include(ExternalProject)

include(ProcessorCount)
ProcessorCount(JOB_COUNT)
if(JOB_COUNT EQUAL 0)
    set(JOB_COUNT 1)
endif()

# This is some world class bullshit right here.
# zlib doesn't autotools for windows (which is even understandable becuase you
# know autotools is sh and sh is not readily available for windows...)
# Wise choice of build tool there.
ExternalProject_Add(zlib
    URL "http://zlib.net/zlib-1.2.11.tar.xz"
    BUILD_IN_SOURCE 1
    CONFIGURE_COMMAND ""
    BUILD_COMMAND make -fwin32/Makefile.gcc SHARED_MODE=1 PREFIX=${TARGET_ARCH}-
    INSTALL_COMMAND make install -fwin32/Makefile.gcc SHARED_MODE=1 DESTDIR=${INSTALL_DIR} INCLUDE_PATH=${INSTALL_PREFIX}/include LIBRARY_PATH=${INSTALL_PREFIX}/lib BINARY_PATH=${INSTALL_PREFIX}/bin
)

# PNG also doesn't autotools properly...
ExternalProject_Add(libpng
    DEPENDS zlib
    URL "https://downloads.sourceforge.net/project/libpng/libpng16/1.6.28/libpng-1.6.28.tar.xz"
    CONFIGURE_COMMAND sh -c "CPPFLAGS=-I${INSTALL_DIR}/include CFLAGS=-I${INSTALL_DIR}/include LDFLAGS=-L${INSTALL_DIR}/lib <SOURCE_DIR>/configure --build=${BUILD_ARCH} --host=${TARGET_ARCH} --prefix=${INSTALL_DIR} --with-sysroot=${CMAKE_SYSROOT}"
    BUILD_COMMAND sh -c "CPPFLAGS=-I${INSTALL_DIR}/include CFLAGS=-I${INSTALL_DIR}/include LDFLAGS=-L${INSTALL_DIR}/lib make -j${JOB_COUNT}"
)

ExternalProject_Add(openssl
    # NB: Qt 5.7 is not compatible with ossl 1.1
    URL "https://www.openssl.org/source/openssl-1.0.2k.tar.gz"
    # This has a custom configure system. Needs crap in ENV.
    BUILD_IN_SOURCE 1 # 1.1 wouldn't need this.
    CONFIGURE_COMMAND sh -c "RC=${CMAKE_WINDRES} CC=${CMAKE_C_COMPILER} CFLAGS=\"--sysroot=${CMAKE_SYSROOT}\" <SOURCE_DIR>/Configure --prefix=${INSTALL_DIR} mingw64"
)

ExternalProject_Add(qtbase
    DEPENDS zlib libpng openssl
    URL https://download.qt.io/official_releases/qt/5.7/5.7.1/submodules/qtbase-opensource-src-5.7.1.tar.xz
    BUILD_IN_SOURCE 1 # FIXME: might not actually be needed if one calls configure from other dir
    # FTR -device-option CROSS_COMPILE is used by the ming32-g++ mkspec to
    # prefix gcc/g++ etc. so it should be a suitable platform prefix for those.
    # This builds with platform zlib and png becuase the qtzlib fails to link
    # in qtsvg for unknown reasons and we need zlib for karchive anyway.
    CONFIGURE_COMMAND <SOURCE_DIR>/configure
        -v
        -sysroot ${CMAKE_SYSROOT}
        -xplatform win32-g++
        -device-option CROSS_COMPILE=${TARGET_ARCH}-
        -extprefix ${INSTALL_DIR}
        -hostprefix ${INSTALL_DIR}/host
        -debug
        -no-accessibility
        -no-qml-debug
        -system-zlib
        -system-libpng
        -nomake examples
        -I ${INSTALL_DIR}/include
        -L ${INSTALL_DIR}/lib
        -L ${INSTALL_DIR}/bin
        -confirm-license -opensource
    BUILD_COMMAND make -j${JOB_COUNT}
)

function(ExternalProject_Add_Qt5 name)
    ExternalProject_Add(${name}
        URL https://download.qt.io/official_releases/qt/5.7/5.7.1/submodules/${name}-opensource-src-5.7.1.tar.xz
        BUILD_IN_SOURCE 1
        CONFIGURE_COMMAND sh -c "${INSTALL_DIR}/host/bin/qmake"
        ${ARGV}
        BUILD_COMMAND make -j${JOB_COUNT}
    )
endfunction()

ExternalProject_Add_Qt5(qtscript DEPENDS qtbase)
ExternalProject_Add_Qt5(qtx11extras DEPENDS qtbase)
ExternalProject_Add_Qt5(qtwinextras DEPENDS qtbase)
ExternalProject_Add_Qt5(qtsvg DEPENDS qtbase)

ExternalProject_Add(libiconv
    URL https://ftp.gnu.org/pub/gnu/libiconv/libiconv-1.15.tar.gz
    CONFIGURE_COMMAND <SOURCE_DIR>/configure
        --host=${TARGET_ARCH}
        --build=${BUILD_ARCH}
        --prefix=${INSTALL_DIR}
        --disable-nls
        --enable-extra-encodings
)

ExternalProject_Add(gettext
    DEPENDS libiconv
    URL http://ftp.gnu.org/pub/gnu/gettext/gettext-0.19.8.tar.xz
    CONFIGURE_COMMAND <SOURCE_DIR>/configure
        --host=${TARGET_ARCH}
        --build=${BUILD_ARCH}
        --prefix=${INSTALL_DIR}
        --enable-threads=win32
        --without-libexpat-prefix
        --without-libxml2-prefix
    BUILD_COMMAND make -C gettext-runtime/intl -j ${JOB_COUNT}
    INSTALL_COMMAND make -C gettext-runtime/intl install
)

# We need a host helper for sonnet
find_program(SONNET_PARSETRIGRAMS parsetrigrams)
# TODO: sonnet needs fixing to support KF5_HOST_TOOLING
# TODO: host_tooling path needs to be determined through find_package or something
function(ExternalProject_Add_KF5)
    ExternalProject_Add(
        ${ARGV}
        CMAKE_ARGS
            -DCMAKE_TOOLCHAIN_FILE=${TOOLCHAIN_FILE}
            -DCMAKE_INSTALL_PREFIX=${INSTALL_DIR}
            -DCMAKE_BUILD_TYPE=Debug
            -DENABLE_TESTING=OFF
            -DBUILD_TESTING=OFF
            -DKDE_SKIP_TEST_SETTINGS=ON
            -DCMAKE_VERBOSE_MAKEFILE=ON
            -DCMAKE_FIND_ROOT_PATH=${CMAKE_FIND_ROOT_PATH}
            -DCMAKE_PREFIX_PATH="/share/ECM/cmake /lib/cmake"
            -DKIO_FORK_SLAVES=ON
            -DPARSETRIGRAMS_EXECUTABLE=${SONNET_PARSETRIGRAMS}
            -DKF5_HOST_TOOLING=/usr/lib/${BUILD_ARCH}/cmake/
        BUILD_COMMAND make -j${JOB_COUNT}
    )
endfunction()

ExternalProject_Add_KF5(ecm
    DEPENDS qtbase
    GIT_REPOSITORY kde:extra-cmake-modules
)

ExternalProject_Add_KF5(ki18n
    DEPENDS ecm gettext qtscript
    GIT_REPOSITORY kde:ki18n
)

ExternalProject_Add_KF5(kconfig
    DEPENDS ecm
    GIT_REPOSITORY /home/me/src/git/kconfig
)

ExternalProject_Add_KF5(karchive
    DEPENDS ecm zlib
    GIT_REPOSITORY kde:karchive
)

add_custom_target(kf5-t1
    DEPENDS
        ecm
        karchive
        kconfig
        kcoreaddons
        kdbusaddons
        kitemviews
        ki18n
        sonnet
        solid
)

ExternalProject_Add_KF5(kcoreaddons
    DEPENDS ecm
    GIT_REPOSITORY kde:kcoreaddons
)
# Note that 'bin/data' is not in the search path
# set by the XDG_DATA_HOME and XDG_DATA_DIRS
# environment variables, so applications may not
# be able to find it until you set them. The
# directories currently searched are:
#
# - /home/me/.local/share
# - /usr/share//usr/share/xsessions/plasma
# - /usr/local/share/
# - /usr/share/
# - /var/lib/snapd/desktop

ExternalProject_Add_KF5(kdbusaddons
    DEPENDS ecm
    GIT_REPOSITORY kde:kdbusaddons
)

ExternalProject_Add_KF5(kwindowsystem
    DEPENDS ecm qtwinextras
    GIT_REPOSITORY kde:kwindowsystem
)

ExternalProject_Add_KF5(kcrash
    DEPENDS ecm kwindowsystem
    GIT_REPOSITORY kde:kcrash
)

ExternalProject_Add_KF5(kservice
    DEPENDS ecm kcrash
    GIT_REPOSITORY kde:kservice
)

ExternalProject_Add_KF5(solid
    DEPENDS ecm
    GIT_REPOSITORY kde:solid
)

ExternalProject_Add_KF5(kguiaddons
    DEPENDS ecm
    GIT_REPOSITORY kde:kguiaddons
)

ExternalProject_Add_KF5(kwidgetsaddons
    DEPENDS ecm
    GIT_REPOSITORY kde:kwidgetsaddons
)

ExternalProject_Add_KF5(kauth
    DEPENDS ecm
    GIT_REPOSITORY kde:kauth
)

# Gather up all t2 so we can conveniently dep on them form higher tiers without
# having to specficy all deps manually.
add_custom_target(kf5-t2
    DEPENDS
        kf5-t1
        kauth
        kcrash
        kcompletion
        kjobwidgets
)

ExternalProject_Add_KF5(kconfigwidgets
    DEPENDS ecm kauth kguiaddons kwidgetsaddons
    GIT_REPOSITORY kde:kconfigwidgets
)

ExternalProject_Add_KF5(kcodecs
    DEPENDS ecm
    GIT_REPOSITORY kde:kcodecs
)

ExternalProject_Add_KF5(kitemviews
    DEPENDS ecm
    GIT_REPOSITORY kde:kitemviews
)

ExternalProject_Add_KF5(kiconthemes
    DEPENDS ecm qtsvg kitemviews kconfigwidgets
    GIT_REPOSITORY kde:kiconthemes
)

ExternalProject_Add_KF5(kcompletion
    DEPENDS ecm
    GIT_REPOSITORY kde:kcompletion
)

ExternalProject_Add_KF5(sonnet
    DEPENDS ecm
    GIT_REPOSITORY kde:sonnet
)

ExternalProject_Add_KF5(ktextwidgets
    DEPENDS ecm kcompletion sonnet kcoreaddons kconfigwidgets kiconthemes kf5-t2
    GIT_REPOSITORY kde:ktextwidgets
)

ExternalProject_Add_KF5(kglobalaccel
    DEPENDS ecm kconfig kcrash kdbusaddons kservice
    GIT_REPOSITORY kde:kglobalaccel
)

ExternalProject_Add_KF5(kxmlgui
    DEPENDS kf5-t2
    GIT_REPOSITORY kde:kxmlgui
)

ExternalProject_Add_KF5(kbookmarks
    DEPENDS ecm kconfigwidgets kxmlgui kf5-t2
    GIT_REPOSITORY kde:kbookmarks
)

ExternalProject_Add_KF5(kjobwidgets
    DEPENDS kf5-t1
    GIT_REPOSITORY kde:kjobwidgets
)

ExternalProject_Add_KF5(kio
    DEPENDS kf5-t2 kbookmarks kcodecs kiconthemes kxmlgui
    GIT_REPOSITORY kde:kio
)

ExternalProject_Add_KF5(kparts
    DEPENDS ecm kio
    GIT_REPOSITORY kde:kparts
)
