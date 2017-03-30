Only tested on KDE neon and probably has some Debianism in the paths as nothing
is resolved properly but mostly hardcoded instead.

To install mingw on neon: `pkcon install mingw-w64`

To cmake run `configure.sh`. This creates a `build/` dir and runs cmake with
the toolchain file defined.

In the `build/` dir `make install` to build and install the build. This uses
cmake's ExternalProject to fetch and build all dependencies needed on top of
mingw64.

NOTE: `make -j` on this project will run the ExternalProject's concurrently
(i.e. if the dep tree permits parallel download and build the deps). The build
of the deps is automatically -j'd to maximize core usage!

Once installed there's a `dist/` dir inside the `build/` dir. This is the
relocatable application dir. It should contain filelight.exe if all went well.

NOTE: the build is running in debug mode and doesn't throw away unused artifacts
so it is a lot fatter than it needs to be in production.
