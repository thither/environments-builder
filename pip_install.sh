#!/usr/bin/env bash


interpreter=$1;
pkgs=${@:2};

export VERBOSE=1;
export LDFLAGS="-DTCMALLOC_MINIMAL -ltcmalloc_minimal -fno-builtin-malloc -fno-builtin-calloc -fno-builtin-realloc -fno-builtin-free"
export CFLAGS="-flto -fuse-linker-plugin -ffat-lto-objects -O3 -DNDEBUG $LDFLAGS"
export CPPFLAGS="$CFLAGS"
export INCLUDEDIRS="-I/usr/local/include"


$interpreter -m pip install --upgrade $pkgs;


export LDFLAGS=""
export CFLAGS=""
export CPPFLAGS=""
export INCLUDEDIRS=""
export VERBOSE="";

