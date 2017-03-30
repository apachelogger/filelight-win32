#!/bin/sh

mkdir build
cd build
cmake .. \
  -DCMAKE_TOOLCHAIN_FILE=../toolchain-win32.cmake -DCMAKE_INSTALL_PREFIX=dist -DCMAKE_VERBOSE_MAKEFILE=ON
