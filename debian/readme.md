# Debian Enviroment Builder

####   A bash based script to Compile and Install debian environment
* Manages the basic compile from source process: folders structure, downloads, out-of-source configure and make (if possible), re-compile follow additional dependencies have been installed.
* Keep all the sources as much version control aware and specific to the build than the pkgs offered with OS-installers.
* Main installation targets of the Build Enviroment are: pypy2 and Hypertable
  * on x86_64 linux

## Usages:
  * bash build-debian-env.sh 
     * --sources source-1 source-2  (builds and installs only the specified sources) or --source all
       * --help 
     * --verbose
     * --stage N
  * recommend, execution cmd: ```nohup bash ~/builder/build-debian-env.sh --no-reuse-make --sources all &> '/root/builder/built.log' &```
  
## Directories Configurations: 
  *  ```CUST_INST_PREFIX=/usr/local ``` (equal to the configure --prefix)
 
  *  ```BUILDS_ROOT=~/builds ```
  *  ```SCRIPTS_PATH=$BUILDS_ROOT/scripts ```
  *  ```DOWNLOAD_PATH=$BUILDS_ROOT/downloads ```
  *  ```BUILDS_PATH=$BUILDS_ROOT/sources ```
  *  ```BUILDS_LOG_PATH=$BUILDS_ROOT/logs/$( date  +"%Y-%m-%d_%H-%M-%S") ```
  *  ```BUILTS_PATH=$BUILDS_ROOT/builts ```

## Source Configuration:
 * Edit the function _do_build() and add a named-source case in follow structure:
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
 * or the same format os the _do_build function's case, add a bash file in SCRIPTS_PATH directory with the filename named-source.sh (The source filenam applies first , if exists,e)

## Logging:
Logs are created in the BUILDS_LOG_PATH in a folder of date-time under filename stage number and source-name 

## Sources
  * Current Sources consist the follow latest realeses as to  May 2017, with some exceptions.
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
        * gawk
        * zlib
        * bzip2
        * unrar
        * gzip
        * snappy
        * lzma
        * libzip
        * unzip
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
        * p11-kit
        * gnutls
        * tcltk
        * tk
        * pcre
        * pcre2
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
        * llvm
        * libconfuse
        * apr
        * apr-util
        * libsigcplusplus
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
        * apache-hadoop
        * freetype
        * harfbuzz
        * fontconfig
        * sqlite
        * imagemagick
        * pixman
        * cairo
        * cairomm
        * gobject-ispec
        * pango
        * rrdtool
        * ganglia
        * pypy2
        * nodejs
        * thrift
        * pybind11
        * hypertable

## Liscense:
Please, consult with the liscenses of the sources
