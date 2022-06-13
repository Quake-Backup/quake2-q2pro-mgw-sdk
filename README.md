# Q2PRO SDK for MinGW-w64

Collection of headers and precompiled libraries for building Windows port of
Q2PRO with MinGW-w64.

## Building

List of dependencies: wget, tar, xz-utils, bzip2, mingw-w64, make, cmake, nasm.

POSIX system required. Building this SDK on Windows is not supported.

Type `make` to build, `make install DESTDIR=/path/to/install` to install, `make
clean` to remove temporary files, `make distclean` to also remove download
cache.
