#!/usr/bin/env bash
## Author Kashirin Alex (kashirin.alex@gmail.com)

# nohup bash ~/builder/build-debian-env.sh --no-reuse-make --sources all &> '/root/builder/built.log' &

################## DIRCETOTRIES CONFIGURATIONS ##################
CUST_INST_PREFIX=/usr/local
CUST_JAVA_INST_PREFIX=/usr/java

SCRIPTS_PATH=~/builder/scripts
BUILDS_ROOT=~/builds
DOWNLOAD_PATH=$BUILDS_ROOT/downloads
BUILDS_PATH=$BUILDS_ROOT/sources
BUILDS_LOG_PATH=$BUILDS_ROOT/logs/$( date  +"%Y-%m-%d_%H-%M-%S")
BUILTS_PATH=$BUILDS_ROOT/builts

ENV_SETTINGS_PATH=/usr/local/etc/profile.d/
LD_CONF_PATH=/usr/local/etc/ld.so.conf.d
##################################################################


reuse_make=0
test_make=0
verbose=0
help=''
stage=0
c=1
only_sources=()
while [ $# -gt 0 ]; do	

  case $1 in
    --no-reuse-make) 	
		reuse_make=0
	;;
    --test-make)  		
		test_make=1
	;;
    --verbose)  		
		verbose=1;
	;;
    --stage)  		
		stage=$2;
		let c=c-1;
	;;
	--sources) 
		only_sources=(${@:$c})
	;;
    --help)  			
		help='--help'
	;;
    *)  			
		let c=c-1
	;;
  esac
  shift
  let c=c+1;
done

if [ ${#only_sources[@]} -eq 0 ]; then 
	echo '	--sources must be set with "all" or sources names'
	exit 1
fi
build_all=0
if [ ${#only_sources[@]} -eq 1 ] && [ ${only_sources[0]} == 'all' ]; then 
	only_sources=()
	build_all=1
	verbose=0;  
else
	stage=-1;
fi

if [ ${#only_sources[@]} -gt 0 ]; then 
	echo 'number of sources: '${#only_sources[@]}
fi
 
if [ -z $help ] && [ ${#only_sources[@]} -eq 0 ] && [ $build_all == 0 ]; then 
	verbose=1;    
	stage=0
fi

echo '--verbose:' $verbose
echo '--sources:' ${only_sources[@]}
echo '--help:' $help
echo '--stage:' $stage
echo '--test_make:' $test_make
echo '--no-reuse-makee:' $reuse_make
#trap 'echo "trying to EXIT"' EXIT
#trap 'echo "trying to SIGINT"' SIGINT
#trap 'echo "trying to SIGTERM"' SIGTERM
#trap 'echo "trying to INT"' INT
#

mkdir -p $LD_CONF_PATH
mkdir -p $ENV_SETTINGS_PATH
mkdir -p $CUST_INST_PREFIX
mkdir -p $CUST_JAVA_INST_PREFIX
mkdir -p $BUILDS_ROOT
mkdir -p $DOWNLOAD_PATH
mkdir -p $BUILDS_PATH
mkdir -p $BUILDS_LOG_PATH
mkdir -p $BUILTS_PATH
cust_conf_path=''
	
NUM_PROCS=`grep -c processor < /proc/cpuinfo || echo 1`


#########
download() {
	if [ ! -f $DOWNLOAD_PATH/$sn/$fn ]; then
		echo 'downloading:' $fn: $url;
		if [ ! -d $DOWNLOAD_PATH/$sn ]; then
			mkdir $DOWNLOAD_PATH/$sn;
		fi	
		cd $DOWNLOAD_PATH/$sn;
		wget -O $fn -nv --tries=3 $url;
	fi
}
extract() {
	echo 'extracting:' $fn to $sn;
	if [ -d $BUILDS_PATH/$sn ]; then
		echo 'removing old:' $BUILDS_PATH/$sn;
		rm -r $BUILDS_PATH/$sn;
	fi
	cd $BUILDS_PATH; 
	
	if [ $archive_type == 'tar' ]; then
		tar xf $DOWNLOAD_PATH/$sn/$fn;
	elif [ $archive_type == 'zip' ]; then
		unzip $DOWNLOAD_PATH/$sn/$fn;
	fi
	if [ $tn != $sn ]; then
		mv $tn $sn;
	fi
}
set_source() {
	echo -e '\n\n\n'
	echo 'setting-source:' $sn
	if [ $reuse_make == 1 ] && [ -d $BUILDS_PATH/$sn ]; then
		echo 'reusing previus make:' $BUILDS_PATH/$sn
		cd $BUILDS_PATH/$sn;
		return 1
	fi

	download $url 
	archive_type=$1;
	extract;
	#if [ $1=='tar' ]; then
	#	extract
	#fi
	cd $BUILDS_PATH/$sn;
}
mv_child_as_parent() {
	rm ../${sn}_tmp; mv $1 ../${sn}_tmp; rm -r ../${sn}; mv ../${sn}_tmp ../${sn};cd ..;cd ${sn};
}
#########
configure_build() {
	echo 'config args:' ${@:1} $help;
	if [ $reuse_make == 0 ] && [ -d $BUILTS_PATH/$sn ]; then
		rm -r  $BUILTS_PATH/$sn;
	fi
	mkdir -p $BUILTS_PATH/$sn;
	cd $BUILTS_PATH/$sn;
	$BUILDS_PATH/$sn/${cust_conf_path}configure ${@:1} $help;
	cust_conf_path=''
	
	if [ ! -z $help ]; then 
		exit 1
	fi
}
cmake_build() {
	echo 'config args:' ${@:1} $help;
	if [ $reuse_make == 0 ] && [ -d $BUILTS_PATH/$sn ]; then
		rm -r  $BUILTS_PATH/$sn;
	fi
	mkdir -p $BUILTS_PATH/$sn;
	cd $BUILTS_PATH/$sn;
	cmake $BUILDS_PATH/$sn ${@:1};
	
	if [ ! -z $help ]; then 
		exit 1
	fi
}
autogen_build() {
	echo 'config args:' ${@:1} $help;
	./autogen.sh; ${@:1} $help;
	if [ ! -z $help ]; then 
		exit 1
	fi
}
bootstrap_build() {
	echo 'config args:' ${@:1};
	./bootstrap ${@:1};
	if [ ! -z $help ]; then 
		exit 1
	fi
}
#########
make_test_build() {
	if [ $test_make == 1 ]; then
		if [ $1 == 'make' ]; then
			make  check;
		fi
	fi
}
finalize_build() {
	source /etc/profile
	source ~/.bashrc
	cd $BUILDS_ROOT; /sbin/ldconfig
	echo 'finished:' $sn;
	echo -e '\n\n\n'
}
#########

#########
do_build() {
	echo '-------------------------------'
	echo 'doing_build:' $sn 'stage:' $stage
	sleep 1
	if [ -f $SCRIPTS_PATH/$sn.sh ]; then
		source $SCRIPTS_PATH/$sn.sh
	else
		_do_build ${@:1}
	fi
	finalize_build
  
	sleep 1
	echo 'done_build:' $sn 'stage:' $stage
	echo '-------------------------------'
}
_do_build() {
  
  case $sn in
		
'make')
fn='make-4.2.tar.gz'; tn='make-4.2'; url='http://ftp.gnu.org/gnu/make/make-4.2.tar.gz';
set_source 'tar' 
configure_build --with-guile --prefix=$CUST_INST_PREFIX;
make;make install-strip;make install;make all;
		shift;;

'libtool')
fn='libtool-2.4.6.tar.gz'; tn='libtool-2.4.6'; url='http://ftpmirror.gnu.org/libtool/libtool-2.4.6.tar.gz';
set_source 'tar' 
configure_build --enable-ltdl-install  --prefix=$CUST_INST_PREFIX;
make;make install-strip;make install;make all; 
		shift;;
		
'autoconf')
fn='autoconf-2.69.tar.xz'; tn='autoconf-2.69'; url='http://ftp.gnu.org/gnu/autoconf/autoconf-2.69.tar.xz';
set_source 'tar'
configure_build --prefix=$CUST_INST_PREFIX;
make;make lib;make install-strip;make install;make all;
		shift;;
		
'automake')
fn='automake-1.15.tar.xz'; tn='automake-1.15'; url='http://ftp.gnu.org/gnu/automake/automake-1.15.tar.xz';
set_source 'tar'
configure_build --prefix=$CUST_INST_PREFIX;
make;make lib; make install-strip;make install;make all; 
		shift;;
		
'cmake')
fn='cmake-3.8.1.tar.gz'; tn='cmake-3.8.1'; url='http://cmake.org/files/v3.8/cmake-3.8.1.tar.gz';
set_source 'tar' 
bootstrap_build --prefix=$CUST_INST_PREFIX;
make;make install;make all;
		shift;;

'zlib')
fn='zlib-1.2.11.tar.gz'; tn='zlib-1.2.11'; url='http://zlib.net/zlib-1.2.11.tar.gz';
set_source 'tar'
configure_build --prefix=$CUST_INST_PREFIX; 
make;make shared;make install;make all; 
		shift;;
		
'bzip2')
fn='bzip2-1.0.6.tar.gz'; tn='bzip2-1.0.6'; url='http://www.bzip.org/1.0.6/bzip2-1.0.6.tar.gz';
set_source 'tar' 
make -f Makefile-libbz2_so;make install PREFIX=$CUST_INST_PREFIX;
cp -av libbz2.so* $CUST_INST_PREFIX/lib/; ln -sv $CUST_INST_PREFIX/lib/libbz2.so.1.0.6 $CUST_INST_PREFIX/lib/libbz2.so
		shift;;

'unrar')
fn='unrar.tar.gz'; tn='unrar'; url='http://www.rarlab.com/rar/unrarsrc-5.5.3.tar.gz';
set_source 'tar' 
make;make lib;make install-lib PREFIX=$CUST_INST_PREFIX;make install PREFIX=$CUST_INST_PREFIX;make all PREFIX=$CUST_INST_PREFIX;
		shift;;
		
'gzip')
fn='gzip-1.8.tar.xz'; tn='gzip-1.8'; url='http://ftp.gnu.org/gnu/gzip/gzip-1.8.tar.xz';
set_source 'tar' 
configure_build --enable-threads=posix --prefix=$CUST_INST_PREFIX; 
make;make lib;make install-strip;make install;make all;
		shift;;
		
'snappy')
fn='snappy-1.1.4.tar.gz'; tn='snappy-1.1.4'; url='http://github.com/google/snappy/releases/download/1.1.4/snappy-1.1.4.tar.gz';
set_source 'tar' 
configure_build --prefix=$CUST_INST_PREFIX; 
make;make install-strip;make install;make all; 	
		shift;;

'lzma')
fn='xz-5.2.3.tar.gz'; tn='xz-5.2.3'; url='https://tukaani.org/xz/xz-5.2.3.tar.gz';
set_source 'tar' 
configure_build --prefix=$CUST_INST_PREFIX; 
make;make lib;make install-strip;make install;make all; 
		shift;;
		
'libpng')
fn='libpng-1.6.29.tar.gz'; tn='libpng-1.6.29'; url='ftp://ftp.simplesystems.org/pub/libpng/png/src/libpng16/libpng-1.6.29.tar.gz';
set_source 'tar' 
configure_build --prefix=$CUST_INST_PREFIX; 
make;make install-strip;make install;make all; 
		shift;;
		
'm4')
fn='m4-1.4.18.tar.xz'; tn='m4-1.4.18'; url='http://ftp.gnu.org/gnu/m4/m4-1.4.18.tar.xz';
set_source 'tar' 
configure_build --enable-c++ --enable-threads=posix --prefix=$CUST_INST_PREFIX;
make;make lib;make install-strip;make install;make all;
		shift;;
	
'byacc')
fn='byacc-20170430.tgz'; tn='byacc-20170430'; url='ftp://invisible-island.net/byacc/byacc-20170430.tgz';
set_source 'tar' 
configure_build --prefix=$CUST_INST_PREFIX;
make;make install;make all;
		shift;;	

'gmp')
fn='gmp-6.1.2.tar.xz'; tn='gmp-6.1.2'; url='http://ftp.gnu.org/gnu/gmp/gmp-6.1.2.tar.xz';
set_source 'tar' 
configure_build --enable-cxx --enable-fat --enable-assert --prefix=$CUST_INST_PREFIX;
make;make install;make all;
		shift;;
		
'mpfr')
fn='mpfr-3.1.5.tar.gz'; tn='mpfr-3.1.5'; url='http://www.mpfr.org/mpfr-current/mpfr-3.1.5.tar.gz';
set_source 'tar' 
configure_build --enable-decimal-float --enable-thread-safe --with-gmp-build=$BUILTS_PATH/gmp/ --prefix=$CUST_INST_PREFIX;
make;make install-strip;make install;make all; 
		shift;;
		
'mpc')
fn='mpc-1.0.3.tar.gz'; tn='mpc-1.0.3'; url='http://ftp.gnu.org/gnu/mpc/mpc-1.0.3.tar.gz';
set_source 'tar' 
configure_build --prefix=$CUST_INST_PREFIX;
make;make install-strip;make install;make all;
		shift;;
		
'isl')
fn='isl-0.16.1.tar.bz2'; tn='isl-0.16.1'; url='ftp://gcc.gnu.org/pub/gcc/infrastructure/isl-0.16.1.tar.bz2';
set_source 'tar' 
configure_build --with-gmp=build --with-gmp-builddir=$BUILTS_PATH/gmp/ --prefix=$CUST_INST_PREFIX;
make;make install-strip;make install;make all;
		shift;;
		
'bison')
fn='bison-3.0.4.tar.gz'; tn='bison-3.0.4'; url='http://ftp.gnu.org/gnu/bison/bison-3.0.4.tar.gz';
set_source 'tar' 
configure_build --enable-threads=posix --prefix=$CUST_INST_PREFIX;
make; make lib;make install-strip;make install;make all;
		shift;;
		
'texinfo')
fn='texinfo-6.3.tar.gz'; tn='texinfo-6.3'; url='http://ftp.gnu.org/gnu/texinfo/texinfo-6.3.tar.gz';
set_source 'tar' 
configure_build --enable-threads=posix --prefix=$CUST_INST_PREFIX;
make;make install-strip;make install;make all; 
		shift;;
		
'flex')
fn='flex-2.6.4.tar.gz'; tn='flex-2.6.4'; url='http://github.com/westes/flex/files/981163/flex-2.6.4.tar.gz';
set_source 'tar' 
configure_build --prefix=$CUST_INST_PREFIX;
make;make lib;make install-strip;make install;make all;
		shift;;
		
'binutils')
fn='binutils-2.28.tar.gz'; tn='binutils-2.28'; url='http://ftp.ntua.gr/mirror/gnu/binutils/binutils-2.28.tar.gz';
set_source 'tar' 
configure_build --enable-plugins --enable-gold=yes --enable-ld=yes --enable-libada --enable-libssp --enable-lto --enable-objc-gc --enable-vtable-verify  --with-system-zlib --with-mpfr=$CUST_INST_PREFIX --with-mpc=$CUST_INST_PREFIX --with-isl=$CUST_INST_PREFIX --with-gmp=$CUST_INST_PREFIX --prefix=$CUST_INST_PREFIX; 
make tooldir=$CUST_INST_PREFIX; make tooldir=$CUST_INST_PREFIX install-strip;make tooldir=$CUST_INST_PREFIX install;make tooldir=$CUST_INST_PREFIX all; # libiberty> --enable-shared=opcodes --enable-shared=bfd --enable-host-shared --enable-stage1-checking=all --enable-stage1-languages=all 
		shift;;
		
'gettext')
fn='gettext-0.19.8.1.tar.gz'; tn='gettext-0.19.8.1'; url='http://ftp.ntua.gr/mirror/gnu/gettext/gettext-0.19.8.1.tar.gz';
set_source 'tar' 
configure_build --enable-threads=posix --prefix=$CUST_INST_PREFIX; 
make; make install-strip;make install;make all;
		shift;;
		
'nettle')
fn='nettle-3.3.tar.gz'; tn='nettle-3.3'; url='http://ftp.gnu.org/gnu/nettle/nettle-3.3.tar.gz';
set_source 'tar' 
configure_build --enable-gcov --enable-x86-aesni --enable-mini-gmp --enable-fat --prefix=$CUST_INST_PREFIX; 
make;make install;make all;
		shift;;
		
'libtasn1')
fn='libtasn1-4.10.tar.gz'; tn='libtasn1-4.10'; url='http://ftp.gnu.org/gnu/libtasn1/libtasn1-4.10.tar.gz';
set_source 'tar' 
configure_build --prefix=$CUST_INST_PREFIX; 
make;make lib;make install-strip;make install;make all;  	
		shift;;
		
'libiconv')
fn='libiconv-1.15.tar.gz'; tn='libiconv-1.15'; url='http://ftp.gnu.org/pub/gnu/libiconv/libiconv-1.15.tar.gz';
set_source 'tar' 
configure_build --enable-extra-encodings --prefix=$CUST_INST_PREFIX; 
make;make lib;make install-lib;make install-strip;make install;make all; 
		shift;;
		
'libunistring')
fn='libunistring-0.9.7.tar.xz'; tn='libunistring-0.9.7'; url='http://ftp.gnu.org/gnu/libunistring/libunistring-0.9.7.tar.xz';
set_source 'tar' 
configure_build --enable-threads=posix --prefix=$CUST_INST_PREFIX; 
make;make lib;make install-strip;make install;make all;
		shift;;
		
'libidn2')
fn='libidn2-2.0.2.tar.gz'; tn='libidn2-2.0.2'; url='http://ftp.gnu.org/pub/gnu/libidn/libidn2-2.0.2.tar.gz';
set_source 'tar' 
configure_build --prefix=$CUST_INST_PREFIX; 
make;make lib;make install-strip;make install;make all;
		shift;;
		
'libsodium')
fn='libsodium-1.0.12.tar.gz'; tn='libsodium-1.0.12'; url='http://download.libsodium.org/libsodium/releases/libsodium-1.0.12.tar.gz';
set_source 'tar' 
configure_build --enable-minimal --prefix=$CUST_INST_PREFIX; 
make;make install-strip;make install;make all; 
		shift;;
		
'unbound')
fn='unbound-1.6.2.tar.gz'; tn='unbound-1.6.2'; url='http://www.unbound.net/downloads/unbound-1.6.2.tar.gz';
set_source 'tar' 
configure_build --enable-tfo-client --enable-tfo-server --enable-dnscrypt --prefix=$CUST_INST_PREFIX; 
make;make lib;make install-lib;make install;make all; 
		shift;;
		
'libffi')
fn='v3.2.1.tar.gz'; tn='libffi-3.2.1'; url='http://github.com/libffi/libffi/archive/v3.2.1.tar.gz';
set_source 'tar' 
autogen_build;
configure_build --prefix=$CUST_INST_PREFIX; 
make;make install-strip;make install;make all; 
		shift;;
		
'p11-kit')
fn='p11-kit-0.23.2.tar.gz'; tn='p11-kit-0.23.2'; url='http://p11-glue.freedesktop.org/releases/p11-kit-0.23.2.tar.gz';
set_source 'tar' 
configure_build --prefix=$CUST_INST_PREFIX; 
make;make install-strip;make install;make all; 
		shift;;
		
'gnutls')
fn='gnutls-3.5.9.tar.xz'; tn='gnutls-3.5.9'; url='ftp://ftp.gnutls.org/gcrypt/gnutls/v3.5/gnutls-3.5.9.tar.xz';
set_source 'tar' 
configure_build --prefix=$CUST_INST_PREFIX; 
make;make lib;make install-strip;make install;make all;
		shift;;
		
'openmpi')
fn='openmpi-2.1.1.tar.gz'; tn='openmpi-2.1.1'; url='http://www.open-mpi.org/software/ompi/v2.1/downloads/openmpi-2.1.1.tar.gz';
set_source 'tar' 
configure_build --prefix=$CUST_INST_PREFIX; #--enable-mpi-fortran
make;make install-strip;make install;make all; 
		shift;;
		
'pcre')
fn='pcre-8.36.tar.gz'; tn='libpcre-pcre-8.36'; url='http://github.com/vmg/libpcre/archive/pcre-8.36.tar.gz';
set_source 'tar' 
autogen_build;
configure_build --enable-pcre16 --enable-pcre32 --enable-jit --enable-pcregrep-libz --enable-pcregrep-libbz2 --enable-unicode-properties --enable-utf  --prefix=$CUST_INST_PREFIX; #  --enable-utf8
make;make install-strip;make install;make all; 
		shift;;
		
'glib')
fn='glib-2.53.1.tar.xz'; tn='glib-2.53.1'; url='http://ftp.acc.umu.se/pub/gnome/sources/glib/2.53/glib-2.53.1.tar.xz';
set_source 'tar' 
configure_build --with-libiconv=gnu --with-threads=posix --prefix=$CUST_INST_PREFIX; 
make; make install-strip;make install;make all;
		shift;;

'jemalloc')
fn='jemalloc-4.2.1.tar.bz2'; tn='jemalloc-4.2.1'; url='http://www.canonware.com/download/jemalloc/jemalloc-4.2.1.tar.bz2';
set_source 'tar' 
configure_build --enable-lazy-lock --enable-xmalloc --prefix=$CUST_INST_PREFIX; 
make;make lib;make install;make all;
		shift;;
		
'libevent')
fn='libevent-2.1.8-stable.tar.gz'; tn='libevent-2.1.8-stable'; url='http://github.com/libevent/libevent/releases/download/release-2.1.8-stable/libevent-2.1.8-stable.tar.gz';
set_source 'tar' 
configure_build --prefix=$CUST_INST_PREFIX; 
make;make install-strip;make install;make all;  
		shift;;
	
'libatomic_ops')
fn='libatomic_ops-7.4.4.tar.gz'; tn='libatomic_ops-7.4.4'; url='http://www.hboehm.info/gc/gc_source/libatomic_ops-7.4.4.tar.gz';
set_source 'tar' 
configure_build --enable-shared --prefix=$CUST_INST_PREFIX; 
make;make install-strip;make install;make all;
		shift;;
		
'gc')
fn='gc-7.6.0.tar.gz'; tn='gc-7.6.0'; url='http://www.hboehm.info/gc/gc_source/gc-7.6.0.tar.gz';
set_source 'tar' 
configure_build --enable-single-obj-compilation  --enable-large-config  --enable-redirect-malloc --enable-sigrt-signals --enable-parallel-mark   --enable-handle-fork  --enable-cplusplus  --with-libatomic-ops=yes --prefix=$CUST_INST_PREFIX;  # --enable-threads=posix  // GC Warning: USE_PROC_FOR_LIBRARIES + GC_LINUX_THREADS performs poorly
make;make install-strip;make install;make all;
		shift;;
	
'gperf')
fn='gperf-3.1.tar.gz'; tn='gperf-3.1'; url='http://ftp.gnu.org/gnu/gperf/gperf-3.1.tar.gz';
set_source 'tar' 
configure_build --prefix=$CUST_INST_PREFIX; 
make;make lib; make install;make all; 
		shift;;
	
'patch')
fn='patch-2.7.5.tar.xz'; tn='patch-2.7.5'; url='http://ftp.gnu.org/gnu/patch/patch-2.7.5.tar.xz';
set_source 'tar' 
configure_build --prefix=$CUST_INST_PREFIX; 
make;make lib;make install-strip;make install;make all;
		shift;;
		
'tcltk')
fn='tcl8.6.6-src.tar.gz'; tn='tcl8.6.6'; url='ftp://sunsite.icm.edu.pl/pub/programming/tcl/tcl8_6/tcl8.6.6-src.tar.gz';
set_source 'tar' 
cd unix;
./configure --enable-threads --enable-shared --enable-64bit --prefix=$CUST_INST_PREFIX; 
make;make lib;make install-strip;make install;make all; 
		shift;;
'tk')
fn='tk8.6.6-src.tar.gz'; tn='tk8.6.6'; url='ftp://sunsite.icm.edu.pl/pub/programming/tcl/tcl8_6/tk8.6.6-src.tar.gz';
set_source 'tar' 
cd unix;
./configure --enable-threads --enable-shared --enable-64bit --prefix=$CUST_INST_PREFIX; #- --enable-xft  -with-tcl=$CUST_INST_PREFIX/lib/
make;make install-strip;make install;make all;
		shift;;

'expect')
fn='expect5.45.tar.gz'; tn='expect5.45'; url='https://sourceforge.net/projects/expect/files/Expect/5.45/expect5.45.tar.gz/download';
set_source 'tar' 
configure_build --enable-threads --enable-64bit --enable-shared --prefix=$CUST_INST_PREFIX;
make;make install;make all;
		shift;;
	
'musl')
fn='musl-1.1.16.tar.gz'; tn='musl-1.1.16'; url='http://www.musl-libc.org/releases/musl-1.1.16.tar.gz';
set_source 'tar' 
configure_build --prefix=$CUST_INST_PREFIX;
make;make install;make all;
		shift;;

'libunwind')
fn='libunwind-1.2.tar.gz'; tn='libunwind-1.2'; url='http://download.savannah.nongnu.org/releases/libunwind/libunwind-1.2.tar.gz';
set_source 'tar' 
configure_build --enable-setjmp --enable-block-signals --enable-conservative-checks --enable-msabi-support --enable-minidebuginfo  --enable-conservative-checks --prefix=$CUST_INST_PREFIX; 
make;make install-strip;make install;make all;
		shift;;
		
'libxml2')
fn='libxml2-2.9.4.tar.gz'; tn='libxml2-2.9.4'; url='http://xmlsoft.org/sources/libxml2-2.9.4.tar.gz';
set_source 'tar' 
configure_build --enable-ipv6=yes --with-c14n --with-fexceptions --with-icu --with-python --with-thread-alloc --with-coverage --prefix=$CUST_INST_PREFIX; 
make;make install-strip;make install;make all; 
		shift;;
		
'libxslt')
fn='libxslt-1.1.29.tar.gz'; tn='libxslt-1.1.29'; url='http://xmlsoft.org/sources/libxslt-1.1.29.tar.gz';
set_source 'tar' 
configure_build --prefix=$CUST_INST_PREFIX; 
make;make install-strip;make install;make all; 	
		shift;;

'libedit')
fn='libedit-20170329-3.1.tar.gz'; tn='libedit-20170329-3.1'; url='http://thrysoee.dk/editline/libedit-20170329-3.1.tar.gz';
set_source 'tar' 
configure_build --enable-widec --prefix=$CUST_INST_PREFIX; 
make;make install-strip;make install;make all;
		shift;;

'readline')
fn='readline-7.0.tar.gz'; tn='readline-7.0'; url='http://ftp.gnu.org/gnu/readline/readline-7.0.tar.gz';
set_source 'tar' 
configure_build --enable-shared --with-curses --enable-multibyte --prefix=$CUST_INST_PREFIX; 
make;make install;make all;
		shift;;

'gcc')
fn='gcc-7.1.0.tar.gz'; tn='gcc-7.1.0'; url='http://mirrors.concertpass.com/gcc/releases/gcc-7.1.0/gcc-7.1.0.tar.gz';
set_source 'tar' 
ln -s /usr/include/asm-generic /usr/include/asm
configure_build  --disable-multilib --target=x86_64-pc-linux-gnu --enable-default-pie --enable-gold=yes --enable-languages=all --enable-shared --enable-libiberty --enable-libssp --enable-libasan --enable-libtsan --enable-libgomp --enable-libgcc --enable-libstdc++ --enable-libada --enable-initfini-array --enable-vtable-verify  --enable-objc-gc --enable-lto --enable-tls --enable-threads=posix --with-long-double-128 --enable-decimal-float=yes --with-mpfr=$CUST_INST_PREFIX --with-mpc=$CUST_INST_PREFIX --with-isl=$CUST_INST_PREFIX --with-gmp=$CUST_INST_PREFIX --prefix=$CUST_INST_PREFIX; 
#--enable-noexist#--enable-multilib  --with-multilib-list=m64
make;make install;make all;

if [ -f $CUST_INST_PREFIX/bin/gcc ]; then
	update-alternatives --install /usr/bin/gcc gcc $CUST_INST_PREFIX/bin/gcc 60
	#mv  /usr/lib/x86_64-linux-gnu/libstdc++.so.6 /usr/lib/x86_64-linux-gnu/libOLDstdc++.so.6;
	#ln -s /usr/local/lib64/libstdc++.so.6 /usr/lib/x86_64-linux-gnu/libstdc++.so.6
fi
if [ -f $CUST_INST_PREFIX/bin/cpp ]; then
	update-alternatives --install /usr/bin/cpp cpp $CUST_INST_PREFIX/bin/cpp 60
fi
if [ -f $CUST_INST_PREFIX/bin/c++ ]; then
	update-alternatives --install /usr/bin/c++ c++ $CUST_INST_PREFIX/bin/c++ 60
fi
if [ -f $CUST_INST_PREFIX/bin/g++ ]; then
	update-alternatives --install /usr/bin/g++ g++ $CUST_INST_PREFIX/bin/g++ 60
fi
if [ -f $CUST_INST_PREFIX/bin/ar ]; then
	mv /usr/bin/ar /usr/bin/ar_os;
	update-alternatives --install /usr/bin/ar_os ar /usr/bin/ar_os 10
	update-alternatives --install /usr/bin/ar ar $CUST_INST_PREFIX/bin/ar 60
fi
if [ -f $CUST_INST_PREFIX/bin/ranlib ]; then
	mv /usr/bin/ranlib /usr/bin/ranlib_os;
	update-alternatives --install /usr/bin/ranlib_os ranlib /usr/bin/ranlib_os 10
	update-alternatives --install /usr/bin/ranlib ranlib $CUST_INST_PREFIX/bin/ranlib 60
fi
# --with-cloog=$CUST_INST_PREFIX --disable-cloog-version-check --enable-fixed-point  --enable-stage1-checking=all  --enable-stage1-languages=all #http://gcc.gnu.org/install/configure.html
#http://stackoverflow.com/questions/7832892/how-to-change-the-default-gcc-compiler-in-ubuntu

		shift;;

'gdbm')
fn='gdbm-1.13.tar.gz'; tn='gdbm-1.13'; url='http://ftp.gnu.org/gnu/gdbm/gdbm-1.13.tar.gz';
set_source 'tar' 
configure_build --enable-libgdbm-compat --enable-gdbm-export --prefix=$CUST_INST_PREFIX; 
make;make install-strip;make install;make all;
		shift;;

'libexpat')
fn='R_2_2_0.tar.gz'; tn='libexpat-R_2_2_0'; url='http://github.com/libexpat/libexpat/archive/R_2_2_0.tar.gz';
set_source 'tar' 
cd expat;
./buildconf.sh; ./configure CPPFLAGS=-DXML_LARGE_SIZE --prefix=$CUST_INST_PREFIX; 
make;make lib;make shared;make installlib;make install;
		shift;;
  		
'log4cpp')
fn='v2.9.0-rc1.tar.gz'; tn='log4cpp-2.9.0-rc1'; url='http://github.com/orocos-toolchain/log4cpp/archive/v2.9.0-rc1.tar.gz';
set_source 'tar' 
cmake_build 
make;make install;make all;
		shift;;
		
'gperftools')
fn='gperftools-2.5.tar.gz'; tn='gperftools-2.5'; url='http://github.com/gperftools/gperftools/releases/download/gperftools-2.5/gperftools-2.5.tar.gz';
set_source 'tar' 
configure_build --enable-libunwind --enable-frame-pointers --prefix=$CUST_INST_PREFIX; 
make;make install-strip;make install;make all; 
		shift;;
		
're2')
fn='2017-05-01.tar.gz'; tn='re2-2017-05-01'; url='http://github.com/google/re2/archive/2017-05-01.tar.gz';
set_source 'tar' 
make;make lib; make install;make all; 
		shift;;
	
'icu4c')
fn='icu4c-59_1-src.tgz'; tn='icu'; url='http://download.icu-project.org/files/icu4c/59.1/icu4c-59_1-src.tgz';
set_source 'tar'
cd  source;
./configure --enable-rpath --enable-plugins --prefix=$CUST_INST_PREFIX; 
make;make lib;make install;make all;
		shift;;
		
'boost')
fn='boost_1_64_0.tar.gz'; tn='boost_1_64_0'; url='http://dl.bintray.com/boostorg/release/1.64.0/source/boost_1_64_0.tar.gz';
set_source 'tar' 
wget 'https://github.com/kashirin-alex/environments-builder/raw/master/patches/libboost/wrapper.cpp'; mv wrapper.cpp libs/python/src/
./bootstrap.sh --with-libraries=all --with-icu --prefix=$CUST_INST_PREFIX; #echo "using mpi ;" >> "project-config.jam";
./b2 threading=multi link=shared runtime-link=shared install; # --build-type=complete
		shift;;
		
'fuse')
fn='fuse-3.0.1.tar.gz'; tn='fuse-3.0.1'; url='http://github.com/libfuse/libfuse/releases/download/fuse-3.0.1/fuse-3.0.1.tar.gz';
set_source 'tar' 
configure_build --enable-lib --enable-util --prefix=$CUST_INST_PREFIX; 
make;make lib; make install-strip;make install;make all;
		shift;;
		
'sigar')
fn='hyperic-sigar-1.6.4.tar.gz'; tn='hyperic-sigar-1.6.4'; url='http://sourceforge.net/projects/sigar/files/sigar/1.6/hyperic-sigar-1.6.4.tar.gz/download';
set_source 'tar' 
cp sigar-bin/include/*.h $CUST_INST_PREFIX/include; cp sigar-bin/lib/libsigar-amd64-linux.so $CUST_INST_PREFIX/lib
		shift;;
		
'berkeley-db')
fn='db-6.2.32.tar.gz'; tn='db-6.2.32'; url='http://download.oracle.com/berkeley-db/db-6.2.32.tar.gz';
set_source 'tar' 
cust_conf_path='dist/'
configure_build --enable-shared --enable-cxx --enable-tcl --enable-dbm --prefix=$CUST_INST_PREFIX; # --enable-java --enable-smallbuild
make;make install;make all; 
#echo $CUST_INST_PREFIX/lib > "/etc/ld.so.conf.d/bdb.conf"
		shift;;

'libgpg-error')
fn='libgpg-error-1.27.tar.gz'; tn='libgpg-error-1.27'; url='ftp://ftp.gnupg.org/gcrypt/libgpg-error/libgpg-error-1.27.tar.gz';
set_source 'tar' 
configure_build  --enable-threads=posix --prefix=$CUST_INST_PREFIX; 
make;make install-strip;make install;make all;
		shift;;	
		
'libgcrypt')
fn='libgcrypt-1.7.6.tar.gz'; tn='libgcrypt-1.7.6'; url='ftp://ftp.gnupg.org/gcrypt/libgcrypt/libgcrypt-1.7.6.tar.gz';
set_source 'tar' 
configure_build --enable-m-guard --prefix=$CUST_INST_PREFIX; 
make;make install-strip;make install;make all;
		shift;;	

'libssh')
fn='libssh-0.7.5.tar.xz'; tn='libssh-0.7.5'; url='http://download.openpkg.org/components/cache/libssh2/libssh-0.7.5.tar.xz';#http://red.libssh.org/attachments/download/218/libssh-0.7.5.tar.xz
set_source 'tar' 
cmake_build -DCMAKE_INSTALL_PREFIX=$CUST_INST_PREFIX -DWITH_LIBZ=ON -DWITH_SSH1=ON -DWITH_GCRYPT=ON;
make;make install;make all; 
		shift;;	

'cronolog')
fn='1.7.1.tar.gz'; tn='cronolog-1.7.1'; url='https://github.com/holdenk/cronolog/archive/1.7.1.tar.gz';
set_source 'tar' 
configure_build --prefix=$CUST_INST_PREFIX; 
make;make lib;make install-strip;make install;make all;
		shift;;	
		
'libuv')
fn='libuv-v1.11.0.tar.gz'; tn='libuv-v1.11.0'; url='http://dist.libuv.org/dist/v1.11.0/libuv-v1.11.0.tar.gz';
set_source 'tar' 
./autogen.sh; ./configure --prefix=$CUST_INST_PREFIX; 
make;make install-strip;make install;make all; 
		shift;;	

'libcares')
fn='c-ares-1.12.0.tar.gz'; tn='c-ares-1.12.0'; url='https://c-ares.haxx.se/download/c-ares-1.12.0.tar.gz';
set_source 'tar' 
configure_build  --enable-libgcc --enable-nonblocking --prefix=$CUST_INST_PREFIX; 
make;make install-strip;make install;make all;
		shift;;	
		
'sqlite')
fn='sqlite.tar.gz'; tn='sqlite'; url='https://www.sqlite.org/src/tarball/sqlite.tar.gz';
set_source 'tar' 
configure_build --enable-releasemode --enable-editline --enable-gcov --enable-session --enable-rtree  --enable-json1 --enable-fts5 --enable-fts4 --enable-fts3 --enable-memsys3 --enable-memsys5 --prefix=$CUST_INST_PREFIX; 
make;make install;make all; 
		shift;;	
		
'libjpeg')
fn='jpegsrc.v9b.tar.gz'; tn='jpeg-9b'; url='http://www.ijg.org/files/jpegsrc.v9b.tar.gz';
set_source 'tar' 
configure_build --prefix=$CUST_INST_PREFIX;
make;make install-strip;make install;make all;
		shift;;	

'imagemagick')
fn='ImageMagick-6.7.7-10.tar.xz'; tn='ImageMagick-6.7.7-10'; url='https://www.imagemagick.org/download/releases/ImageMagick-6.7.7-10.tar.xz'; #https://github.com/dahlia/wand/blob/f97277be6d268038a869e59b0d6c3780d7be5664/wand/version.py
set_source 'tar' 
configure_build --enable-shared --with-jpeg=yes --with-quantum-depth=16 --enable-hdri --enable-pipes --enable-hugepages --disable-docs --with-aix-soname=both --with-modules --with-jemalloc --with-umem --prefix=$CUST_INST_PREFIX; 
make;make install-strip;make install;make all;
		shift;;	
		
'harfbuzz')
fn='harfbuzz-1.4.6.tar.bz2'; tn='harfbuzz-1.4.6'; url='https://www.freedesktop.org/software/harfbuzz/release/harfbuzz-1.4.6.tar.bz2';
set_source 'tar' 
configure_build --prefix=$CUST_INST_PREFIX; 
make;make install;make all;
		shift;;	
		
'freetype')
fn='freetype-2.8.tar.gz'; tn='freetype-2.8'; url='http://download.savannah.gnu.org/releases/freetype/freetype-2.8.tar.gz';
set_source 'tar' 
configure_build --prefix=$CUST_INST_PREFIX; 
make;make install;make all;
		shift;;	
		
'fontconfig')
fn='fontconfig-2.12.0.tar.gz'; tn='fontconfig-2.12.0'; url='https://www.freedesktop.org/software/fontconfig/release/fontconfig-2.12.0.tar.gz';
set_source 'tar' 
configure_build --enable-iconv --prefix=$CUST_INST_PREFIX; 
make;make install-strip;make install;make all;
		shift;;				
		
'sparsehash')
fn='sparsehash-2.0.3.tar.gz'; tn='sparsehash-sparsehash-2.0.3'; url='https://github.com/sparsehash/sparsehash/archive/sparsehash-2.0.3.tar.gz';
set_source 'tar' 
configure_build --prefix=$CUST_INST_PREFIX;   # --enable-namespace=gpreftools
make;make install-strip;make install;make all; 	
		shift;;	
		

'openjdk')	
fn='jdk-8u152-ea-bin-b03-linux-x64-19_apr_2017.tar.gz'; tn='jdk1.8.0_152'; url='http://download.java.net/java/jdk8u152/archive/b03/binaries/jdk-8u152-ea-bin-b03-linux-x64-19_apr_2017.tar.gz';
set_source 'tar' 
rm -r  $CUST_JAVA_INST_PREFIX/$sn
mv ../$sn $CUST_JAVA_INST_PREFIX/;

if [ -f $CUST_JAVA_INST_PREFIX/$sn/bin/javac ] &&  [ -f $CUST_JAVA_INST_PREFIX/$sn/jre/bin/java ]; then
	echo "#!/usr/bin/env bash" > $ENV_SETTINGS_PATH/$sn.sh
	echo "export JAVA_HOME=\"$CUST_JAVA_INST_PREFIX/$sn\"" >> $ENV_SETTINGS_PATH/$sn.sh
	echo "export PATH=\$PATH:\"$CUST_JAVA_INST_PREFIX/$sn/bin\"" >> $ENV_SETTINGS_PATH/$sn.sh

	#update-alternatives --install /usr/bin/javac javac $CUST_JAVA_INST_PREFIX/$sn/bin/javac 60
	#update-alternatives --install /usr/bin/java java $CUST_JAVA_INST_PREFIX/$sn/jre/bin/java 60
fi
		shift;;	
		
'apache-ant')
fn='apache-ant-1.10.1-src.tar.gz'; tn='apache-ant-1.10.1'; url='https://www.apache.org/dist/ant/source/apache-ant-1.10.1-src.tar.gz';
set_source 'tar' 
./build.sh install -Ddist.dir=$CUST_JAVA_INST_PREFIX/$sn -Dant.install=$CUST_JAVA_INST_PREFIX/$sn
echo "#!/usr/bin/env bash" > $ENV_SETTINGS_PATH/$sn.sh
echo "export ANT_HOME=\"$CUST_JAVA_INST_PREFIX/$sn\"" >> $ENV_SETTINGS_PATH/$sn.sh
		shift;;	

'apache-maven')	
fn='apache-maven-3.5.0-bin.tar.gz'; tn='apache-maven-3.5.0'; url='http://apache.mediamirrors.org/maven/maven-3/3.5.0/binaries/apache-maven-3.5.0-bin.tar.gz';
set_source 'tar' 
rm -r  $CUST_JAVA_INST_PREFIX/$sn
mv ../$sn $CUST_JAVA_INST_PREFIX/;
if [ -f $CUST_JAVA_INST_PREFIX/$sn/bin/mvn ]; then
	echo "#!/usr/bin/env bash" > $ENV_SETTINGS_PATH/$sn.sh
	echo "export MAVEN_HOME=\"$CUST_JAVA_INST_PREFIX/$sn\"" >> $ENV_SETTINGS_PATH/$sn.sh
	echo "export PATH=\$PATH:\"$CUST_JAVA_INST_PREFIX/$sn/bin\"" >> $ENV_SETTINGS_PATH/$sn.sh

fi
		shift;;	
		
'thrift')
fn='thrift-0.10.0.tar.gz'; tn='thrift-0.10.0'; url='http://archive.apache.org/dist/thrift/0.10.0/thrift-0.10.0.tar.gz';
set_source 'tar' 
cmake_build -DUSE_STD_THREAD=1 -DWITH_STDTHREADS=ON; #-DWITH_BOOSTTHREADS=ON -DOPENSSL_ROOT_DIR=/usr/local/ssl
make -j4;make install;make all;
#configure_build --enable-libs --enable-plugin --with-c_glib  --with-csharp --with-python  --with-qt4  --with-qt5 --prefix=$CUST_INST_PREFIX; 
		shift;;	
		
'attr')
fn='attr-2.4.47.tar.gz'; tn='attr-2.4.47'; url='http://git.savannah.nongnu.org/cgit/attr.git/snapshot/attr-2.4.47.tar.gz';
set_source 'tar' 
make configure;
./configure --enable-gettext=yes --enable-shared=yes --prefix=$CUST_INST_PREFIX;
make;make install-lib;make install-dev;make install;
		shift;;	

'libjansson')
fn='jansson-2.10.tar.gz'; tn='jansson-2.10'; url='http://www.digip.org/jansson/releases/jansson-2.10.tar.gz';
set_source 'tar' 
configure_build --prefix=$CUST_INST_PREFIX;
make install;	
		shift;;
		
'protobuf')
fn='v3.3.1.tar.gz'; tn='protobuf-3.3.1'; url='https://github.com/google/protobuf/archive/v3.3.1.tar.gz';
set_source 'tar' 
cp -r ../$TMP_NAME ../$TMP_NAME-tmp; mv ../$TMP_NAME-tmp gtest;
./autogen.sh;./configure --with-zlib --prefix=$CUST_INST_PREFIX;
make;make install;
		shift;;	
			
'apache-hadoop')
fn='hadoop-2.7.3.tar.gz'; tn='hadoop-2.7.3'; url='http://apache.crihan.fr/dist/hadoop/common/hadoop-2.7.3/hadoop-2.7.3.tar.gz';
set_source 'tar' 
if [ -d $CUST_JAVA_INST_PREFIX/$sn ]; then
	rm -r $CUST_JAVA_INST_PREFIX/$sn;
	rm -r /etc/opt/hadoop;
else 
    mkdir -p /etc/opt;
fi
mv ../$sn $CUST_JAVA_INST_PREFIX/$sn;
#update-alternatives --install /usr/bin/hadoop hadoop $CUST_JAVA_INST_PREFIX/$sn/bin/hadoop 60

ln -s  $CUST_JAVA_INST_PREFIX/$sn/etc/hadoop /etc/opt/hadoop
chmod -R 777 /etc/opt/hadoop
echo "#!/usr/bin/env bash" > $ENV_SETTINGS_PATH/$sn.sh
echo "export HADOOP_HOME=\"$CUST_JAVA_INST_PREFIX/$sn\"" >> $ENV_SETTINGS_PATH/$sn.sh
echo "export HADOOP_CONF_DIR=\"$CUST_JAVA_INST_PREFIX/$sn/etc/hadoop\"" >> $ENV_SETTINGS_PATH/$sn.sh
echo "export HADOOP_VERSION=\"2.8.2\"" >> $ENV_SETTINGS_PATH/$sn.sh
echo "export HADOOP_INCLUDE_PATH=\"$CUST_JAVA_INST_PREFIX/$sn/include\"" >> $ENV_SETTINGS_PATH/$sn.sh
echo "export HADOOP_LIB_PATH=\"$CUST_JAVA_INST_PREFIX/$sn/lib\"" >> $ENV_SETTINGS_PATH/$sn.sh
echo "export PATH=\$PATH:\"$CUST_JAVA_INST_PREFIX/$sn/bin\"" >> $ENV_SETTINGS_PATH/$sn.sh
		shift;;	
		
'nodejs')
fn='node-v7.10.0.tar.xz'; tn='node-v7.10.0'; url='https://nodejs.org/dist/latest-v7.x/node-v7.10.0.tar.xz';
set_source 'tar'
# cp -r ../$sn ../$sn-tmp; mv ../$sn-tmp gtest;
./configure --prefix=$CUST_INST_PREFIX; #--with-intl=none 
make -j$NUM_PROCS;make install;
		shift;;	

'libhoard')
fn='Hoard-3.10-source.tar.gz'; tn='Hoard'; url='https://github.com/emeryberger/Hoard/releases/download/3.10/Hoard-3.10-source.tar.gz';
set_source 'tar' 
cd src;
make linux-gcc-x86-64;mv libhoard.so /usr/local/lib/;
		shift;;	
 	

'libzip')
fn='libzip-1.2.0.tar.xz'; tn='libzip-1.2.0'; url='https://nih.at/libzip/libzip-1.2.0.tar.xz';
set_source 'tar' 
configure_build --prefix=$CUST_INST_PREFIX;
make;make install;	
		shift;;

'unzip')
fn='unzip60.tar.gz'; tn='unzip60'; url='https://sourceforge.net/projects/infozip/files/UnZip%206.x%20%28latest%29/UnZip%206.0/unzip60.tar.gz/download';
set_source 'tar' 
make -f unix/Makefile generic
make prefix=$CUST_INST_PREFIX MANDIR=/usr/local/share/man/man1 -f unix/Makefile install
		shift;;

'gawk')
fn='gawk-4.1.4.tar.xz'; tn='gawk-4.1.4'; url='http://ftp.gnu.org/gnu/gawk/gawk-4.1.4.tar.xz';
set_source 'tar' 
configure_build --prefix=$CUST_INST_PREFIX;
make;make install;	
		shift;;

'pybind11')
fn='master.zip'; tn='pybind11-master'; url='https://github.com/pybind/pybind11/archive/master.zip';
set_source 'zip' 
cmake_build -DPYBIND11_TEST=OFF -DCMAKE_INSTALL_INCLUDEDIR=$CUST_INST_PREFIX/include;
make install;
		shift;;

'hypertable')
fn='master.zip'; tn='hypertable-master'; url='https://github.com/kashirin-alex/hypertable/archive/master.zip';
rm -r $DOWNLOAD_PATH/$sn/$fn
set_source 'zip' 
apt-get -y install rrdtool;
cmake_build  -DHADOOP_INCLUDE_PATH=$HADOOP_INCLUDE_PATH -DHADOOP_LIB_PATH=$HADOOP_LIB_PATH -DTHRIFT_SOURCE_DIR=$BUILDS_PATH/thrift -DCMAKE_INSTALL_PREFIX=/opt/hypertable -DCMAKE_BUILD_TYPE=Release; # -DVERSION_MISC_SUFFIX=$( date  +"%Y-%m-%d_%H-%M") -DBUILD_SHARED_LIBS=ON
make -j$NUM_PROCS VERBOSE=1 ;make install;#make alltests;#  -DPACKAGE_OS_SPECIFIC=1 
		shift;;

'llvm')
fn='llvm-4.0.0.src.tar.xz'; tn='llvm-4.0.0.src'; url='http://releases.llvm.org/4.0.0/llvm-4.0.0.src.tar.xz';
set_source 'tar' 
cmake_build -DCMAKE_BUILD_TYPE=Release -DLLVM_TARGETS_TO_BUILD=X86 -DFFI_INCLUDE_DIR=$CUST_INST_PREFIX/lib/libffi-3.2.1/include -DFFI_LIBRARY_DIR=$CUST_INST_PREFIX/lib64 -DLLVM_ENABLE_FFI=ON -DLLVM_USE_INTEL_JITEVENTS=ON -DLLVM_LINK_LLVM_DYLIB=ON -DCMAKE_INSTALL_PREFIX=$CUST_INST_PREFIX; 
make;make install;
		shift;;


    *)         echo "Unknown build: $sn";       shift;;
  esac
  
}
#########

#########
do_install() {
  for sn in "$@"; do
	if [ $verbose == 1 ]; then
		sleep 3
		do_build;
		sleep 3
	else
		do_build &>> $BUILDS_LOG_PATH/$stage-$sn'.log';
	fi
  done
}
#########

if [  ${#only_sources[@]} -gt 0  ]; then 
	do_install ${only_sources[@]}
	exit 1
fi
#########

#########
compile_and_install(){
	do_install make cmake
	do_install byacc
	do_install m4 gmp mpfr mpc isl
	do_install autoconf automake libtool gawk
	do_install zlib bzip2 unrar gzip snappy lzma libzip unzip
	do_install libatomic_ops libedit libevent libunwind #readline
	do_install openssl libgpg-error libgcrypt libssh icu4c
	do_install log4cpp cronolog fuse sparsehash
	do_install bison texinfo flex binutils gettext nettle libtasn1 libiconv
	do_install libexpat libunistring libidn2 libsodium unbound
	do_install libffi p11-kit gnutls tcltk tk pcre glib openmpi gdbm re2
	do_install expect attr #musl
	do_install libhoard jemalloc gc gperf gperftools patch 
	do_install gcc llvm
	
	if [ $stage -gt 0 ]; then
		do_install boost  
		do_install libpng libjpeg
		do_install libjansson libxml2 libxslt libuv libcares 
	
		do_install python
		do_install openjdk apache-ant apache-maven sigar berkeley-db  
		do_install protobuf apache-hadoop	

		do_install harfbuzz freetype fontconfig 
		do_install sqlite imagemagick
		if [ $stage == 2 ]; then
			do_install pypy2 nodejs thrift pybind11
			do_install hypertable
		fi
	fi
} 
#########

#########
os_releases(){
	if [ $verbose == 1 ]; then
		sleep 5
		_os_releases ${@:1};
		sleep 5
	else
		_os_releases ${@:1} &>> $BUILDS_LOG_PATH/os_releases_$1'.log';
	fi
}
_os_releases(){
	if [ $1 == 'install' ]; then
		echo 'os_releases-install'
		
		apt-get update && apt-get upgrade -y
		apt-get install -y  ufw nano
	 
		if [ ! -f $CUST_INST_PREFIX/bin/make ]; then
			apt-get install -y --reinstall make 
		fi
		if [ ! -f $CUST_INST_PREFIX/bin/gcc ]; then
			apt-get autoremove --purge -y pkg-config build-essential gcc 
			apt-get install -y --reinstall libmount-dev libncurses-dev libreadline-dev
			apt-get install -y --reinstall pkg-config build-essential gcc 
		fi

			#apt-get install -y libedit-dev libunwind-dev libevent-dev libgc-dev libssl-dev libffi-dev libexpat1-dev libxml2-dev libxslt1-dev libre2-dev liblzma-dev libz-dev libbz2-dev libsnappy-dev  libgdbm-dev tk-dev 	
		echo 'fin:os_releases-install'
		
	elif [ $1 == 'uninstall' ]; then
		echo 'os_releases-uninstall'
		if [ -f $CUST_INST_PREFIX/bin/make ] && [ -f $CUST_INST_PREFIX/bin/gcc ]; then
			echo 'pkgs to remove'
			#apt-get autoremove -y --purge python make pkg-config build-essential gcc cpp
		fi
		echo 'fin:os_releases-uninstall'
	fi
}
#########

#########
env_setup(){
	if [ $verbose == 1 ]; then
		sleep 5
		_env_setup ${@:1};
		sleep 5
	else
		_env_setup ${@:1} &>> $BUILDS_LOG_PATH/env_setup_$1'.log';
	fi
}
_env_setup(){
	echo env_setup-$1
	
	if [ $1 == 'pre' ]; then
		#if [ ! -f $CUST_INST_PREFIX/etc/environment.d ]; then
		#	mkdir -p $CUST_INST_PREFIX/etc/environment.d
		#	chmod -R 777 $CUST_INST_PREFIX/etc/environment.d/
		#fi

		#tmp=`fgrep -c $ENV_SETTINGS_PATH /etc/profile`
		#if [ $tmp -eq 0 ]; then
		#	echo '''if [ -d $ENV_SETTINGS_PATH ]; then  for i in $ENV_SETTINGS_PATH*.sh; do    if [ -r $i ]; then       source $i;     fi;   done; unset i; fi; ''' >> /etc/profile;
		#fi
		echo include $LD_CONF_PATH/*.conf > "/etc/ld.so.conf.d/usr.conf"
		echo $CUST_INST_PREFIX/lib64 > $LD_CONF_PATH/lib64.conf
		
		echo '''if [ -d '''$ENV_SETTINGS_PATH''' ]; then  for i in '''$ENV_SETTINGS_PATH'''*.sh; do    if [ -r $i ]; then       source $i;     fi;   done; unset i; fi; ''' > /etc/profile.d/custom_env.sh;
		chmod -R 777 /etc/profile.d/custom_env.sh
		


	elif [ $1 == 'post' ]; then
		if [ -d $ENV_SETTINGS_PATH ]; then
			chmod -R 777 $ENV_SETTINGS_PATH
			sn=${only_sources[@]}
			finalize_build;
		fi
	fi
	
	echo fin:env_setup-$1
}
#########


#########
if [ $stage == 0 ]; then
	env_setup pre
	reuse_make=0
	os_releases install;
	compile_and_install;
	os_releases uninstall;
	stage=1
fi
if [ $stage == 1 ]; then
	reuse_make=0;
	compile_and_install
	stage=2
fi
if [ $stage == 2 ]; then
	reuse_make=0
	compile_and_install
	env_setup post
fi
#########

exit 1

# DRAFTS #######################################################################





echo llvm
mkdir ~/tmpBuilds;cd ~/tmpBuilds;
 rm -r llvm;
wget 'http://releases.llvm.org/4.0.0/llvm-4.0.0.src.tar.xz'
tar xf llvm-4.0.0.src.tar.xz
mv llvm-4.0.0.src llvm;
rm -r llvm_build
mkdir llvm_build;cd llvm_build;
cmake -DLLVM_TARGETS_TO_BUILD=X86 -DFFI_INCLUDE_DIR=/usr/local/lib/libffi-3.2.1/include -DFFI_LIBRARY_DIR=/usr/local/lib64 -DLLVM_ENABLE_FFI=ON -DLLVM_USE_INTEL_JITEVENTS=ON -DLLVM_LINK_LLVM_DYLIB=ON -DCMAKE_INSTALL_PREFIX=/usr/local ../llvm; 
make; make check; make install
cd ~; /sbin/ldconfig



TMP_NAME=libffi; 
echo $TMP_NAME
mkdir ~/tmpBuilds
cd ~/tmpBuilds; rm -r $TMP_NAME;
wget 'http://github.com/libffi/libffi/archive/v3.2.1.tar.gz'
tar xf v3.2.1.tar.gz
mv $TMP_NAME-3.2.1 $TMP_NAME; cd $TMP_NAME;
./autogen.sh
./configure --includedir=/usr/local/include --prefix=/usr/local 
make;make install-strip;make install;make all; 

TMP_NAME=proxygen; 
echo $TMP_NAME
mkdir ~/tmpBuilds
cd ~/tmpBuilds; rm -r $TMP_NAME;
rm master.zip;
wget 'https://github.com/facebook/proxygen/archive/v2017.05.22.00.tar.gz'
tar xf v2017.05.22.00.tar.gz
mv proxygen-2017.05.22.00 $TMP_NAME; cd $TMP_NAME;




TMP_NAME=greeny; 
echo $TMP_NAME
mkdir ~/tmpBuilds
cd ~/tmpBuilds; rm -r $TMP_NAME;
rm master.zip;
wget 'https://github.com/nifigase/greeny/archive/master.zip'
/usr/local/bin/unzip master.zip
mv greeny-master $TMP_NAME; cd $TMP_NAME;



TMP_NAME=poco
echo $TMP_NAME
mkdir ~/tmpBuilds
cd ~/tmpBuilds; rm -r $TMP_NAME;
wget 'https://pocoproject.org/releases/poco-1.7.8/poco-1.7.8p2.tar.gz'
tar xf poco-1.7.8p2.tar.gz
mv  poco-1.7.8p2 $TMP_NAME;cd $TMP_NAME
./configure --shared --unbundled --everything --config=Linux --prefix=/usr/local; 
make; make install;



TMP_NAME=pybind11; 
echo $TMP_NAME
mkdir ~/tmpBuilds
cd ~/tmpBuilds; rm -r $TMP_NAME;
rm master.zip;
wget 'https://github.com/pybind/pybind11/archive/master.zip'
/usr/local/bin/unzip master.zip
mv pybind11-master $TMP_NAME; 
cd $TMP_NAME;
cmake -DPYBIND11_PYPY_VERSION=2.7 -DPYBIND11_TEST=OFF -DCMAKE_INSTALL_INCLUDEDIR=/usr/local/include;

apt-get -y install rrdtool #apt-get -y install nodejs-dev

TMP_NAME=hypertable; 
echo $TMP_NAME
mkdir ~/tmpBuilds
cd ~/tmpBuilds; rm -r $TMP_NAME;
rm master.zip;
wget 'https://github.com/kashirin-alex/hypertable/archive/master.zip'
/usr/local/bin/unzip master.zip
mv hypertable-master $TMP_NAME; 
mkdir $TMP_NAME-build;cd $TMP_NAME-build;

cmake -DVERSION_ADD_COMMIT_SUFFIX=$( date  +"%Y-%m-%d_%H-%M") -DHADOOP_INCLUDE_PATH=$HADOOP_INCLUDE_PATH -DHADOOP_LIB_PATH=$HADOOP_LIB_PATH -DTHRIFT_SOURCE_DIR=~/builds/sources/thrift -DCMAKE_INSTALL_PREFIX=/opt/hypertable -DCMAKE_BUILD_TYPE=Release -DBUILD_SHARED_LIBS=ON ../$TMP_NAME
#  -DPACKAGE_OS_SPECIFIC=1 
make -j8; make install; make alltests;
cd ~; /sbin/ldconfig



TMP_NAME=nghttp2
echo $TMP_NAME
mkdir ~/tmpBuilds
cd ~/tmpBuilds; rm -r $TMP_NAME;
wget 'https://github.com/nghttp2/nghttp2/releases/download/v1.17.0/nghttp2-1.17.0.tar.xz'
tar xf nghttp2-1.17.0.tar.xz
mv nghttp2-1.17.0 $TMP_NAME;cd $TMP_NAME
autoreconf -i
automake
autoconf
./configure --enable-app --prefix=/usr/local; 
make; make install;




https://www.openfabrics.org/downloads/libibverbs/libibverbs-1.1.4-1.24.gb89d4d7.tar.gz

TMP_NAME=leveldb
echo $TMP_NAME
mkdir ~/tmpBuilds
cd ~/tmpBuilds; rm -r $TMP_NAME;
wget 'https://github.com/google/leveldb/archive/v1.20.tar.gz'
tar xf v1.20.tar.gz
mv leveldb-1.20 $TMP_NAME;cd $TMP_NAME; 
make;
mv out-shared /usr/local/leveldb;
echo /usr/local/leveldb > "/etc/ld.so.conf.d/leveldb.conf"
 
TMP_NAME=ceph
echo $TMP_NAME
mkdir ~/tmpBuilds
cd ~/tmpBuilds; rm -r $TMP_NAME;
wget 'http://download.ceph.com/tarballs/ceph_12.0.3.orig.tar.gz'
tar xf ceph_12.0.3.orig.tar.gz
mv ceph-12.0.3 $TMP_NAME;cd $TMP_NAME; 
./do_cmake.sh -DWITH_MANPAGE=
 ./configure --without-build  --enable-cephfs-java --with-cephfs  --with-mon   --with-osd    --with-cryptopp  --with-nss  --with-jemalloc  --with-tcmalloc-minimal  --with-libzfs  --prefix=/usr/local; #--enable-client  --enable-server  
./do_cmake.sh; #KRB5_PREFIX




TMP_NAME=gf-complete
echo $TMP_NAME
mkdir ~/tmpBuilds
cd ~/tmpBuilds; rm -r $TMP_NAME;
wget 'http://lab.jerasure.org/jerasure/gf-complete/repository/archive.tar.gz'  -O gf-complete.tar.gz
tar xf gf-complete.tar.gz
mv gf-complete.git $TMP_NAME;cd $TMP_NAME
./autogen.sh; ./configure --enable-avx --prefix=/usr/local; 
make; make install;

TMP_NAME=jerasure
echo $TMP_NAME
mkdir ~/tmpBuilds
cd ~/tmpBuilds; rm -r $TMP_NAME;
wget 'http://www.kaymgee.com/Kevin_Greenan/Software_files/jerasure.tar.gz'
tar xf jerasure.tar.gz
mv jerasure $TMP_NAME;cd $TMP_NAME
./configure --prefix=/usr/local; 
make; make install;

TMP_NAME=qfs
echo $TMP_NAME
mkdir ~/tmpBuilds
cd ~/tmpBuilds; rm -r $TMP_NAME;
wget 'https://github.com/quantcast/qfs/archive/1.2.1.tar.gz'
tar xzf 1.2.1.tar.gz
mv qfs-1.2.1 $TMP_NAME;
mkdir $TMP_NAME-build;cd $TMP_NAME-build;
cmake -DFUSE_INCLUDE_DIRS=/usr/local/include/fuse3 -DFUSE_LIBRARIES=/usr/local/lib/libfuse3.so -DOPENSSL_ROOT_DIR=/usr/local/ssl -DQFS_USE_STATIC_LIB_LINKAGE=OFF -DCMAKE_BUILD_TYPE=Release ../$TMP_NAME
make; make check; make install
cd ~; /sbin/ldconfig



TMP_NAME=libgssapi
echo $TMP_NAME
mkdir ~/tmpBuilds
cd ~/tmpBuilds; rm -r $TMP_NAME;
wget 'http://www.citi.umich.edu/projects/nfsv4/linux/libgssapi/libgssapi-0.11.tar.gz'
tar xzf libgssapi-0.11.tar.gz
mv libgssapi-0.11 $TMP_NAME;cd $TMP_NAME;
./configure  --prefix=/usr/local; 
make;  make install;

TMP_NAME=nfs-ganesha
echo $TMP_NAME
mkdir ~/tmpBuilds
cd ~/tmpBuilds; rm -r $TMP_NAME;
wget 'https://github.com/nfs-ganesha/nfs-ganesha/archive/V2.5-rc7.tar.gz'
tar xzf V2.5-rc7.tar.gz
mv nfs-ganesha-2.5-rc7 $TMP_NAME;
mkdir $TMP_NAME-build;cd $TMP_NAME-build;
cmake -DUSE_GSS=OFF -DUSE_TSAN=ON -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/usr/local  ../$TMP_NAME/src






#### > libX11 > 
apt-get install -y libx11-dev 
apt-get install -y rrdtools
libpthread-stubs0-dev libx11-dev libx11-doc libxau-dev libxcb 1-dev libxdmcp-dev x11proto-core-dev x11proto-input-dev x11proto-kb-dev xorg-sgml-doctools xtrans-dev


TMP_NAME=xorg-macros
echo $TMP_NAME
mkdir ~/tmpBuilds
cd ~/tmpBuilds; rm -r $TMP_NAME;
wget 'https://www.x.org/releases/X11R7.7/src/everything/util-macros-1.17.tar.gz'
tar xf util-macros-1.17.tar.gz
mv util-macros-1.17 $TMP_NAME;cd $TMP_NAME; 
./configure  --prefix=/usr/local;
make; make install

ldconfig

TMP_NAME=libpthread-stubs
echo $TMP_NAME
mkdir ~/tmpBuilds
cd ~/tmpBuilds; rm -r $TMP_NAME;
wget 'https://www.x.org/releases/X11R7.7/src/xcb/libpthread-stubs-0.3.tar.gz'
tar xf libpthread-stubs-0.3.tar.gz
mv libpthread-stubs-0.3 $TMP_NAME;cd $TMP_NAME; 
./configure  --prefix=/usr/local;
make; make install

ldconfig

TMP_NAME=libXau
echo $TMP_NAME
mkdir ~/tmpBuilds
cd ~/tmpBuilds; rm -r $TMP_NAME;
wget 'https://www.x.org/releases/X11R7.7/src/lib/libXau-1.0.7.tar.gz'
tar xf libXau-1.0.7.tar.gz
mv libXau-1.0.7 $TMP_NAME;cd $TMP_NAME; 
./configure  --prefix=/usr/local;
make; make install

ldconfig

TMP_NAME=libxcb
echo $TMP_NAME
mkdir ~/tmpBuilds
cd ~/tmpBuilds; rm -r $TMP_NAME;
wget 'https://www.x.org/releases/X11R7.7/src/xcb/libxcb-1.8.1.tar.gz'
tar xf libxcb-1.8.1.tar.gz
mv libxcb-1.8.1 $TMP_NAME;cd $TMP_NAME; 
./configure --disable-static --prefix=/usr/local;
make; make install

ldconfig

TMP_NAME=xtrans
echo $TMP_NAME
mkdir ~/tmpBuilds
cd ~/tmpBuilds; rm -r $TMP_NAME;
wget 'https://www.x.org/releases/X11R7.7/src/lib/xtrans-1.2.7.tar.gz'
tar xf xtrans-1.2.7.tar.gz
mv xtrans-1.2.7 $TMP_NAME;cd $TMP_NAME; 
./configure  --prefix=/usr/local;
make; make install

ldconfig

TMP_NAME=inputproto
echo $TMP_NAME
mkdir ~/tmpBuilds;
cd ~/tmpBuilds; rm -r $TMP_NAME;
wget 'https://www.x.org/releases/X11R7.7/src/proto/inputproto-2.2.tar.gz'
tar xf inputproto-2.2.tar.gz
mv inputproto-2.2 $TMP_NAME;cd $TMP_NAME; 
./configure  --prefix=/usr/local;
make; make install

ldconfig

TMP_NAME=kbproto
echo $TMP_NAME
mkdir ~/tmpBuilds;
cd ~/tmpBuilds; rm -r $TMP_NAME;
wget 'https://www.x.org/releases/X11R7.7/src/proto/kbproto-1.0.6.tar.gz'
tar xf kbproto-1.0.6.tar.gz
mv kbproto-1.0.6 $TMP_NAME;cd $TMP_NAME; 
./configure  --prefix=/usr/local;
make; make install

ldconfig

TMP_NAME=xproto
echo $TMP_NAME
mkdir ~/tmpBuilds
cd ~/tmpBuilds; rm -r $TMP_NAME;
wget 'https://www.x.org/releases/X11R7.7/src/proto/xproto-7.0.23.tar.gz'
tar xf xproto-7.0.23.tar.gz
mv xproto-7.0.23 $TMP_NAME;cd $TMP_NAME; 
./configure  --prefix=/usr/local;
make; make install

ldconfig

TMP_NAME=libX11
echo $TMP_NAME
mkdir ~/tmpBuilds
cd ~/tmpBuilds; rm -r $TMP_NAME;
wget 'https://www.x.org/releases/X11R7.7/src/lib/libX11-1.5.0.tar.gz'
tar xf libX11-1.5.0.tar.gz
mv libX11-1.5.0 $TMP_NAME;cd $TMP_NAME; 
./configure  --prefix=/usr/local;
make; make install

####### > libX11

TMP_NAME=libX11
echo $TMP_NAME
mkdir ~/tmpBuilds
cd ~/tmpBuilds; rm -r $TMP_NAME;
wget 'https://github.com/mirror/libX11/archive/libX11-1.6.5.tar.gz'
tar xf libX11-1.6.5.tar.gz
mv libX11-1.6.5 $TMP_NAME;cd $TMP_NAME; 
./configure  --prefix=/usr/local;
make; make install







libpcre3 librsvg2 libexif

 pixman
xcb-proto libxcb xextproto libX11
renderproto libXrender libXrender
cairo pango rrdtool



TMP_NAME=pixman
echo $TMP_NAME
mkdir ~/tmpBuilds
cd ~/tmpBuilds; rm -r $TMP_NAME;
wget 'https://www.cairographics.org/releases/pixman-0.34.0.tar.gz'
tar xf pixman-0.34.0.tar.gz
mv pixman-0.34.0 $TMP_NAME;cd $TMP_NAME; 
./configure --prefix=/usr/local; #
make; make check; make install



TMP_NAME=xcb-proto
echo $TMP_NAME
mkdir ~/tmpBuilds
cd ~/tmpBuilds; rm -r $TMP_NAME;
wget 'https://www.x.org/releases/X11R7.7/src/xcb/xcb-proto-1.7.1.tar.gz'
tar xf xcb-proto-1.7.1.tar.gz
mv xcb-proto-1.7.1 $TMP_NAME;cd $TMP_NAME; 
./configure  --prefix=/usr/local;
make; make install


TMP_NAME=xextproto
echo $TMP_NAME
mkdir ~/tmpBuilds
cd ~/tmpBuilds; rm -r $TMP_NAME;
wget 'https://www.x.org/releases/X11R7.7/src/proto/xextproto-7.2.1.tar.gz'
tar xf xextproto-7.2.1.tar.gz
mv xextproto-7.2.1 $TMP_NAME;cd $TMP_NAME; 
./configure  --prefix=/usr/local;
make; make install




TMP_NAME=renderproto
echo $TMP_NAME
mkdir ~/tmpBuilds
cd ~/tmpBuilds; rm -r $TMP_NAME;
wget 'https://www.x.org/archive/individual/proto/renderproto-0.11.1.tar.gz'
tar xf renderproto-0.11.1.tar.gz
mv renderproto-0.11.1 $TMP_NAME;cd $TMP_NAME; 
./configure  --prefix=/usr/local;
make; make install

TMP_NAME=libXrender
echo $TMP_NAME
mkdir ~/tmpBuilds
cd ~/tmpBuilds; rm -r $TMP_NAME;
wget 'https://www.x.org/archive//individual/lib/libXrender-0.9.10.tar.gz'
tar xf libXrender-0.9.10.tar.gz
mv libXrender-0.9.10 $TMP_NAME;cd $TMP_NAME; 
./configure  --prefix=/usr/local;
make; make install


TMP_NAME=cairo
echo $TMP_NAME
mkdir ~/tmpBuilds
cd ~/tmpBuilds; rm -r $TMP_NAME;
wget 'https://www.cairographics.org/releases/cairo-1.14.8.tar.xz'
tar xf cairo-1.14.8.tar.xz
mv cairo-1.14.8 $TMP_NAME;cd $TMP_NAME; 
./configure --enable-tee --enable-fc=yes --enable-ft=yes --enable-xml=yes  --enable-pthread=yes --enable-xlib=yes  --enable-xlib-xrender=yes  --enable-xcb=yes --enable-xlib-xcb=yes --prefix=/usr/local;
make; make install

TMP_NAME=pango
echo $TMP_NAME
mkdir ~/tmpBuilds
cd ~/tmpBuilds; rm -r $TMP_NAME;
wget 'http://ftp.gnome.org/pub/GNOME/sources/pango/1.40/pango-1.40.0.tar.xz'
tar xf pango-1.40.0.tar.xz
mv pango-1.40.0 $TMP_NAME;cd $TMP_NAME; 
./configure  --prefix=/usr/local; #
make; make check; make install



TMP_NAME=rrdtool
echo $TMP_NAME
mkdir ~/tmpBuilds
cd ~/tmpBuilds; rm -r $TMP_NAME;
wget 'http://oss.oetiker.ch/rrdtool/pub/rrdtool-1.7.0.tar.gz'
tar xf rrdtool-1.7.0.tar.gz
mv rrdtool-1.7.0 $TMP_NAME;cd $TMP_NAME; 

./configure --enable-tcl-site  --disable-ruby --disable-lua   --disable-docs  --disable-examples --prefix=/usr/local; #
make; make check;make installlib;  make install; make lib; make install-lib
cd ~; /sbin/ldconfig






##############################
echo pkg-config
cd ~/dependeciesBuilds; rm -r pkg-config;
wget 'http://pkg-config.freedesktop.org/releases/pkg-config-0.29.2.tar.gz'
tar xf pkg-config-0.29.2.tar.gz
mv pkg-config-0.29.2 pkg-config; cd pkg-config
./configure --with-internal-glib --prefix=/usr/local; 
make; make check; make install
cd ~; /sbin/ldconfig

echo wayland-protocols
cd ~/dependeciesBuilds; rm -r wayland-protocols;
wget 'http://wayland.freedesktop.org/releases/weston-2.0.0.tar.xz'
tar xf weston-2.0.0.tar.xz
mv weston-2.0.0 wayland-protocols; cd wayland-protocols
./configure --enable-xwayland --enable-x11-compositor --enable-wayland-compositor --enable-fbdev-compositor --enable-headless-compositor --prefix=/usr/local; 
make; make check; make install
cd ~; /sbin/ldconfig

# --enable-wayland-backend
echo gtk
cd ~/dependeciesBuilds; rm -r gtk;
wget 'http://ftp.gnome.org/pub/gnome/sources/gtk+/3.90/gtk+-3.90.0.tar.xz'
tar xf gtk+-3.90.0.tar.xz
mv gtk+-3.90.0 gtk; cd gtk
./configure --enable-shared --enable-static  --enable-x11-backend  --enable-win32-backend --enable-quartz-backend --enable-broadway-backend --enable-mir-backend --enable-quartz-relocation --enable-test-print-backend --prefix=/usr/local; 
make; make check; make install
cd ~; /sbin/ldconfig

echo classpath
cd ~/dependeciesBuilds; rm -r classpath;
wget 'http://ftp.gnu.org/gnu/classpath/classpath-0.99.tar.gz'
tar xf classpath-0.99.tar.gz
mv classpath-0.99 classpath; cd classpath
./configure --with-gmp=/usr/local --enable-collections --enable-jni --enable-core-jni --enable-gstreamer-peer --enable-default-toolkit --enable-xmlj --enable-gmp --enable-regen-headers --enable-tool-wrappers --enable-tools --enable-local-sockets --prefix=/usr/local; 
make; make check; make install
cd ~; /sbin/ldconfig

echo gnu-crypto
cd ~/dependeciesBuilds; rm -r gnu-crypto;
wget 'http://ftp.ntua.gr/mirror/gnu/gnu-crypto/gnu-crypto-2.1.0.tar.gz'
tar xf gnu-crypto-2.1.0.tar.gz
mv gnu-crypto-2.1.0 gnu-crypto; cd gnu-crypto
./configure  --prefix=/usr/local; make; make check; make install
cd ~; /sbin/ldconfig
##############################


echo glibc
cd ~/tmpBuilds; rm -r glibc;
wget 'http://ftp.gnu.org/gnu/libc/glibc-2.25.tar.xz'
tar xf glibc-2.25.tar.xz
mv glibc-2.25 glibc; cd glibc
wget 'https://ftp.gnu.org/gnu/libc/glibc-linuxthreads-2.5.tar.bz2'
tar xf glibc-linuxthreads-2.5.tar.bz2
cd ..; mkdir build-glibc; cd build-glibc
../glibc/configure  --enable-add-ons=linuxthreads --enable-shared --enable-lock-elision=yes --enable-stack-protector=all  --enable-tunables --enable-mathvec --with-fp --prefix=/usr/local/glibc;
 make; make check; make install #  --enable-multi-arch --disable-sanity-checks 
cd ~; /sbin/ldconfig

echo llvm_mono
cd ~/dependeciesBuilds; rm -r llvm_mono;
wget 'http://github.com/mono/llvm/archive/RELEASE_27.tar.gz'
tar xvf RELEASE_27.tar.gz
mv llvm-RELEASE_27 llvm_mono;cd llvm_mono
./configure  --enable-targets="x86_64"  --prefix=/usr/local ; --enable-jit --enable-threads  --enable-libffi --enable-optimized --enable-bindings --enable-ltdl-install ;
make; make check; make install
cd ~; /sbin/ldconfig

echo mono
cd ~/dependeciesBuilds; rm -r mono;
wget 'http://download.mono-project.com/sources/mono/mono-5.0.0.94.tar.bz2'
tar xf mono-5.0.0.94.tar.bz2
mv mono-5.0.0 mono; cd mono
./configure --enable-parallel-mark --enable-big-arrays --enable-llvm --enable-loadedllvm  --enable-llvm-runtime --enable-vtune --enable-icall-symbol-map --enable-dynamic-btls --enable-icall-export --with-tls=pthread --with-bitcode=yes --prefix=/usr/local; 
make; make check; make install
cd ~; /sbin/ldconfig









TMP_NAME=guile-gtk
echo $TMP_NAME
mkdir ~/tmpBuilds
cd ~/tmpBuilds; rm -r $TMP_NAME;
wget 'http://ftp.gnu.org/gnu/guile-gtk/guile-gtk-2.1.tar.gz'
tar xf guile-gtk-2.1.tar.gz
mv guile-gtk-2.1 $TMP_NAME;cd $TMP_NAME; 
./configure  --prefix=/usr/local;# 
make; make all; make install;

TMP_NAME=guile
echo $TMP_NAME
mkdir ~/tmpBuilds
cd ~/tmpBuilds; rm -r $TMP_NAME;
wget 'https://ftp.gnu.org/gnu/guile/guile-2.0.13.tar.xz'
tar xf guile-2.0.13.tar.xz
mv guile-2.0.13 $TMP_NAME;cd $TMP_NAME; 
./configure --prefix=/usr/local;# 
make; make install;

TMP_NAME=autogen
echo $TMP_NAME
mkdir ~/tmpBuilds
cd ~/tmpBuilds; rm -r $TMP_NAME;
wget 'http://ftp.gnu.org/gnu/autogen/rel5.18.12/autogen-5.18.12.tar.gz'
tar xf autogen-5.18.12.tar.gz
mv autogen-5.18.12 $TMP_NAME;cd $TMP_NAME; 
./configure  --prefix=/usr/local;



#https://www.x.org/pub/individual/util/util-macros-1.19.1.tar.bz2
TMP_NAME=mkfontdir
echo $TMP_NAME
mkdir ~/tmpBuilds
cd ~/tmpBuilds; rm -r $TMP_NAME;
wget 'https://www.x.org/releases/individual/app/mkfontdir-1.0.7.tar.gz'
tar xf mkfontdir-1.0.7.tar.gz
mv mkfontdir-1.0.7 $TMP_NAME;cd $TMP_NAME; 
./configure  --prefix=/usr/local;
make; make all; make install;

TMP_NAME=intlfonts
echo $TMP_NAME
mkdir ~/tmpBuilds
cd ~/tmpBuilds; rm -r $TMP_NAME;
wget 'http://ftp.ntua.gr/mirror/gnu/intlfonts/intlfonts-1.2.1.tar.gz'
tar xf intlfonts-1.2.1.tar.gz
mv  intlfonts-1.2.1 $TMP_NAME;cd $TMP_NAME; 
./configure --with-type1 --with-truetype --prefix=/usr/local;

make; make all; make install;


TMP_NAME=readline
echo $TMP_NAME
mkdir ~/tmpBuilds
cd ~/tmpBuilds; rm -r $TMP_NAME;
wget 'http://ftp.gnu.org/gnu/readline/readline-7.0.tar.gz'
tar xf readline-7.0.tar.gz
mv readline-7.0 $TMP_NAME;cd $TMP_NAME
./configure --enable-shared --with-curses --enable-multibyte --prefix=/usr/local;
make; make shared; make all;make install;

TMP_NAME=ncurses
echo $TMP_NAME
mkdir ~/tmpBuilds
cd ~/tmpBuilds; rm -r $TMP_NAME;
wget 'http://ftp.gnu.org/gnu/ncurses/ncurses-6.0.tar.gz'
tar xf ncurses-6.0.tar.gz
mv ncurses-6.0 $TMP_NAME;cd $TMP_NAME

./configure  --enable-pc-file --with-libtool --with-shared --with-profile --with-cxx-shared --with-termlib --with-gpm --enable-rpath --enable-widec --enable-sp-funcs --enable-const --with-pthread --enable-pthreads-eintr --enable-weak-symbols --enable-reentrant --enable-wgetch-events --prefix=/usr/local;
# --with-hashed-db --with-ticlib
make; make check;make installlib;  make install; make lib; make install-lib
cd ~; /sbin/ldconfig



#echo openldap
#cd ~/dependeciesBuilds; rm -r openldap;
#wget 'ftp://ftp.openldap.org/pub/OpenLDAP/openldap-release/openldap-2.4.44.tgz'
#tar xzvf openldap-2.4.44.tgz
#mv openldap-2.4.44 openldap; cd openldap
#./configure --enable-backends=no --enable-ldap=yes  --enable-sock=yes --prefix=/usr/local;
#make depend; make; make check; make install
#cd ~; /sbin/ldconfig



mkdir ~/dependeciesBuilds
echo krb5
cd ~/dependeciesBuilds; rm -r krb5;
wget 'http://github.com/krb5/krb5/archive/krb5-1.15.1-final.tar.gz'
tar xzvf krb5-1.15.1-final.tar.gz
mv krb5-krb5-1.15.1-final krb5; cd krb5/src
./autoconf
./configure  --with-size-optimizations --prefix=/usr/local; 
make; make check; make install;
cd ~; /sbin/ldconfig


http://ftp.ntua.gr/mirror/gnu/libmicrohttpd/











echo pcre2
cd ~/dependeciesBuilds; rm -r pcre2;
wget 'ftp://ftp.csx.cam.ac.uk/pub/software/programming/pcre/pcre2-10.23.tar.gz'
tar xf pcre2-10.23.tar.gz
mv pcre2-10.23 pcre2; cd pcre2
./configure --enable-pcre2-16 --enable-pcre2-32 --enable-jit --enable-pcre2grep-libz  --enable-pcre2grep-libbz2  --enable-pcre2test-libedit --prefix=/usr/local; 
make; make check; make install
cd ~; /sbin/ldconfig


echo heimdal
cd ~/dependeciesBuilds
wget 'http://github.com/heimdal/heimdal/archive/master.zip' --output-document=heimdal.zip
unzip heimdal.zip
#git clone git://svn.h5l.org/heimdal.git
cd heimdal-master
autoreconf -f -i
./configure --with-mips-abi=64 --enable-pthread-support; make; make install # --enable-dce
cd ~; /sbin/ldconfig
 	

echo ppl
cd ~/dependeciesBuilds; rm -r ppl;
wget 'ftp://ftp.cs.unipr.it/pub/ppl/releases/1.2/ppl-1.2.tar.xz'
tar xf ppl-1.2.tar.xz
mv ppl-1.2 ppl; cd ppl
./configure --enable-cxx --with-cxx=cpp --enable-ppl_lcdd --enable-ppl_lpsol --enable-ppl_pips --prefix=/usr/local;  
make; make check; make install
cd ~; /sbin/ldconfig

echo freepooma
cd ~/dependeciesBuilds
wget 'http://download.savannah.gnu.org/releases/freepooma/freepooma-2.4.1.tar.gz'
tar xf freepooma-2.4.1.tar.gz
cd freepooma-2.4.1
mkdir TAUDIR
export TAUDIR=/root/dependeciesBuilds/freepooma-2.4.1/TAUDIR
mkdir PDTDIR
export PDTDIR=/root/dependeciesBuilds/freepooma-2.4.1/PDTDIR
./configure --arch LINUXgcc --prefix /usr/local --threads --sched mcveMultiQ --shared --mpi --opt; make depend; make; make install
cd ~; /sbin/ldconfig

echo cloog
cd ~/dependeciesBuilds
git clone http://github.com/periscop/cloog.git
cd cloog
./get_submodules.sh
./autogen.sh
./configure; make; make install
cd ~; /sbin/ldconfig

echo piplib
cd ~/dependeciesBuilds
git clone http://github.com/periscop/piplib.git
cd piplib
./autogen.sh
./configure; make; make install
cd ~; /sbin/ldconfig





echo gss
cd ~/dependeciesBuilds
wget http://ftp.gnu.org/gnu/gss/gss-1.0.3.tar.gz
tar xzvf gss-1.0.3.tar.gz
cd gss-1.0.3
./configure; make; make install
cd ~; /sbin/ldconfig

echo globus_toolkit
cd ~/dependeciesBuilds
wget http://toolkit.globus.org/ftppub/gt6/installers/src/globus_toolkit-6.0.tar.gz
tar xzf globus_toolkit-6.0.tar.gz
cd globus_toolkit-6.0
./configure --enable-ltdl-install  --enable-udt; make; make install
cd ~; /sbin/ldconfig

 apt-get install -y libgssglue-dev libjson-perl libxt-dev

echo gssapi-mechglue
cd ~/dependeciesBuilds
wget ftp://ftp.ncsa.uiuc.edu/aces/gssapi-mechglue/mechglue-ncsa-latest.tar.gz
tar xzvf mechglue-ncsa-latest.tar.gz
cd mechglue-ncsa-20070501
./configure --enable-pthread-support --enable-dce; make; make install
cd ~; /sbin/ldconfig



echo ncurses
cd ~/dependeciesBuilds
wget http://ftp.gnu.org/pub/gnu/ncurses/ncurses-5.9.tar.gz
tar xzvf ncurses-5.9.tar.gz
cd ncurses-5.9
./configure --prefix=/usr --with-shared --without-debug --enable-widec; make; make install
mv -v /usr/lib/libncursesw.so.5* /lib
ln -sfv ../../lib/$(readlink /usr/lib/libncursesw.so) /usr/lib/libncursesw.so
for lib in ncurses form panel menu ; do
    rm -vf                    /usr/lib/lib${lib}.so
    echo "INPUT(-l${lib}w)" > /usr/lib/lib${lib}.so
    ln -sfv lib${lib}w.a      /usr/lib/lib${lib}.a
    ln -sfv ${lib}w.pc        /usr/lib/pkgconfig/${lib}.pc
done
ln -sfv libncurses++w.a /usr/lib/libncurses++.a
rm -vf                     /usr/lib/libcursesw.so
echo "INPUT(-lncursesw)" > /usr/lib/libcursesw.so
ln -sfv libncurses.so      /usr/lib/libcurses.so
ln -sfv libncursesw.a      /usr/lib/libcursesw.a
ln -sfv libncurses.a       /usr/lib/libcurses.a
make distclean
./configure --prefix=/usr    \
            --with-shared    \
            --without-normal \
            --without-debug  \
            --without-cxx-binding
make sources libs
cp -av lib/lib*.so.5* /usr/lib
cd ~; /sbin/ldconfig


#echo util-linux #warning kerner version mismaches 
#cd ~/dependeciesBuilds
#wget 'ftp://ftp.kernel.org/pub/linux/utils/util-linux/v2.24/util-linux-2.24.tar.gz'
#tar xzvf util-linux-2.24.tar.gz
#cd util-linux-2.24
#./configure --with-python=no --disable-mount --disable-libmount --enable-libuuid --enable-libblkid; make; make install
#cd ~; /sbin/ldconfig

apt-get -y --allow-unauthenticated install default-jdk
apt-get -y --allow-unauthenticated install ant

echo libchdfs
cd ~/dependeciesBuilds
/bin/rm -rf libchdfs*
wget 'http://github.com/yankay/libchdfs/archive/master.zip' --output-document=libchdfs-master.zip
unzip libchdfs-master.zip
cd libchdfs-master
autoconf  --output=configure; ./configure; echo "CXXFLAGS += -fPIC" >> Makefile; make all
mv /root/dependeciesBuilds/libchdfs-master/hadoop.h /usr/local/include
mv /root/dependeciesBuilds/libchdfs-master/libhadoop.so /usr/local/lib
cd ~; /sbin/ldconfig


#echo kosmosfs
#cd ~
#wget 'http://sourceforge.net/projects/kosmosfs/files/kosmosfs/kfs-0.5/kfs-0.5.tar.gz/download' --output-document=kfs-0.5.tar.gz
#tar xzvf kfs-0.5.tar.gz
#cd kfs-0.5
#mkdir build
#cd build
#cmake -D CMAKE_BUILD_TYPE=RelWithDebInfo ~/kfs-0.5/
#make
#make install
#cd ~; /sbin/ldconfig

# apt-get install -y --allow-unauthenticated  libcephfs-dev libcephfs1
#echo ceph
#cd ~
#wget http://ceph.com/download/ceph-0.75.tar.gz
#tar xzvf ceph-0.75.tar.gz
#cd ceph-0.75
#./configure --with-libzfs --disable-cephfs-java; make; make install
#cd ~; /bin/rm -rf ~/ceph-0.75*
#/sbin/ldconfig
#echo CDH4
#cd ~
#wget  http://archive.cloudera.com/cdh4/one-click-install/precise/amd64/cdh4-repository_1.0_all.deb
#dpkg -i cdh4-repository_1.0_all.deb

rm -r /opt/hypertable

rm -r ~/build/
mkdir -p ~/build/hypertable

ps aux | grep -ie make | awk '{print $2}' | xargs kill -9 
ps aux | grep -ie hyper | awk '{print $2}' | xargs kill -9 
cd ~/build/hypertable
cmake ~/src/hypertable






#rm nohup.out
#nohup make -j5 &
#tail nohup.out

#rm -r /opt/hypertable

#make install

#cd /opt/hypertable/0.9.7.15/conf
#nano hypertable.cfg

#192.168.0.200

#ps aux | grep -ie LOAD_AND_BACKUP | awk '{print $2}' | xargs kill -9 
#ps aux | grep -ie hyper | awk '{print $2}' | xargs kill -9 
#/opt/hypertable/0.9.7.15/bin/start-dfsbroker.sh qfs
#/opt/hypertable/0.9.7.15/bin/clean-hyperspace.sh
#/opt/hypertable/0.9.7.15/bin/clean-database.sh


#cd /opt/hypertable/0.9.7.15/

#rm -rf /opt/hypertable/0.9.7.15/hyperspace/* /opt/hypertable/0.9.7.15/log/* /var/opt/hypertable/log/* /opt/hypertable/0.9.7.15/fs/* /opt/hypertable/0.9.7.15/run/rsml_backup/* /opt/hypertable/0.9.7.15/run/last-dfs
#/opt/hypertable/0.9.7.15/bin/fhsize.sh

#/opt/hypertable/0.9.7.15/bin/clean-database.sh
#ps aux | grep -ie hyper | awk '{print $2}' | xargs kill -9 
#ps aux | grep -ie hyper | awk '{print $2}' | xargs kill -9 
#/opt/hypertable/0.9.7.15/bin/start-all-servers.sh qfs

#ps aux | grep -ie LOAD_AND_BACKUP | awk '{print $2}' | xargs kill -9 
#echo "CREATE NAMESPACE NET; quit;" | /opt/hypertable/0.9.7.15/bin/ht shell

#nohup bash /home/www/LOAD_AND_BACKUP-test.sh NET 10000 100 2 &
#cd log
#tail DfsBroker.qfs.log
	arch=`uname -m`

if [ $arch == "i386" ] || [ $arch == "i586" ] || [ $arch == "i686" ] ; then
  ARCH=32
elif [ $arch == "x86_64" ] ; then
  ARCH=64
else
  echo "Unknown processor architecture: $arch"
  exit 1
fi
echo "Release: $(lsb_release -sc)"
echo "Arch: $arch"


#cd ~/build/hypertable
#nohup make alltests &


#ps aux | grep -ie qfs | awk '{print $2}' | xargs kill -9 
