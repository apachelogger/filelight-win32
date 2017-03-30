cmake_minimum_required(VERSION 3.0)
project(filelight-win32)

set(CMAKE_TOOLCHAIN_FILE ${CMAKE_CURRENT_SOURCE_DIR}/toolchain-win32.cmake)
set(CMAKE_INSTALL_PREFIX dist)
set(DCMAKE_VERBOSE_MAKEFILE ON)

# This sets the bin dir as base dir for ExternalProject which will create a
# bunch of dirs to manage the projects in there /Install, /Source etc.
set_property(DIRECTORY PROPERTY "EP_BASE" ${CMAKE_BINARY_DIR})

# Fully expand our toolchain.
get_filename_component(TOOLCHAIN_FILE "${CMAKE_TOOLCHAIN_FILE}"
                       REALPATH BASE_DIR "${CMAKE_BINARY_DIR}")
set(CMAKE_FIND_ROOT_PATH ${CMAKE_BINARY_DIR}/Install) # EP_BASE derived
set(INSTALL_DIR ${CMAKE_FIND_ROOT_PATH})

include(deps.cmake)

ExternalProject_Add_KF5(filelight
    DEPENDS kparts
    GIT_REPOSITORY /home/me/src/git/filelight # special patches
    GIT_TAG win32
)

install(DIRECTORY ${CMAKE_FIND_ROOT_PATH}/bin/ DESTINATION .)
# Trailing slash on plugins is to flatten out the dir.
install(DIRECTORY ${CMAKE_FIND_ROOT_PATH}/plugins/ DESTINATION .)
# FIXME: this installs also dirs, albeit empty, kinda silly.
# FIXME: not sure how to properly resolve the path of the core libs
install(DIRECTORY /usr/lib/gcc/x86_64-w64-mingw32/5.3-win32/ DESTINATION .
    FILES_MATCHING PATTERN "*.dll")
