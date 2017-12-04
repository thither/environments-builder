# Enviroment Builder

####   A bash based script to Compile and Make an environment
* Manages the basic compile from source process: folders structure, downloads, out-of-source configure and make (if possible),
 re-compile follow additional dependencies have been installed.
* Keep all the sources as much under version control aware and specific to the build than the pkgs offered with OS-installers.
* Main installation targets of the Build Enviroment are: nftables, PyPy2, Apache-Hadoop and Hypertable and next to be Ceph
  * Ubunutu or openSUSE on x86_64 linux
  
## Usages:
  * bash build-env.sh
     * --target node/monitoring/all  
     * --sources source-1 source-2  (builds and installs only the specified sources) or --source all
       * --help 
     * --verbose
     * --stage N
  * recommend, execution cmd: ```nohup bash ~/builder/build-env.sh --no-reuse-make --sources all &> '/root/builder/built.log' &```
  
## Directories Configurations: 
  *  ```CUST_INST_PREFIX=/usr/local ``` (equal to the configure --prefix with most of the sources)
  *  ```CUST_JAVA_INST_PREFIX=/usr/java ``` 
 
  *  ```BUILDS_ROOT=~/builds ```
  *  ```SCRIPTS_PATH=~/builder/scripts ```
  *  ```DOWNLOAD_PATH=$BUILDS_ROOT/downloads ```
  *  ```BUILDS_PATH=$BUILDS_ROOT/sources ```
  *  ```BUILDS_LOG_PATH=$BUILDS_ROOT/logs/$( date  +"%Y-%m-%d_%H-%M-%S") ```
  *  ```BUILTS_PATH=$BUILDS_ROOT/builts ```

  *  ```ENV_SETTINGS_PATH=$CUST_INST_PREFIX/etc/profile.d/ ```
  *  ```LD_CONF_PATH=$CUST_INST_PREFIX/etc/ld.so.conf.d ```
  
## Source Configuration:
 * Edit the function _do_build() and add a named-source case in follow structure:
  ```
    'named-source')
  ```
  ```
      tn='archive-folder-name'; url='URI.tar*';
      set_source 'tar' or 'zip'
      configure_build ARGUMENTS to PASSS to configure, configure_build is creating the instructions out of source and adds build=x86_64-OS-gnu (it can be without build by passing as first arg --no-build) 
      make - as usual or do_make which adds parallel and verbose additionally to passed arguments
  ```
  ```
      shift;;
  ```
 * or the same format as the _do_build function's case, add a bash file in SCRIPTS_PATH directory with the filename named-source.sh (The source filename applies first, if exists)

## Logging:
Logs are created in the BUILDS_LOG_PATH in a folder of date-time under filename stage number and source-name 

## Sources
  * Current Sources consist the follow latest realeses as to  Nov 2017, with some exceptions.
     *  Compilation Build and Install is in the same order, while stages have it's grouping
     *  Sources commented are kept out
     
        * make
        * cmake
        * byacc
        * ncursesw
        * libreadline
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
        * lzo
        * snappy
        * libzip
        * unzip
        * xz
        * p7zip
        * tar
        * libatomic_ops
        * libeditline
        * libevent
        * libunwind
        * fuse
        * pth
        * openssl
        * libgpg-error
        * libgcrypt
        * kerberos
        * libssh
        * icu4c
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
        * pcre
        * pcre2
        * #tk
        * #openmpi
        * gdbm
        * expect
        * attr
        * patch
        * jemalloc
        * gc
        * gperf
        * gperftools
        * #libhoard
        * glib
        * pkg-config
        * gcc
        * #glibc
        * coreutils
        * gdb
        * bash
        * curl
        * sqlite
        * berkeley-db
        * python
        * boost
        * libmnl
        * libnftnl
        * nftables
        * llvm
        * clang
        * libconfuse
        * apr
        * apr-util
        * libsigcplusplus
        * log4cpp
        * cronolog
        * re2
        * sparsehash
        * libpng
        * libjpeg
        * libjansson
        * libxml2
        * libxslt
        * libuv
        * libcares
        * openjdk
        * apache-ant
        * apache-maven
        * sigar
        * gmock
        * protobuf
        * apache-hadoop
        * libgsasl
        * libhdfs3
        * freetype
        * harfbuzz
        * fontconfig
        * pixman
        * cairo
        * cairomm
        * gobject-ispec
        * pango
        * imagemagick
        * php
        * ganglia-web
        * pypy2
        * nodejs
        * thrift
        * pybind11
        * rrdtool
        * hypertable
        * python3
        * pypy2stm

		
## Liscense:
Please, consult with the liscenses from the providers of the sources.
