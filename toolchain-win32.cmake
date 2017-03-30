set(CMAKE_SYSTEM_NAME Windows)
# TODO: surely there must be a better way to get the native arch?
set(BUILD_ARCH x86_64-linux-gnu)
set(TARGET_ARCH x86_64-w64-mingw32)

set(CMAKE_SYSROOT /usr/${TARGET_ARCH})

SET(CMAKE_C_COMPILER ${TARGET_ARCH}-gcc)
SET(CMAKE_CXX_COMPILER ${TARGET_ARCH}-g++)
SET(CMAKE_WINDRES ${TARGET_ARCH}-windres)
SET(CMAKE_RC_COMPILER ${TARGET_ARCH}-windres)

# Make sure that contained builds pick programs from the host but otherwise stay
# within their containment.
set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_PACKAGE ONLY)
