# Debian Enviroment Builder

####   A bash based script to Compile and Install debian environment
* Manages the basic compile from source process: forlders structure, downloads, out-of-source configure and make (if possible), re-compile follow additional dependecies have been installed.

* Main installation targets of the Build Enviroment are: pypy2 and Hypertable
  * on x86_64 linux

## Usages:
  * bash build-debian-env.sh 
     * --sources source-1 source-2  (builds and installs only the specified sources)
       * --help 
     * --verbose
     * --stage N
     
## Directories Configurations: 
  *  ```CUST_INST_PREFIX=/usr/local ``` (equal to the configure --prefix)
 
  *  ```BUILDS_ROOT=~/builds ```
  *  ```SCRIPTS_PATH=$BUILDS_ROOT/scripts ```
  *  ```DOWNLOAD_PATH=$BUILDS_ROOT/downloads ```
  *  ```BUILDS_PATH=$BUILDS_ROOT/sources ```
  *  ```BUILDS_LOG_PATH=$BUILDS_ROOT/logs/$( date  +"%Y-%m-%d_%H-%M-%S") ```
  *  ```BUILTS_PATH=$BUILDS_ROOT/builts ```

## Source Configuration:
 * Add in the function _do_build() to add a named-source case in follow structure:
  ```
    'named-source')
  ```
  ```
      fn='downloaded.archive.name'; tn='archive-folder-name'; url='URI.tar*';
      set_source 'tar' 
      configure_build ARGUMENTS PASSSED TO configure --prefix=$CUST_INST_PREFIX;
      make;make desired commands
  ```
  ```
      shift;;
  ```
 * or the same format os the _do_build function's case, add a bash file in SCRIPTS_PATH directory with the filename named-source.sh (First applies, if exists, the source filename)

## Logging:
Logs are created in the BUILDS_LOG_PATH in a folder of date-time under filename stage number and source-name 

## Sources
  * Current Sources consist the follow latest realeses as to 20th of May 2017, exceptions to imagemagick.
     *  Compilation Build and Install is in the same order, while stages have it's grouping
     *  Sources commented are kept out
     
        * make
        * cmake
        * byacc
        * m4
        * gmp
        * mpfr
        * mpc
        * isl
        * autoconf
        * automake
        * libtool
        * zlib
        * bzip2
        * unrar
        * gzip
        * snappy
        * lzma
        * libzip
        * libatomic_ops
        * libedit
        * libevent
        * libunwind
        * #readline
        * openssl
        * libgpg-error
        * libgcrypt
        * libssh
        * icu4c
        * log4cpp
        * cronolog
        * fuse
        * sparsehash
        * bison
        * texinfo
        * flex
        * binutils
        * gettext
        * nettle
        * libtasn1
        * libiconv
        * libexpat
        * libunistring
        * libidn2
        * libsodium
        * unbound
        * libffi
        * gnutls
        * p11-kit
        * tcltk
        * tk
        * pcre
        * glib
        * openmpi
        * gdbm
        * re2
        * expect
        * attr
        * #musl
        * libhoard
        * jemalloc
        * gc
        * gperf
        * gperftools
        * patch
        * gcc
        * boost
        * libpng
        * libjpeg
        * libjansson
        * libxml2
        * libxslt
        * libuv
        * libcares
        * python
        * openjdk
        * apache-ant
        * apache-maven
        * sigar
        * berkeley-db
        * protobuf
        * harfbuzz
        * freetype
        * fontconfig
        * sqlite
        * imagemagick
        * pypy2
        * nodejs
        * thrift

## Liscense:
Please, consult with the liscenses of the sources
