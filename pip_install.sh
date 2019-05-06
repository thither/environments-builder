#!/usr/bin/env bash

# USING:
# ./pip_install.sh py_exec list of packages 

interpreter=$1;
pkgs=${@:2};


if [[ ! " ${pkgs[@]} " =~ "pip" ]]; then
	$interpreter -m pip uninstall -y $pkgs;
fi;

export VERBOSE=1;
export LDFLAGS="-DTCMALLOC_MINIMAL -ltcmalloc_minimal -fno-builtin-malloc -fno-builtin-calloc -fno-builtin-realloc -fno-builtin-free"
export CFLAGS="-flto -fuse-linker-plugin -ffat-lto-objects -O3 -DNDEBUG $LDFLAGS"
export CPPFLAGS="$CFLAGS"
export INCLUDEDIRS="-I/usr/local/include"


$interpreter -m pip install --upgrade --verbose $pkgs;


export LDFLAGS=""
export CFLAGS=""
export CPPFLAGS=""
export INCLUDEDIRS=""
export VERBOSE="";

