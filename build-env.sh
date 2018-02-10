#!/usr/bin/env bash
## Author Kashirin Alex (kashirin.alex@gmail.com)

# nohup bash ~/builder/build-env.sh --sources all &> '/root/builder/built.log' &
  
################## DIRCETOTRIES CONFIGURATIONS ##################
CUST_INST_PREFIX=/usr/local
CUST_JAVA_INST_PREFIX=/usr/java

SCRIPTS_PATH=~/builder/scripts
BUILDS_ROOT=~/builds
DOWNLOAD_PATH=$BUILDS_ROOT/downloads
BUILDS_PATH=$BUILDS_ROOT/sources
BUILDS_LOG_PATH=$BUILDS_ROOT/logs/$( date  +"%Y-%m-%d_%H-%M-%S")
BUILTS_PATH=$BUILDS_ROOT/builts

ENV_SETTINGS_PATH=$CUST_INST_PREFIX/etc/profile.d/
LD_CONF_PATH=$CUST_INST_PREFIX/etc/ld.so.conf.d
##################################################################

os_r=$(cat /etc/issue.net);
echo $os_r;
if [[ $os_r == *"Ubuntu"* ]]; then 
	os_r='Ubuntu';
elif [[ $os_r == *"openSUSE"* ]]; then 
	os_r='openSUSE';
fi


build_target='node'
reuse_make=0
test_make=0
verbose=0
only_dw=0
help=''
stage=0
c=0
only_sources=()

ARGS=("$@")
while [ $# -gt 0 ]; do	
  let c=c+1;

  case $1 in
    --reuse-make) 	
		reuse_make=0
	;;
    --test-make)  		
		test_make=1
	;;
    --target)  		
		build_target=$2;
	;;
    --only-dw)  		
		only_dw=1;
	;;
    --verbose)  		
		verbose=1;
	;;
    --stage)  		
		stage=$2;
	;;
	--sources) 
		echo --sources at $c :
		echo ${ARGS[@]:$c}
		only_sources=(${ARGS[@]:$c});
		echo $only_sources
	;;
    --help)  			
		help='--help'
	;;
  esac
  shift
done

if [ ${#only_sources[@]} -eq 0 ]; then 
	echo '	--sources must be set with "all" or sources names'
	echo $only_sources
	exit 1
fi
build_all=0
if [ ${#only_sources[@]} -eq 1 ] && [ ${only_sources[0]} == 'all' ]; then 
	only_sources=()
	build_all=1
	#verbose=0;  
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


echo '--target:' $build_target
echo '--verbose:' $verbose
echo '--sources:' ${only_sources[@]}
echo '--help:' $help
echo '--stage:' $stage
echo '--test_make:' $test_make
echo '--reuse-make:' $reuse_make
echo '--only-dw:' $only_dw
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
_install_prefix(){
	echo $CUST_INST_PREFIX; #/$sn
}
_build(){
	echo `uname -m`-$os_r-linux-gnu;
}

download() {
	if [ ! -f $DOWNLOAD_PATH/$sn/$sn.ext ]; then
		echo 'downloading:' $sn.ext: $url;
		if [ ! -d $DOWNLOAD_PATH/$sn ]; then
			mkdir $DOWNLOAD_PATH/$sn;
		fi	
		cd $DOWNLOAD_PATH/$sn;

		wget -O $sn.ext -nv --tries=3 --no-check-certificate $url;
	fi
}
extract() {
	echo 'extracting:'$sn'.ext to '$sn;
	if [ -d $BUILDS_PATH/$sn ]; then
		echo 'removing old:' $BUILDS_PATH/$sn;
		rm -r $BUILDS_PATH/$sn;
	fi
	cd $BUILDS_PATH; 
	
	if [ $archive_type == 'tar' ]; then
		tar xf $DOWNLOAD_PATH/$sn/$sn.ext;
	elif [ $archive_type == 'zip' ]; then
		unzip $DOWNLOAD_PATH/$sn/$sn.ext;
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
	if [ $1 == '--no-build' ]; then
		$BUILDS_PATH/$sn/${cust_conf_path}configure ${@:2} $help;
	else
		$BUILDS_PATH/$sn/${cust_conf_path}configure ${@:1} --build=`_build` $help;
	fi
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
do_make() {
	echo 'make args:' -j$NUM_PROCS  ${@:1} VERBOSE=1;
	make -j$NUM_PROCS ${@:1} VERBOSE=1;
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
	if [ `_install_prefix` != $CUST_INST_PREFIX ]; then
		paths=''
		if [ -d `_install_prefix`/lib ]; then
			paths=`_install_prefix`/lib;
		fi
		if [ -d `_install_prefix`/lib64 ]; then
			paths=$paths\\n`_install_prefix`/lib64
		fi
		if [ paths != '' ]; then 
			echo -e $paths > $LD_CONF_PATH/$sn.conf;
		fi
	fi
	source /etc/profile
	source ~/.bashrc
	cd $BUILDS_ROOT; ldconfig
	echo 'finished:' $sn;
	echo -e '\n\n\n'
}
#########

#########
do_build() {
	echo '-------------------------------'
	echo 'doing_build:' $sn 'stage:' $stage
	if [ -f $SCRIPTS_PATH/$sn.sh ]; then
		source $SCRIPTS_PATH/$sn.sh
	else
		_do_build #${@:1}
	fi
	finalize_build
	echo 'done_build:' $sn 'stage:' $stage
	echo '-------------------------------'
}
_do_build() {
  
  case $sn in
		
'make')
tn='make-4.2'; url='http://ftp.gnu.org/gnu/make/make-4.2.tar.gz';
set_source 'tar';
if [ $only_dw == 1 ];then return;fi
configure_build --with-guile --prefix=`_install_prefix`;
do_make;do_make install-strip;do_make install;do_make all;
		shift;;

'libtool')
tn='libtool-2.4.6'; url='http://ftpmirror.gnu.org/libtool/libtool-2.4.6.tar.gz';
set_source 'tar';
if [ $only_dw == 1 ];then return;fi
configure_build --enable-ltdl-install  --prefix=`_install_prefix`;
do_make;do_make install-strip;do_make install;do_make all; 
		shift;;
		
'autoconf')
tn='autoconf-2.69'; url='http://ftp.gnu.org/gnu/autoconf/autoconf-2.69.tar.xz';
set_source 'tar';
if [ $only_dw == 1 ];then return;fi
configure_build --prefix=`_install_prefix`;
do_make;do_make lib;do_make install-strip;do_make install;do_make all;
		shift;;
		
'automake')
tn='automake-1.15.1'; url='http://ftp.gnu.org/gnu/automake/automake-1.15.1.tar.xz';
set_source 'tar';
if [ $only_dw == 1 ];then return;fi
configure_build --prefix=`_install_prefix`;
do_make;do_make lib; do_make install;do_make all; 
		shift;;
		
'cmake')
tn='cmake-3.10.2'; url='http://cmake.org/files/v3.10/cmake-3.10.2.tar.gz';
set_source 'tar';
if [ $only_dw == 1 ];then return;fi
bootstrap_build --prefix=`_install_prefix`;
do_make;do_make install;do_make all;
		shift;;

'zlib')
tn='zlib-1.2.11'; url='http://zlib.net/zlib-1.2.11.tar.gz';
set_source 'tar';
if [ $only_dw == 1 ];then return;fi
configure_build --no-build --prefix=`_install_prefix`; 
do_make;do_make install;do_make all; 
		shift;;
		
'bzip2')
tn='bzip2-1.0.6'; url='http://www.bzip.org/1.0.6/bzip2-1.0.6.tar.gz';
set_source 'tar';
if [ $only_dw == 1 ];then return;fi
do_make -f Makefile-libbz2_so;do_make install PREFIX=`_install_prefix`;
cp -av libbz2.so* `_install_prefix`/lib/; ln -sv `_install_prefix`/lib/libbz2.so.1.0.6 `_install_prefix`/lib/libbz2.so
		shift;;

'unrar')
tn='unrar'; url='http://www.rarlab.com/rar/unrarsrc-5.5.8.tar.gz';
set_source 'tar';
if [ $only_dw == 1 ];then return;fi
make DESTDIR=`_install_prefix`;make lib DESTDIR=`_install_prefix`;make install-lib DESTDIR=`_install_prefix`;make install DESTDIR=`_install_prefix`;make all DESTDIR=`_install_prefix`;
		shift;;
		
'gzip')
tn='gzip-1.9'; url='http://ftp.gnu.org/gnu/gzip/gzip-1.9.tar.xz';
set_source 'tar';
if [ $only_dw == 1 ];then return;fi
configure_build --enable-threads=posix --prefix=`_install_prefix`; 
do_make;do_make lib;do_make install-strip;do_make install;do_make all;
		shift;;
		
'lzo')
tn='lzo-2.10'; url='http://www.oberhumer.com/opensource/lzo/download/lzo-2.10.tar.gz';
set_source 'tar';
if [ $only_dw == 1 ];then return;fi
configure_build --enable-shared --prefix=`_install_prefix`; 
do_make;do_make install;
		shift;;
		
'snappy')
tn='snappy-1.1.7'; url='http://github.com/google/snappy/archive/1.1.7.tar.gz';
set_source 'tar';
if [ $only_dw == 1 ];then return;fi
cmake_build -DSNAPPY_BUILD_TESTS=0 -DBUILD_SHARED_LIBS=1 -DCMAKE_INSTALL_PREFIX=`_install_prefix`;
make;make install; 	
		shift;;

'xz')
tn='xz-5.2.3'; url='http://tukaani.org/xz/xz-5.2.3.tar.gz';
set_source 'tar';
if [ $only_dw == 1 ];then return;fi
configure_build --prefix=`_install_prefix`; 
do_make;do_make lib;do_make install-strip;do_make install;do_make all; 
		shift;;
		
'p7zip')
tn='p7zip_16.02'; url='http://sourceforge.net/projects/p7zip/files/p7zip/16.02/p7zip_16.02_src_all.tar.bz2/download';
set_source 'tar';
if [ $only_dw == 1 ];then return;fi
do_make;do_make all; ./install.sh; 
		shift;;
		
'tar')
tn='tar-1.30'; url='http://ftp.gnu.org/gnu/tar/tar-1.30.tar.xz';
set_source 'tar';
if [ $only_dw == 1 ];then return;fi
export FORCE_UNSAFE_CONFIGURE=1; configure_build --prefix=`_install_prefix`; unset FORCE_UNSAFE_CONFIGURE;
do_make;do_make lib;do_make install-strip;do_make install;
		shift;;
	
'libpng')
tn='libpng-1.6.34'; url='ftp://ftp.simplesystems.org/pub/libpng/png/src/libpng16/libpng-1.6.34.tar.gz';
set_source 'tar';
if [ $only_dw == 1 ];then return;fi
configure_build --prefix=`_install_prefix`;
do_make;do_make install-strip;do_make install;do_make all; 
		shift;;
		
'm4')
tn='m4-1.4.18'; url='http://ftp.gnu.org/gnu/m4/m4-1.4.18.tar.xz';
set_source 'tar';
if [ $only_dw == 1 ];then return;fi
configure_build --enable-c++ --enable-threads=posix --prefix=`_install_prefix`;
do_make;do_make lib;do_make install-strip;do_make install;do_make all;
		shift;;
	
'byacc')
tn='byacc-20170709'; url='ftp://ftp.invisible-island.net/pub/byacc/byacc-20170709.tgz';
set_source 'tar';
if [ $only_dw == 1 ];then return;fi
configure_build --prefix=`_install_prefix`;
do_make;do_make install;do_make all;
		shift;;	

'gmp')
tn='gmp-6.1.2'; url='http://ftp.gnu.org/gnu/gmp/gmp-6.1.2.tar.xz';
set_source 'tar';
if [ $only_dw == 1 ];then return;fi
sed -i 's/-lncurses/-lncursesw/g' configure;
configure_build --enable-cxx --enable-fat --enable-assert --prefix=`_install_prefix`;
do_make;do_make install;do_make all;
		shift;;
		
'mpfr')
tn='mpfr-4.0.0'; url='http://ftp.gnu.org/gnu/mpfr/mpfr-4.0.0.tar.xz';
set_source 'tar';
if [ $only_dw == 1 ];then return;fi
configure_build --enable-decimal-float --enable-thread-safe --with-gmp-build=$BUILTS_PATH/gmp/ --prefix=`_install_prefix`;
do_make;do_make install-strip;do_make install;do_make all; 
		shift;;
		
'mpc')
tn='mpc-1.1.0'; url='http://ftp.gnu.org/gnu/mpc/mpc-1.1.0.tar.gz';
set_source 'tar';
if [ $only_dw == 1 ];then return;fi
configure_build --prefix=`_install_prefix`;
do_make;do_make install-strip;do_make install;do_make all;
		shift;;
		
'isl')
tn='isl-0.18'; url='http://gcc.gnu.org/pub/gcc/infrastructure/isl-0.18.tar.bz2';
set_source 'tar';
if [ $only_dw == 1 ];then return;fi
configure_build --with-gmp=build --with-gmp-builddir=$BUILTS_PATH/gmp/ --prefix=`_install_prefix`;
do_make;do_make install-strip;do_make install;do_make all;
		shift;;
		
'bison')
tn='bison-3.0.4'; url='http://ftp.gnu.org/gnu/bison/bison-3.0.4.tar.gz';
set_source 'tar';
if [ $only_dw == 1 ];then return;fi
configure_build --enable-threads=posix --prefix=`_install_prefix`;
do_make; do_make lib;do_make install-strip;do_make install;do_make all;
		shift;;
		
'texinfo')
tn='texinfo-6.5'; url='http://ftp.gnu.org/gnu/texinfo/texinfo-6.5.tar.xz';
set_source 'tar';
if [ $only_dw == 1 ];then return;fi
sed -i 's/ncurses/ncursesw/g' configure;
configure_build --enable-threads=posix --prefix=`_install_prefix`;
do_make;do_make install-strip;do_make install;do_make all; 
		shift;;
		
'flex')
tn='flex-2.6.4'; url='http://github.com/westes/flex/releases/download/v2.6.4/flex-2.6.4.tar.gz';
set_source 'tar';
if [ $only_dw == 1 ];then return;fi
configure_build --prefix=`_install_prefix`;
do_make;do_make lib;do_make install-strip;do_make install;do_make all;
		shift;;
		
'coreutils')
tn='coreutils-8.29'; url='http://ftp.gnu.org/gnu/coreutils/coreutils-8.29.tar.xz';
set_source 'tar';
if [ $only_dw == 1 ];then return;fi
FORCE_UNSAFE_CONFIGURE=1 configure_build --enable-install-program=hostname --prefix=`_install_prefix`; 
do_make;do_make lib;do_make install-strip;do_make install;do_make all;unset FORCE_UNSAFE_CONFIGURE;
		shift;;
		
'binutils')
tn='binutils-2.30'; url='http://ftp.ntua.gr/mirror/gnu/binutils/binutils-2.30.tar.xz';
set_source 'tar';
if [ $only_dw == 1 ];then return;fi
configure_build --enable-plugins --enable-gold=yes --enable-ld=yes --enable-libada --enable-libssp --enable-lto --enable-objc-gc --enable-vtable-verify  --with-system-zlib --with-mpfr=`_install_prefix` --with-mpc=`_install_prefix` --with-isl=`_install_prefix` --with-gmp=`_install_prefix` --prefix=`_install_prefix`; 
do_make tooldir=`_install_prefix`; do_make tooldir=`_install_prefix` install-strip;do_make tooldir=`_install_prefix` install;do_make tooldir=`_install_prefix` all; # libiberty> --enable-shared=opcodes --enable-shared=bfd --enable-host-shared --enable-stage1-checking=all --enable-stage1-languages=all 
		shift;;
		
'keyutils')
tn='keyutils-1.5.10'; url='http://people.redhat.com/~dhowells/keyutils/keyutils-1.5.10.tar.bz2';
set_source 'tar';
if [ $only_dw == 1 ];then return;fi
sed -i 's/\/usr\/bin\//\/usr\/local\/bin\//g' Makefile;
make DESTDIR=`_install_prefix`/ SHAREDIR=share MANDIR=share LIBDIR=lib INCLUDEDIR=include; make DESTDIR=`_install_prefix`/ MANDIR=share SHAREDIR=share LIBDIR=lib INCLUDEDIR=include install;
		shift;;
	
'gettext')
tn='gettext-0.19.8.1'; url='http://ftp.gnu.org/pub/gnu/gettext/gettext-0.19.8.1.tar.xz';
set_source 'tar';
if [ $only_dw == 1 ];then return;fi
sed -i 's/ncurses/ncursesw/g' configure;sed -i 's/ncurses/ncursesw/g' gettext-tools/configure;
configure_build --enable-threads=posix --prefix=`_install_prefix`; 
do_make; do_make install-strip;do_make install;do_make all;
		shift;;
		
'nettle')
tn='nettle-3.4'; url='http://ftp.gnu.org/gnu/nettle/nettle-3.4.tar.gz';
set_source 'tar';
if [ $only_dw == 1 ];then return;fi
configure_build --enable-gcov --enable-x86-aesni --enable-fat --libdir=`_install_prefix`/lib --prefix=`_install_prefix`; 
do_make;do_make install;do_make all;
		shift;;
		
'libtasn1')
tn='libtasn1-4.13'; url='http://ftp.gnu.org/gnu/libtasn1/libtasn1-4.13.tar.gz';
set_source 'tar';
if [ $only_dw == 1 ];then return;fi
configure_build --prefix=`_install_prefix`; 
do_make;do_make lib;do_make install-strip;do_make install;do_make all;  	
		shift;;
		
'libiconv')
tn='libiconv-1.15'; url='http://ftp.gnu.org/pub/gnu/libiconv/libiconv-1.15.tar.gz';
set_source 'tar';
if [ $only_dw == 1 ];then return;fi
configure_build --enable-extra-encodings --prefix=`_install_prefix`; 
do_make;do_make lib;do_make install-lib;do_make install-strip;do_make install;do_make all; 
		shift;;
		
'libunistring')
tn='libunistring-0.9.8'; url='http://ftp.gnu.org/gnu/libunistring/libunistring-0.9.8.tar.xz';
set_source 'tar';
if [ $only_dw == 1 ];then return;fi
configure_build --enable-threads=posix --prefix=`_install_prefix`; 
do_make;do_make lib;do_make install-strip;do_make install;do_make all;
		shift;;
		
'libidn2')
tn='libidn2-2.0.4'; url='http://ftp.gnu.org/pub/gnu/libidn/libidn2-2.0.4.tar.gz';
set_source 'tar';
if [ $only_dw == 1 ];then return;fi
configure_build --prefix=`_install_prefix`; 
do_make;do_make lib;do_make install-strip;do_make install;do_make all;
		shift;;
		
'libsodium')
tn='libsodium-1.0.16'; url='http://github.com/jedisct1/libsodium/releases/download/1.0.16/libsodium-1.0.16.tar.gz';
set_source 'tar';
if [ $only_dw == 1 ];then return;fi
configure_build --enable-minimal --prefix=`_install_prefix`; 
do_make;do_make install-strip;do_make install;do_make all; 
		shift;;
		
'unbound')
tn='unbound-1.6.8'; url='http://www.unbound.net/downloads/unbound-1.6.8.tar.gz';
set_source 'tar';
if [ $only_dw == 1 ];then return;fi
configure_build --enable-tfo-client --enable-tfo-server --enable-dnscrypt --with-pyunbound --prefix=`_install_prefix`; 
do_make;do_make lib;do_make install-lib;do_make install;do_make all; 
		shift;;
		
'libffi')
tn='libffi-3.2.1'; url='http://github.com/libffi/libffi/archive/v3.2.1.tar.gz';
set_source 'tar';
if [ $only_dw == 1 ];then return;fi
autogen_build;configure_build --prefix=`_install_prefix`; 
do_make;do_make install-strip;do_make install;do_make all; 
		shift;;
		
'p11-kit')
tn='p11-kit-0.23.9'; url='http://github.com/p11-glue/p11-kit/releases/download/0.23.9/p11-kit-0.23.9.tar.gz';
set_source 'tar';
if [ $only_dw == 1 ];then return;fi
configure_build --without-trust-paths --prefix=`_install_prefix`; 
do_make;do_make install-strip;do_make install;do_make all; 
		shift;;
		
'gnutls')
tn='gnutls-3.6.1'; url='http://www.gnupg.org/ftp/gcrypt/gnutls/v3.6/gnutls-3.6.1.tar.xz';
set_source 'tar';
if [ $only_dw == 1 ];then return;fi
configure_build --disable-gtk-doc --enable-openssl-compatibility --prefix=`_install_prefix`; 
do_make;do_make lib;do_make install-strip;do_make install;do_make all;
		shift;;
		
'openmpi')
tn='openmpi-3.0.0'; url='http://www.open-mpi.org/software/ompi/v3.0/downloads/openmpi-3.0.0.tar.gz';
set_source 'tar';
if [ $only_dw == 1 ];then return;fi
configure_build --prefix=`_install_prefix`; #--enable-mpi-fortran
do_make;do_make install-strip;do_make install;do_make all; 
		shift;;
		
'pcre')
tn='pcre-8.41'; url='http://ftp.pcre.org/pub/pcre/pcre-8.41.tar.gz';
set_source 'tar';
if [ $only_dw == 1 ];then return;fi
configure_build --enable-newline-is-any --enable-pcre16 --enable-pcre32 --enable-jit --enable-pcregrep-libz --enable-pcregrep-libbz2 --enable-unicode-properties --enable-utf --enable-ucp --prefix=`_install_prefix`; #  --enable-utf8
do_make;do_make install-strip;do_make install;do_make all; 
		shift;;	
		
'pcre2')
tn='pcre2-10.30'; url='http://ftp.pcre.org/pub/pcre/pcre2-10.30.tar.gz';
set_source 'tar';
if [ $only_dw == 1 ];then return;fi
configure_build --enable-rebuild-chartables --enable-newline-is-any --enable-pcre2-16 --enable-pcre2-32 --enable-jit --enable-pcre2grep-libz --enable-pcre2grep-libbz2 --enable-unicode-properties --enable-utf --enable-ucp --prefix=`_install_prefix`; #  --enable-utf8
do_make;do_make install-strip;do_make install;do_make all; 
		shift;;
		
'glib')
tn='glib-2.55.1'; url='http://ftp.acc.umu.se/pub/gnome/sources/glib/2.55/glib-2.55.1.tar.xz';
set_source 'tar';
if [ $only_dw == 1 ];then return;fi
configure_build --with-libiconv=gnu --with-threads=posix --prefix=`_install_prefix`; 
do_make; do_make install-strip;do_make install;do_make all;
		shift;;

'jemalloc')
tn='jemalloc-5.0.1'; url='http://github.com/jemalloc/jemalloc/releases/download/5.0.1/jemalloc-5.0.1.tar.bz2';
set_source 'tar';
if [ $only_dw == 1 ];then return;fi
configure_build --enable-lazy-lock --enable-xmalloc --prefix=`_install_prefix`; 
do_make;do_make lib;do_make install;do_make all;
		shift;;
		
'libevent')
tn='libevent-2.1.8-stable'; url='http://github.com/libevent/libevent/releases/download/release-2.1.8-stable/libevent-2.1.8-stable.tar.gz';
set_source 'tar';
if [ $only_dw == 1 ];then return;fi
configure_build --prefix=`_install_prefix`; 
do_make;do_make install-strip;do_make install;do_make all;  
		shift;;
	
'libatomic_ops')
tn='libatomic_ops-7.6.2'; url='http://www.hboehm.info/gc/gc_source/libatomic_ops-7.6.2.tar.gz';
set_source 'tar';
if [ $only_dw == 1 ];then return;fi
configure_build --enable-shared --prefix=`_install_prefix`; 
do_make;do_make install-strip;do_make install;do_make all;
		shift;;
		
'gc')
tn='gc-7.6.4'; url='http://www.hboehm.info/gc/gc_source/gc-7.6.4.tar.gz';
set_source 'tar';
if [ $only_dw == 1 ];then return;fi
configure_build --enable-single-obj-compilation --enable-large-config --enable-redirect-malloc --enable-sigrt-signals --enable-parallel-mark --enable-handle-fork --enable-cplusplus  --with-libatomic-ops=yes --prefix=`_install_prefix`;  # --enable-threads=posix  // GC Warning: USE_PROC_FOR_LIBRARIES + GC_LINUX_THREADS performs poorly
do_make;do_make install-strip;do_make install;do_make all;
		shift;;
	
'gperf')
tn='gperf-3.1'; url='http://ftp.gnu.org/gnu/gperf/gperf-3.1.tar.gz';
set_source 'tar';
if [ $only_dw == 1 ];then return;fi
configure_build --prefix=`_install_prefix`; 
do_make;do_make lib; do_make install;do_make all; 
		shift;;
	
'patch')
tn='patch-2.7.5'; url='http://ftp.gnu.org/gnu/patch/patch-2.7.5.tar.xz';
set_source 'tar';
if [ $only_dw == 1 ];then return;fi
configure_build --prefix=`_install_prefix`; 
do_make;do_make lib;do_make install-strip;do_make install;do_make all;
		shift;;
		
'tcltk')
tn='tcl8.6.6'; url='ftp://sunsite.icm.edu.pl/pub/programming/tcl/tcl8_6/tcl8.6.6-src.tar.gz';
set_source 'tar';
if [ $only_dw == 1 ];then return;fi
cd unix;./configure --enable-threads --enable-shared --enable-64bit --build=`_build` --prefix=`_install_prefix`; 
make;make install-strip;make install;make all; 
		shift;;
'tk')
tn='tk8.6.6'; url='ftp://sunsite.icm.edu.pl/pub/programming/tcl/tcl8_6/tk8.6.6-src.tar.gz';
set_source 'tar';
if [ $only_dw == 1 ];then return;fi
cd unix;
./configure --enable-threads --enable-shared --enable-64bit --build=`_build` --prefix=`_install_prefix`; #- --enable-xft  -with-tcl=`_install_prefix`/lib/
do_make;do_make install-strip;do_make install;do_make all;
		shift;;

'expect')
tn='expect5.45.3'; url='http://sourceforge.net/projects/expect/files/Expect/5.45.3/expect5.45.3.tar.gz/download';
set_source 'tar';
if [ $only_dw == 1 ];then return;fi
configure_build --enable-threads --enable-64bit --enable-shared --prefix=`_install_prefix`;
do_make;do_make install;do_make all;
		shift;;
	
'musl')
tn='musl-1.1.16'; url='http://www.musl-libc.org/releases/musl-1.1.16.tar.gz';
set_source 'tar';
if [ $only_dw == 1 ];then return;fi
configure_build --prefix=`_install_prefix`;
do_make;do_make install;do_make all;
		shift;;

'libunwind')
tn='libunwind-1.2.1'; url='http://download.savannah.nongnu.org/releases/libunwind/libunwind-1.2.1.tar.gz';
set_source 'tar';
if [ $only_dw == 1 ];then return;fi
configure_build --enable-setjmp --enable-block-signals --enable-conservative-checks --enable-msabi-support --enable-minidebuginfo  --enable-conservative-checks --prefix=`_install_prefix`; 
do_make;do_make install-strip;do_make install;do_make all;
		shift;;
		
'libxml2')
tn='libxml2-2.9.7'; url='http://xmlsoft.org/sources/libxml2-2.9.7.tar.gz';
set_source 'tar';
if [ $only_dw == 1 ];then return;fi
configure_build --enable-ipv6=yes --with-c14n --with-fexceptions --with-icu --with-python --with-thread-alloc --with-coverage --prefix=`_install_prefix`; 
do_make;do_make install-strip;do_make install;do_make all; 
		shift;;
		
'libxslt')
tn='libxslt-1.1.32'; url='http://xmlsoft.org/sources/libxslt-1.1.32.tar.gz';
set_source 'tar';
if [ $only_dw == 1 ];then return;fi
configure_build --prefix=`_install_prefix`; 
do_make;do_make install-strip;do_make install;do_make all; 	
		shift;;

'libeditline')
tn='libedit-20170329-3.1'; url='http://thrysoee.dk/editline/libedit-20170329-3.1.tar.gz';
set_source 'tar';
if [ $only_dw == 1 ];then return;fi
sed -i 's/-lncurses/-lncursesw/g' configure;
configure_build --prefix=`_install_prefix`; 
do_make SHLIB_LIBS="-lncursesw";do_make install-strip;do_make install;do_make all;
		shift;;

'termcap')
tn='termcap-1.3.1'; url='http://ftp.gnu.org/gnu/termcap/termcap-1.3.1.tar.gz';
set_source 'tar';
if [ $only_dw == 1 ];then return;fi
configure_build --enable-shared --prefix=`_install_prefix`;
do_make;do_make install;do_make all;
		shift;;
		
'libreadline')
tn='readline-7.0'; url='http://ftp.gnu.org/gnu/readline/readline-7.0.tar.gz';
set_source 'tar';
if [ $only_dw == 1 ];then return;fi
sed -i 's/-lncurses/-lncursesw/g' configure;
configure_build --enable-shared --with-curses --enable-multibyte --prefix=`_install_prefix`; 
make SHLIB_LIBS="-lncursesw";make install;
		shift;;

'gdbm')
tn='gdbm-1.14.1'; url='http://ftp.gnu.org/gnu/gdbm/gdbm-1.14.1.tar.gz';
set_source 'tar';
if [ $only_dw == 1 ];then return;fi
sed -i 's/ncurses/ncursesw/g' configure;
configure_build --enable-libgdbm-compat --enable-gdbm-export --prefix=`_install_prefix`; 
make;make install-strip;make install;make all;
		shift;;

'libexpat')
tn='libexpat-R_2_2_5/expat'; url='http://github.com/libexpat/libexpat/archive/R_2_2_5.tar.gz';
set_source 'tar';
if [ $only_dw == 1 ];then return;fi
cmake_build -DCMAKE_INSTALL_PREFIX=`_install_prefix`;
do_make;do_make install;
		shift;;
  		
'log4cpp')
tn='log4cpp-2.9.0-rc1'; url='http://github.com/orocos-toolchain/log4cpp/archive/v2.9.0-rc1.tar.gz';
set_source 'tar';
if [ $only_dw == 1 ];then return;fi
cmake_build 
do_make;do_make install;do_make all;
		shift;;
		
'gperftools')
tn='gperftools-2.6.3'; url='http://github.com/gperftools/gperftools/releases/download/gperftools-2.6.3/gperftools-2.6.3.tar.gz';
set_source 'tar';
if [ $only_dw == 1 ];then return;fi
configure_build --enable-libunwind --enable-frame-pointers --prefix=`_install_prefix`; 
do_make;do_make install-strip;do_make install;do_make all; 
		shift;;
		
're2')
tn='re2-2018-02-01'; url='http://github.com/google/re2/archive/2018-02-01.tar.gz';
set_source 'tar';
if [ $only_dw == 1 ];then return;fi
do_make;do_make lib; do_make install;do_make all; 
		shift;;
	
'icu4c')
tn='icu/source'; url='http://download.icu-project.org/files/icu4c/60.2/icu4c-60_2-src.tgz';
set_source 'tar';
if [ $only_dw == 1 ];then return;fi
echo '' > LICENSE;
configure_build --enable-rpath --enable-plugins --prefix=`_install_prefix`; 
do_make;do_make lib;do_make install;do_make all;
		shift;;
		
'boost')
tn='boost_1_66_0'; url='http://dl.bintray.com/boostorg/release/1.66.0/source/boost_1_66_0.tar.bz2';
set_source 'tar';
if [ $only_dw == 1 ];then return;fi
./bootstrap.sh --with-libraries=all --with-icu --prefix=`_install_prefix`; #
#echo "using mpi ;" >> "project-config.jam"; --without-mpi --build-type=complete
./b2 threading=multi link=shared runtime-link=shared install; #
		shift;;
	
'fuse')
tn='fuse-3.1.1'; url='http://github.com/libfuse/libfuse/releases/download/fuse-3.1.1/fuse-3.1.1.tar.gz';
set_source 'tar';
if [ $only_dw == 1 ];then return;fi
configure_build --enable-lib --enable-util --prefix=`_install_prefix`; 
do_make;do_make lib; do_make install-strip;do_make install;do_make all;
		shift;;
		
'sigar')
tn='hyperic-sigar-1.6.4'; url='http://sourceforge.net/projects/sigar/files/sigar/1.6/hyperic-sigar-1.6.4.tar.gz/download';
set_source 'tar';
if [ $only_dw == 1 ];then return;fi
cp sigar-bin/include/*.h `_install_prefix`/include; cp sigar-bin/lib/libsigar-amd64-linux.so `_install_prefix`/lib
		shift;;
		
'berkeley-db')
tn='db-6.2.32'; url='http://download.oracle.com/berkeley-db/db-6.2.32.tar.gz';
set_source 'tar';
if [ $only_dw == 1 ];then return;fi
cust_conf_path='dist/';configure_build --enable-shared --enable-cxx --enable-tcl --enable-dbm --prefix=`_install_prefix`; # --enable-java --enable-smallbuild
do_make;do_make install;do_make all; 
		shift;;

'libgpg-error')
tn='libgpg-error-1.27'; url='ftp://ftp.gnupg.org/gcrypt/libgpg-error/libgpg-error-1.27.tar.gz';
set_source 'tar';
if [ $only_dw == 1 ];then return;fi
configure_build  --enable-threads=posix --prefix=`_install_prefix`; 
do_make;do_make install-strip;do_make install;do_make all;
		shift;;	
		
'libgcrypt')
tn='libgcrypt-1.8.2'; url='ftp://ftp.gnupg.org/gcrypt/libgcrypt/libgcrypt-1.8.2.tar.gz';
set_source 'tar';
if [ $only_dw == 1 ];then return;fi
configure_build --enable-m-guard --enable-hmac-binary-check --prefix=`_install_prefix`; 
do_make;do_make install-strip;do_make install;do_make all; #libcap =  --with-capabilities ,
		shift;;	

'libssh')
tn='libssh-0.7.5'; url='http://red.libssh.org/attachments/download/218/libssh-0.7.5.tar.xz';
set_source 'tar';
if [ $only_dw == 1 ];then return;fi
cmake_build -DWITH_GSSAPI=ON -DWITH_LIBZ=ON -DWITH_SSH1=ON -DWITH_GCRYPT=ON -DCMAKE_INSTALL_PREFIX=`_install_prefix`;
do_make;do_make install;do_make all; 
		shift;;	

'cryptopp')
tn='cryptopp-CRYPTOPP_6_0_0'; url='http://github.com/weidai11/cryptopp/archive/CRYPTOPP_6_0_0.tar.gz';
set_source 'tar';
if [ $only_dw == 1 ];then return;fi
cmake_build -DCMAKE_INSTALL_PREFIX=`_install_prefix`;
do_make;do_make install;do_make all; 
		shift;;	

'cronolog')
tn='cronolog-1.7.1'; url='http://github.com/holdenk/cronolog/archive/1.7.1.tar.gz';
set_source 'tar';
if [ $only_dw == 1 ];then return;fi
configure_build --prefix=`_install_prefix`; 
do_make;do_make lib;do_make install-strip;do_make install;do_make all;
		shift;;	
		
'libuv')
tn='libuv-1.19.1'; url='http://github.com/libuv/libuv/archive/v1.19.1.tar.gz';
set_source 'tar';
if [ $only_dw == 1 ];then return;fi
autogen_build;configure_build --prefix=`_install_prefix`; 
do_make;do_make install-strip;do_make install;do_make all; 
		shift;;	

'libcares')
tn='c-ares-1.12.0'; url='http://c-ares.haxx.se/download/c-ares-1.12.0.tar.gz';
set_source 'tar';
if [ $only_dw == 1 ];then return;fi
configure_build  --enable-libgcc --enable-nonblocking --prefix=`_install_prefix`; 
do_make;do_make install-strip;do_make install;do_make all;
		shift;;	
		
'sqlite')
tn='sqlite'; url='http://www.sqlite.org/src/tarball/sqlite.tar.gz';
set_source 'tar';
if [ $only_dw == 1 ];then return;fi
configure_build --enable-releasemode --enable-editline --enable-gcov --enable-session --enable-rtree  --enable-json1 --enable-fts5 --enable-fts4 --enable-fts3 --enable-memsys3 --enable-memsys5 --prefix=`_install_prefix`; 
do_make;do_make install;do_make all; 
		shift;;	
		
'libjpeg')
tn='jpeg-9c'; url='http://www.ijg.org/files/jpegsrc.v9c.tar.gz';
set_source 'tar';
if [ $only_dw == 1 ];then return;fi
configure_build --prefix=`_install_prefix`;
do_make;do_make install-strip;do_make install;do_make all;
		shift;;	

'imagemagick')
tn='ImageMagick-6.7.7-10'; url='http://www.imagemagick.org/download/releases/ImageMagick-6.7.7-10.tar.xz'; #http://github.com/dahlia/wand/blob/f97277be6d268038a869e59b0d6c3780d7be5664/wand/version.py
set_source 'tar';
if [ $only_dw == 1 ];then return;fi
configure_build --enable-shared --with-jpeg=yes --with-quantum-depth=16 --enable-hdri --enable-pipes --enable-hugepages --disable-docs --with-aix-soname=both --with-modules --with-jemalloc --with-umem --prefix=`_install_prefix`; 
do_make;do_make install-strip;do_make install;do_make all;
		shift;;	
		
'freetype')
tn='freetype-2.9'; url='http://download.savannah.gnu.org/releases/freetype/freetype-2.9.tar.gz';
set_source 'tar';
if [ $only_dw == 1 ];then return;fi
if [ -z $1 ]; then opt='--with-harfbuzz=no'; else opt=$1;fi 
configure_build --enable-fast-install=no $opt --prefix=`_install_prefix`; 
do_make;do_make install;do_make all;
		shift;;	
			
'harfbuzz')
tn='harfbuzz-1.7.5'; url='http://www.freedesktop.org/software/harfbuzz/release/harfbuzz-1.7.5.tar.bz2';
set_source 'tar';
if [ $only_dw == 1 ];then return;fi
if [ -z $1 ]; then opt='--with-freetype=yes --with-fontconfig=no'; else opt=${@:1};fi 
configure_build $opt --prefix=`_install_prefix`; 
do_make;do_make install;do_make all;
sn='freetype'; _do_build --with-harfbuzz=yes; sn='harfbuzz';
		shift;;	

'itstool')
tn='itstool-2.0.4'; url='http://files.itstool.org/itstool/itstool-2.0.4.tar.bz2';
set_source 'tar';
if [ $only_dw == 1 ];then return;fi
configure_build --prefix=`_install_prefix`; 
do_make;do_make install;do_make all;
		shift;;	
	
	
'fontconfig')
tn='fontconfig-2.12.6'; url='http://www.freedesktop.org/software/fontconfig/release/fontconfig-2.12.6.tar.bz2';
set_source 'tar';
if [ $only_dw == 1 ];then return;fi
configure_build --with-default-fonts=`_install_prefix`/share/fonts/ --enable-iconv --prefix=`_install_prefix`; 
do_make;do_make install-strip;do_make install;do_make all;
sn='harfbuzz';_do_build --with-fontconfig=yes --with-freetype=yes;sn='fontconfig';
fc-cache -f;
		shift;;		
	
'fonts')
font_dir=`_install_prefix`/share/fonts/;
mkdir -p $font_dir;
sn='freefont-ttf';tn='freefont-20120503'; url='http://ftp.gnu.org/gnu/freefont/freefont-ttf-20120503.zip';
set_source 'zip';cp *.ttf $font_dir;
sn='freefont-woff';tn='freefont-20120503'; url='http://ftp.gnu.org/gnu/freefont/freefont-woff-20120503.zip';
set_source 'zip';cp *.woff $font_dir;

sn='unifont_upper';download 'http://unifoundry.com/pub/unifont-10.0.07/font-builds/unifont_upper-10.0.07.ttf';cp $DOWNLOAD_PATH/$sn/$sn.ext $font_dir$sn.ttf
sn='unifont_csur';download 'http://unifoundry.com/pub/unifont-10.0.07/font-builds/unifont_csur-10.0.07.ttf';cp  $DOWNLOAD_PATH/$sn/$sn.ext $font_dir$sn.ttf
sn='unifont';download 'http://unifoundry.com/pub/unifont-10.0.07/font-builds/unifont-10.0.07.ttf';cp  $DOWNLOAD_PATH/$sn/$sn.ext $font_dir$sn.ttf
		shift;;		
	
'sparsehash')
tn='sparsehash-sparsehash-2.0.3'; url='http://github.com/sparsehash/sparsehash/archive/sparsehash-2.0.3.tar.gz';
set_source 'tar';
if [ $only_dw == 1 ];then return;fi
configure_build --prefix=`_install_prefix`;   # --enable-namespace=gpreftools
do_make;do_make install-strip;do_make install;do_make all; 	
		shift;;	
		

'openjdk')	
tn='jdk-9.0.4'; url='http://download.java.net/java/GA/jdk9/9.0.4/binaries/openjdk-9.0.4_linux-x64_bin.tar.gz';
set_source 'tar';
if [ $only_dw == 1 ];then return;fi
rm -r  $CUST_JAVA_INST_PREFIX/$sn
mv ../$sn $CUST_JAVA_INST_PREFIX/;

if [ -f $CUST_JAVA_INST_PREFIX/$sn/bin/javac ] &&  [ -f $CUST_JAVA_INST_PREFIX/$sn/bin/java ]; then # &&  [ -f $CUST_JAVA_INST_PREFIX/$sn/jre/bin/java ]
	echo "#\!/usr/bin/env bash" > $ENV_SETTINGS_PATH/$sn.sh
	echo "export JAVA_HOME=\"$CUST_JAVA_INST_PREFIX/$sn\"" >> $ENV_SETTINGS_PATH/$sn.sh
	echo "export PATH=\$PATH:\"$CUST_JAVA_INST_PREFIX/$sn/bin\"" >> $ENV_SETTINGS_PATH/$sn.sh
	echo -e $CUST_JAVA_INST_PREFIX/$sn/lib/server/ > $LD_CONF_PATH/$sn.conf;
fi
		shift;;	
		
'apache-ant')
tn='apache-ant-1.10.2'; url='http://www.apache.org/dist/ant/source/apache-ant-1.10.2-src.tar.xz';
set_source 'tar';
if [ $only_dw == 1 ];then return;fi
./build.sh install-lite -Ddist.dir=$CUST_JAVA_INST_PREFIX/$sn -Dant.install=$CUST_JAVA_INST_PREFIX/$sn
echo "#!/usr/bin/env bash" > $ENV_SETTINGS_PATH/$sn.sh
echo "export ANT_HOME=\"$CUST_JAVA_INST_PREFIX/$sn\"" >> $ENV_SETTINGS_PATH/$sn.sh
		shift;;	

'apache-maven')	
tn='apache-maven-3.5.2'; url='http://apache.mediamirrors.org/maven/maven-3/3.5.2/binaries/apache-maven-3.5.2-bin.tar.gz';
set_source 'tar';
if [ $only_dw == 1 ];then return;fi
rm -r  $CUST_JAVA_INST_PREFIX/$sn
mv ../$sn $CUST_JAVA_INST_PREFIX/;
if [ -f $CUST_JAVA_INST_PREFIX/$sn/bin/mvn ]; then
	echo "#!/usr/bin/env bash" > $ENV_SETTINGS_PATH/$sn.sh
	echo "export MAVEN_HOME=\"$CUST_JAVA_INST_PREFIX/$sn\"" >> $ENV_SETTINGS_PATH/$sn.sh
	echo "export PATH=\$PATH:\"$CUST_JAVA_INST_PREFIX/$sn/bin\"" >> $ENV_SETTINGS_PATH/$sn.sh

fi
		shift;;	
		
'thrift')
tn='thrift-0.10.0'; url='http://archive.apache.org/dist/thrift/0.10.0/thrift-0.10.0.tar.gz';
set_source 'tar';
if [ $only_dw == 1 ];then return;fi
sed -i 's/1.5/1.6/g' lib/java/build.xml;
./bootstrap.sh; 
cmake_build -DUSE_STD_THREAD=1 -DWITH_STDTHREADS=ON -DTHRIFT_COMPILER_HS=ON;
do_make;do_make install;do_make all;
cd $BUILDS_PATH/$sn/lib/py/;
python setup.py install;
pypy setup.py install;
		shift;;	
		
'attr')
tn='attr-2.4.48'; url='http://git.savannah.nongnu.org/cgit/attr.git/snapshot/attr-2.4.48.tar.gz';
set_source 'tar';
if [ $only_dw == 1 ];then return;fi
autogen_build;configure_build --enable-gettext=yes --enable-shared=yes --prefix=`_install_prefix`;
do_make;do_make install;
		shift;;	

'libjansson')
tn='jansson-2.10'; url='http://www.digip.org/jansson/releases/jansson-2.10.tar.gz';
set_source 'tar';
if [ $only_dw == 1 ];then return;fi
configure_build --prefix=`_install_prefix`;
do_make install;	
		shift;;
	
'gmock')
tn='googletest-release-1.8.0'; url='http://github.com/google/googletest/archive/release-1.8.0.tar.gz';
set_source 'tar';
if [ $only_dw == 1 ];then return;fi
cmake_build -DCMAKE_INSTALL_PREFIX=`_install_prefix`;
do_make;do_make install;
		shift;;	
		
'curl')
tn='curl-curl-7_58_0'; url='http://github.com/curl/curl/archive/curl-7_58_0.tar.gz';
set_source 'tar';
if [ $only_dw == 1 ];then return;fi
cmake_build -DCMAKE_INSTALL_PREFIX=`_install_prefix`;
do_make;do_make install;
		shift;;	
'wget')
tn='wget-1.19.4'; url='http://ftp.gnu.org/gnu/wget/wget-1.19.4.tar.gz';
set_source 'tar';
if [ $only_dw == 1 ];then return;fi
configure_build --prefix=`_install_prefix`;
do_make install;	
		shift;;	
		
'protobuf')
tn='protobuf-3.5.1'; url='http://github.com/google/protobuf/archive/v3.5.1.tar.gz';
set_source 'tar';
if [ $only_dw == 1 ];then return;fi
cp -r ../$sn ../$sn-tmp; mv ../$sn-tmp gtest;
autogen_build;configure_build --with-zlib --prefix=`_install_prefix`;
do_make;do_make install;
		shift;;	
			
'apache-hadoop')
tn='hadoop-2.7.5'; url='http://apache.crihan.fr/dist/hadoop/common/hadoop-2.7.5/hadoop-2.7.5.tar.gz';
set_source 'tar';
if [ $only_dw == 1 ];then return;fi
if [ -d $CUST_JAVA_INST_PREFIX/$sn ]; then rm -r $CUST_JAVA_INST_PREFIX/$sn;fi;
mv ../$sn $CUST_JAVA_INST_PREFIX/$sn;
if [ ! -d /etc/opt/hadoop ]; then
	mkdir -p /etc/opt; mv $CUST_JAVA_INST_PREFIX/$sn/etc/hadoop /etc/opt/;chmod -R 777 /etc/opt/hadoop;
fi
rm -r $CUST_JAVA_INST_PREFIX/$sn/etc/hadoop;ln -s /etc/opt/hadoop $CUST_JAVA_INST_PREFIX/$sn/etc/hadoop;

echo "#!/usr/bin/env bash" > $ENV_SETTINGS_PATH/$sn.sh
echo "export HADOOP_HOME=\"$CUST_JAVA_INST_PREFIX/$sn\"" >> $ENV_SETTINGS_PATH/$sn.sh
echo "export HADOOP_CONF_DIR=\"$CUST_JAVA_INST_PREFIX/$sn/etc/hadoop\"" >> $ENV_SETTINGS_PATH/$sn.sh
echo "export HADOOP_VERSION=\"2.7.5\"" >> $ENV_SETTINGS_PATH/$sn.sh
echo "export HADOOP_INCLUDE_PATH=\"$CUST_JAVA_INST_PREFIX/$sn/include\"" >> $ENV_SETTINGS_PATH/$sn.sh
echo "export HADOOP_LIB_PATH=\"$CUST_JAVA_INST_PREFIX/$sn/lib\"" >> $ENV_SETTINGS_PATH/$sn.sh
echo "export PATH=\$PATH:\"$CUST_JAVA_INST_PREFIX/$sn/bin\"" >> $ENV_SETTINGS_PATH/$sn.sh
orig_IFS=$IFS;subs=('common common/lib hdfs hdfs/lib tools/lib');CLASSPATH='';for n in $subs;do CLASSPATH=$(JARS=($CUST_JAVA_INST_PREFIX/$sn/share/hadoop/$n/*.jar); IFS=:; echo "${JARS[*]}"):$CLASSPATH;done;IFS=$orig_IFS;
echo "export CLASSPATH=$CLASSPATH" >> $ENV_SETTINGS_PATH/$sn.sh
echo -e $CUST_JAVA_INST_PREFIX/$sn/lib/native/ > $LD_CONF_PATH/$sn.conf;
		shift;;	
		
'apache-zookeeper')
tn='zookeeper-3.4.10'; url='http://apache.mirrors.ovh.net/ftp.apache.org/dist/zookeeper/zookeeper-3.4.10/zookeeper-3.4.10.tar.gz';
set_source 'tar';
if [ $only_dw == 1 ];then return;fi
if [ -d $CUST_JAVA_INST_PREFIX/$sn ]; then rm -r $CUST_JAVA_INST_PREFIX/$sn;fi;
mv ../$sn $CUST_JAVA_INST_PREFIX/$sn;
if [ ! -d /etc/opt/zookeeper ]; then
	mkdir -p /etc/opt; mv $CUST_JAVA_INST_PREFIX/$sn/conf /etc/opt/zookeeper;chmod -R 777 /etc/opt/zookeeper;
fi
rm -r $CUST_JAVA_INST_PREFIX/$sn/conf;ln -s /etc/opt/zookeeper $CUST_JAVA_INST_PREFIX/$sn/conf;
		shift;;	
		
'nodejs')
tn='node-v9.5.0'; url='http://nodejs.org/dist/latest-v9.x/node-v9.5.0.tar.gz';
set_source 'tar';
if [ $only_dw == 1 ];then return;fi
./configure --no-cross-compiling --prefix=`_install_prefix`; #--with-intl=none 
do_make;do_make install;
		shift;;	

'libhoard')
tn='Hoard'; url='http://github.com/emeryberger/Hoard/releases/download/3.10/Hoard-3.10-source.tar.gz';
set_source 'tar';
if [ $only_dw == 1 ];then return;fi
cd src;
make linux-gcc-x86-64;mv libhoard.so $CUST_INST_PREFIX/lib/;
		shift;;	
 	
'libzip')
tn='libzip-1.4.0'; url='http://libzip.org/download/libzip-1.4.0.tar.xz';
set_source 'tar';
if [ $only_dw == 1 ];then return;fi
cmake_build -DCMAKE_INSTALL_PREFIX=`_install_prefix`;
do_make;do_make install;	
		shift;;

'unzip')
tn='unzip60'; url='http://sourceforge.net/projects/infozip/files/UnZip%206.x%20%28latest%29/UnZip%206.0/unzip60.tar.gz/download';
set_source 'tar';
if [ $only_dw == 1 ];then return;fi
make -f unix/Makefile generic
make prefix=`_install_prefix` MANDIR=$CUST_INST_PREFIX/share/man/man1 -f unix/Makefile install
		shift;;

'gawk')
tn='gawk-4.2.0'; url='http://ftp.gnu.org/gnu/gawk/gawk-4.2.0.tar.xz';
set_source 'tar';
if [ $only_dw == 1 ];then return;fi
configure_build --prefix=`_install_prefix`;
do_make;do_make install;	
		shift;;

'pybind11')
tn='pybind11-2.2.1'; url='http://github.com/pybind/pybind11/archive/v2.2.1.tar.gz';
set_source 'tar';
if [ $only_dw == 1 ];then return;fi
cmake_build -DPYBIND11_TEST=OFF -DCMAKE_INSTALL_INCLUDEDIR=`_install_prefix`/include;
do_make install;
		shift;;

'hypertable')
tn='hypertable-master'; url='http://github.com/kashirin-alex/hypertable/archive/master.zip';
rm -r $DOWNLOAD_PATH/$sn/$fn
set_source 'zip';
if [ $only_dw == 1 ];then return;fi
echo '' > /root/builds/sources/hypertable/src/rb/ThriftClient/hypertable/gen-rb/hql_types.rb;
cmake_build -DBUILD_SHARED_LIBS=ON -DUSE_JEMALLOC=ON -DHADOOP_INCLUDE_PATH=$HADOOP_INCLUDE_PATH -DHADOOP_LIB_PATH=$HADOOP_LIB_PATH -DTHRIFT_SOURCE_DIR=$BUILDS_PATH/thrift -DCMAKE_INSTALL_PREFIX=/opt/hypertable -DCMAKE_BUILD_TYPE=Release;
do_make;do_make install;#make alltests;#  -DPACKAGE_OS_SPECIFIC=1  -DVERSION_MISC_SUFFIX=$( date  +"%Y-%m-%d_%H-%M")
		shift;;

'llvm')
tn='llvm-5.0.1.src'; url='http://releases.llvm.org/5.0.1/llvm-5.0.1.src.tar.xz';
set_source 'tar';
if [ $only_dw == 1 ];then return;fi
cmake_build -DCMAKE_BUILD_TYPE=Release -DLLVM_TARGETS_TO_BUILD=X86 -DFFI_INCLUDE_DIR=`_install_prefix`/lib/libffi-3.2.1/include -DLLVM_ENABLE_FFI=ON -DLLVM_USE_INTEL_JITEVENTS=ON -DLLVM_LINK_LLVM_DYLIB=ON -DCMAKE_INSTALL_PREFIX=`_install_prefix`; 
do_make;do_make install;
		shift;;

'libconfuse')
tn='confuse-3.2.1'; url='http://github.com/martinh/libconfuse/releases/download/v3.2.1/confuse-3.2.1.tar.xz';
set_source 'tar';
if [ $only_dw == 1 ];then return;fi
configure_build --prefix=`_install_prefix`;
do_make;do_make install;	
		shift;;

'apr')
tn='apr-1.6.3'; url='http://apache.mindstudios.com/apr/apr-1.6.3.tar.gz';
set_source 'tar';
if [ $only_dw == 1 ];then return;fi
configure_build --enable-threads --enable-posix-shm --prefix=`_install_prefix`;
do_make;do_make install;	
		shift;;
		
'apr-util')
tn='apr-util-1.6.1'; url='http://apache.mindstudios.com/apr/apr-util-1.6.1.tar.gz';
set_source 'tar';
if [ $only_dw == 1 ];then return;fi
configure_build --with-crypto=`_install_prefix` --with-openssl=`_install_prefix`  --with-apr=`_install_prefix` --prefix=`_install_prefix`;
do_make;do_make install;	
		shift;;

'libsigcplusplus')
tn='libsigcplusplus-2.99.10'; url='http://github.com/GNOME/libsigcplusplus/archive/2.99.10.tar.gz';
set_source 'tar';
if [ $only_dw == 1 ];then return;fi
cmake_build -DCMAKE_INSTALL_PREFIX=`_install_prefix`;
do_make;do_make install;	
		shift;;

'pixman')
tn='pixman-0.34.0'; url='http://www.cairographics.org/releases/pixman-0.34.0.tar.gz';
set_source 'tar';
if [ $only_dw == 1 ];then return;fi
configure_build --enable-timers --prefix=`_install_prefix`;
do_make;do_make install;	
		shift;;

'cairo')
tn='cairo-1.14.12'; url='http://www.cairographics.org/releases/cairo-1.14.12.tar.xz';
set_source 'tar';
if [ $only_dw == 1 ];then return;fi
configure_build --enable-pdf=yes --enable-svg=yes --enable-tee=yes --enable-fc=yes --enable-ft=yes --enable-xml=yes --enable-pthread=yes --prefix=`_install_prefix`;
do_make;do_make install;	
		shift;;

'cairomm')
tn='cairomm-1.15.5'; url='http://www.cairographics.org/releases/cairomm-1.15.5.tar.gz';
set_source 'tar';
if [ $only_dw == 1 ];then return;fi
configure_build  --prefix=`_install_prefix`;
do_make;do_make install;	
		shift;;
	
'gobject-ispec')
tn='gobject-introspection-1.55.1'; url='http://ftp.acc.umu.se/pub/gnome/sources/gobject-introspection/1.55/gobject-introspection-1.55.1.tar.xz';
set_source 'tar';
if [ $only_dw == 1 ];then return;fi
configure_build  --prefix=`_install_prefix`;
do_make;do_make install;	
		shift;;	
		
'pango')
tn='pango-1.41.0'; url='http://ftp.acc.umu.se/pub/GNOME/sources/pango/1.41/pango-1.41.0.tar.xz';
set_source 'tar';
if [ $only_dw == 1 ];then return;fi
configure_build --prefix=`_install_prefix`;
do_make;do_make install;	
		shift;;	

'rrdtool')
tn='rrdtool-1.7.0'; url='http://github.com/oetiker/rrdtool-1.x/releases/download/v1.7.0/rrdtool-1.7.0.tar.gz';
set_source 'tar';
if [ $only_dw == 1 ];then return;fi
./configure --disable-python --disable-tcl --disable-perl --disable-ruby --disable-lua --disable-docs --disable-examples --build=`_build` --prefix=`_install_prefix`;
do_make;do_make install;	
		shift;;	
		
'ganglia')
tn='ganglia-3.7.2'; url='http://sourceforge.net/projects/ganglia/files/ganglia%20monitoring%20core/3.7.2/ganglia-3.7.2.tar.gz/download';
set_source 'tar';
if [ $only_dw == 1 ];then return;fi
./configure --with-gmetad --enable-status --enable-shared --enable-static --enable-python --disable-perl --build=`_build` --prefix=`_install_prefix`;
do_make;do_make install;
		shift;;	
		
'pkg-config')
tn='pkg-config-0.29.2'; url='http://pkg-config.freedesktop.org/releases/pkg-config-0.29.2.tar.gz';
set_source 'tar';
if [ $only_dw == 1 ];then return;fi
configure_build --prefix=`_install_prefix`;
do_make;do_make install;
		shift;;	
		
'gdb')
tn='gdb-8.1'; url='http://ftp.gnu.org/gnu/gdb/gdb-8.1.tar.xz';
set_source 'tar';
if [ $only_dw == 1 ];then return;fi
configure_build --prefix=`_install_prefix`;
do_make;do_make install;
		shift;;	

'kerberos')
tn='krb5-1.16'; url='http://web.mit.edu/kerberos/dist/krb5/1.16/krb5-1.16.tar.gz';
set_source 'tar';
if [ $only_dw == 1 ];then return;fi
cust_conf_path='src/';configure_build  --disable-dns-for-realm --disable-athena --without-ldap --disable-asan --prefix=`_install_prefix`;
do_make;do_make install;
		shift;;

'clang')
tn='cfe-5.0.1.src'; url='http://releases.llvm.org/5.0.1/cfe-5.0.1.src.tar.xz';
set_source 'tar';
if [ $only_dw == 1 ];then return;fi
cmake_build -DCMAKE_INSTALL_PREFIX=`_install_prefix`;
do_make;do_make install;	
		shift;;
 
'php')
tn='php-7.2.2'; url='http://mirror.cogentco.com/pub/php/php-7.2.2.tar.xz';
set_source 'tar';
if [ $only_dw == 1 ];then return;fi
configure_build --enable-shared --enable-json --prefix=`_install_prefix`/$sn; #--enable-all
do_make;do_make install;	
echo -e `_install_prefix`/$sn/lib > $LD_CONF_PATH/$sn.conf;
echo "#!/usr/bin/env bash" > $ENV_SETTINGS_PATH/$sn.sh
echo "export PATH=\$PATH:\"`_install_prefix`/$sn/bin\"" >> $ENV_SETTINGS_PATH/$sn.sh
		shift;;
 
'ganglia-web')
tn='ganglia-web-3.7.2'; url='http://sourceforge.net/projects/ganglia/files/ganglia-web/3.7.2/ganglia-web-3.7.2.tar.gz/download';
set_source 'tar';
if [ $only_dw == 1 ];then return;fi
echo "\$conf['rrdtool'] = \"rrdtool\";" >> conf_default.php;
if [ -d /usr/share/ganglia-webfrontend ]; then rm -r /usr/share/ganglia-webfrontend; fi;
do_make install; #/usr/share/ganglia-webfrontend
		shift;;
		
'libmnl')
tn='libmnl-1.0.4'; url='http://www.netfilter.org/projects/libmnl/files/libmnl-1.0.4.tar.bz2';
set_source 'tar';
if [ $only_dw == 1 ];then return;fi
configure_build --enable-static --enable-shared --prefix=`_install_prefix`;
do_make;do_make install;	
		shift;;
		
'libnftnl')
tn='libnftnl-1.0.9'; url='http://www.netfilter.org/projects/libnftnl/files/libnftnl-1.0.9.tar.bz2';
set_source 'tar';
if [ $only_dw == 1 ];then return;fi
configure_build --enable-static --enable-shared --prefix=`_install_prefix`;
do_make;do_make install;	
		shift;;
		
'nftables')
tn='nftables-0.8.1'; url='http://www.netfilter.org/projects/nftables/files/nftables-0.8.1.tar.bz2';
set_source 'tar';
if [ $only_dw == 1 ];then return;fi
apt-get autoremove --purge -y iptables
configure_build --prefix=`_install_prefix`;
do_make;do_make install;	
		shift;;
	
'pth')
tn='pth-2.0.7'; url='http://ftp.gnu.org/gnu/pth/pth-2.0.7.tar.gz';
set_source 'tar';
if [ $only_dw == 1 ];then return;fi
configure_build --enable-m-guard --enable-hmac-binary-check --prefix=`_install_prefix`; 
make;make install;
		shift;;	
	
'libgsasl')
tn='libgsasl-1.8.0'; url='http://ftp.gnu.org/gnu/gsasl/libgsasl-1.8.0.tar.gz';
set_source 'tar';
if [ $only_dw == 1 ];then return;fi
configure_build --prefix=`_install_prefix`; 
do_make;do_make install;
		shift;;	
	
'libhdfs3')
tn='attic-c-hdfs-client-2.2.31'; url='http://github.com/Pivotal-Data-Attic/pivotalrd-libhdfs3/archive/v2.2.31.tar.gz';
set_source 'tar';
if [ $only_dw == 1 ];then return;fi
mkdir $sn-tmp; cd $sn-tmp;
../bootstrap --prefix=`_install_prefix`;
do_make; do_make install;
		shift;;	
		
'glibc')
tn='glibc-2.27'; url='http://ftp.gnu.org/gnu/libc/glibc-2.27.tar.xz';
set_source 'tar'; 
if [ $only_dw == 1 ];then return;fi
wget 'http://ftp.gnu.org/gnu/libc/glibc-linuxthreads-2.5.tar.bz2';tar xf glibc-linuxthreads-2.5.tar.bz2;
configure_build --disable-multi-arch --enable-kernel=4.0.0 --enable-shared --enable-lock-elision=yes --enable-stack-protector=all --enable-tunables --enable-mathvec --with-fp --prefix=`_install_prefix`/glibc --build=`_build`;
do_make; #do_make install;
		shift;;	
		
'bash')
tn='bash-4.4.18'; url='http://ftp.gnu.org/gnu/bash/bash-4.4.18.tar.gz';
set_source 'tar';
if [ $only_dw == 1 ];then return;fi
sed -i 's/ncurses/ncursesw/g' configure;
configure_build --prefix=`_install_prefix`; 
do_make;do_make install;
		shift;;	
'lsof')
tn='lsof_4.89'; url='http://www.mirrorservice.org/sites/lsof.itap.purdue.edu/pub/tools/unix/lsof/lsof_4.89.tar.gz';
set_source 'tar';
if [ $only_dw == 1 ];then return;fi
tar -xf lsof_4.89_src.tar;cd lsof_4.89_src;
./Configure -n linux;
do_make;install -v -m0755 -o root -g root lsof `_install_prefix`/bin;
		shift;;	

'ncurses')
tn='ncurses-6.1'; url='http://ftp.gnu.org/gnu/ncurses/ncurses-6.1.tar.gz';
set_source 'tar';
if [ $only_dw == 1 ];then return;fi
ncurses_args="CPPFLAGS=-P --with-shared --with-termlib --enable-rpath --disable-overwrite --enable-termcap --enable-getcap --enable-ext-colors --enable-ext-mouse --enable-sp-funcs --enable-pc-file --enable-const --enable-sigwinch --enable-hashmap -disable-widec";
if [ $stage -eq 0 ]; then
	configure_build --without-libtool --without-gpm --without-hashed-db $ncurses_args --prefix=`_install_prefix`;
else
	configure_build --with-libtool --without-hashed-db --with-gpm $ncurses_args --prefix=`_install_prefix`;
fi
make;make install;
		shift;;	

'ncursesw')
tn='ncurses-6.1'; url='http://ftp.gnu.org/gnu/ncurses/ncurses-6.1.tar.gz';
set_source 'tar';
if [ $only_dw == 1 ];then return;fi
ncurses_args="CPPFLAGS=-P --with-shared --enable-rpath --enable-overwrite --enable-getcap --enable-ext-colors --enable-ext-mouse --enable-sp-funcs --enable-pc-file --enable-const --enable-sigwinch --enable-hashmap --enable-widec ";
if [ $stage -eq 0 ]; then
	configure_build --without-libtool --without-gpm --without-hashed-db $ncurses_args --prefix=`_install_prefix`;
else
	configure_build --with-libtool --with-hashed-db --with-gpm $ncurses_args --prefix=`_install_prefix`;
fi
make;make install;
		shift;;
		
'ncursestw')
tn='ncurses-6.1'; url='http://ftp.gnu.org/gnu/ncurses/ncurses-6.1.tar.gz';
set_source 'tar';
if [ $only_dw == 1 ];then return;fi
ncurses_args="CPPFLAGS=-P --with-shared --with-termlib --enable-overwrite --enable-pthreads-eintr --enable-reentrant --enable-termcap --enable-getcap --enable-ext-colors --enable-ext-mouse --enable-sp-funcs --enable-pc-file --enable-const --enable-sigwinch --enable-widec --with-pthread";
if [ $stage -eq 0 ]; then
	configure_build --without-libtool --without-gpm --without-hashed-db $ncurses_args --prefix=`_install_prefix`;
else
	configure_build --with-libtool --with-hashed-db --with-gpm $ncurses_args --prefix=`_install_prefix`; # 
fi # --enable-weak-symbols --disable-overwrite
make;make install;
echo "#!/usr/bin/env bash" > $ENV_SETTINGS_PATH/$sn.sh
echo "export CPATH=\$CPATH:\$CUST_INST_PREFIX/include/$sn" >> $ENV_SETTINGS_PATH/$sn.sh
		shift;;	
		
    *)         echo "Unknown build: $sn";       shift;;
  esac
  
}
#########

#########
do_install() {
  for sn in "$@"; do
	if [ $verbose == 1 ]; then
		sleep 1
		do_build;
	else
		do_build &>> $BUILDS_LOG_PATH/$stage-$sn'.log';
	fi
  done
}
#########

#########
compile_and_install(){
	if [ $stage -eq 0 ] || [ $stage -eq 1 ]; then
		do_install make cmake
		do_install byacc
		do_install ncursesw libreadline
		do_install m4 gmp mpfr mpc isl
		do_install autoconf automake libtool gawk
		do_install zlib bzip2 unrar gzip lzo snappy libzip unzip xz p7zip tar
		do_install libatomic_ops libeditline libevent libunwind fuse pth
		do_install openssl libgpg-error libgcrypt kerberos libssh icu4c
		do_install bison texinfo flex binutils gettext nettle libtasn1 libiconv
		do_install libexpat libunistring libidn2 libsodium unbound
		do_install libffi p11-kit gnutls tcltk pcre pcre2  # tk openmpi 
		do_install gdbm expect attr patch #musl
		do_install jemalloc gc gperf gperftools  # libhoard
		do_install glib pkg-config gcc  # glibc
	fi
	if [ $stage -ne 3 ]; then
		do_install coreutils gdb bash lsof curl wget sqlite berkeley-db python boost 
	fi
	if [ $stage -eq 2 ]; then
		do_install libmnl libnftnl nftables
		if [ $build_target == 'all' ];then
			do_install llvm clang 
		fi
		do_install libconfuse apr apr-util libsigcplusplus log4cpp cronolog
		do_install re2 sparsehash 
		do_install libpng libjpeg  
		do_install libjansson libxml2 libxslt libuv libcares
		do_install openjdk apache-ant apache-maven sigar
		do_install gmock protobuf apache-zookeeper apache-hadoop libgsasl libhdfs3
		do_install fonts itstool freetype harfbuzz fontconfig 
		do_install pixman cairo cairomm gobject-ispec pango 
		do_install imagemagick
		
		if [ $build_target == 'monitoring' ] || [ $build_target == 'all' ];then
			do_install php ganglia-web
		fi
	fi
	if [ $stage -eq 3 ]; then
		do_install pypy2 nodejs thrift pybind11
		do_install rrdtool hypertable # pypy2stm # ganglia 
		do_install python3
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
		echo 'os_releases-install: '$os_r
		
		if [ ! -f $CUST_INST_PREFIX/bin/gcc ] && [ ! -f /usr/bin/gcc ]; then
			if [ $os_r == 'Ubuntu' ];then
				front_state=$DEBIAN_FRONTEND;export DEBIAN_FRONTEND=noninteractive;			
				apt-get install -yq --reinstall libblkid-dev libmount-dev uuid-dev;# libncurses-dev libreadline-dev
				echo '' > /var/log/dpkg.log;
				apt-get install -yq --reinstall make pkg-config build-essential gcc 
				export DEBIAN_FRONTEND=$front_state;
				
			elif [ $os_r == 'openSUSE' ]; then
				zypper rm -y tar make gcc cpp g++ c++;
				zypper install -y libblkid-devel libmount-devel libuuid-devel #  ncurses-devel  readline-devel
				zypper install -y tar pkg-config make gcc cpp gcc-c++; #zypper info -t pattern devel_basis
				rm /usr/share/site/x86_64-unknown-linux-gnu; 
			fi
		fi
		echo 'fin:os_releases-install: '$os_r
		
	elif [ $1 == 'uninstall' ]; then
		echo 'os_releases-uninstall: '$os_r
		
		if [ -f $CUST_INST_PREFIX/bin/make ] && [ -f $CUST_INST_PREFIX/bin/gcc ]; then
			if [ $os_r == 'Ubuntu' ]; then
				front_state=$DEBIAN_FRONTEND;export DEBIAN_FRONTEND=noninteractive;
				echo 'pkgs to remove';
				apt-get autoremove -yq --purge $(zgrep -h ' install ' /var/log/dpkg.log* | sort | awk '{print $4}');
				export DEBIAN_FRONTEND=$front_state;
				
			elif [ $os_r == 'openSUSE' ]; then
				zypper rm -y xz xz-lang tar tar-lang openssl ca-certificates python python-base make gcc cpp gcc-c++ binutils cpp48 gcc48 gcc48-c++ gcc-c++ libasan0 libatomic1 libcloog-isl4 libgomp1 libisl10 libitm1 libmpc3 libmpfr4 libstdc++48-devel libtsan0 site-config;
				# linux-glibc-devel glibc-devel pkg-config 
			fi;
	    else
			exit 1; 
		fi;
		echo 'fin:os_releases-uninstall: '$os_r
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
		if [ ! -d $CUST_INST_PREFIX/lib64 ]; then
			mkdir -p $CUST_INST_PREFIX/lib;ln -s  $CUST_INST_PREFIX/lib $CUST_INST_PREFIX/lib64;
		fi
		if [[ $os_r == 'openSUSE' ]];then
			if [[ $(cat /etc/profile) != *"#EDITTED ETC/PROFILE"* ]]; then
				echo 'if [ -d /etc/profile.d ]; then for i in /etc/profile.d/*.sh; do if [ -r $i ]; then . $i;fi;done;unset i;fi; #EDITTED ETC/PROFILE'  >> "/etc/profile";
			fi
		fi

		echo include $LD_CONF_PATH/*.conf > "/etc/ld.so.conf.d/usr.conf"
		
		echo '''source /etc/environment; CPATH=''; if [ -d '''$ENV_SETTINGS_PATH''' ]; then  for i in '''$ENV_SETTINGS_PATH'''*.sh; do    if [ -r $i ]; then       source $i;     fi;   done; unset i; fi; ''' > /etc/profile.d/custom_env.sh;
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
_run_setup(){
	if [ $stage == 0 ]; then
		env_setup pre
		reuse_make=0
		os_releases install;
		compile_and_install;
		os_releases uninstall;
		stage=1		
		compile_and_install;
		stage=2
	fi
	if [ $stage == 2 ]; then
		reuse_make=0;
		compile_and_install
		stage=3
	fi
	if [ $stage == 3 ]; then
		reuse_make=0
		compile_and_install
		env_setup post
	fi
}
#########

#########
if [  ${#only_sources[@]} -gt 0  ]; then 
	source /etc/profile
	source ~/.bashrc
	do_install ${only_sources[@]}
	exit 1
fi
#########

if [ $only_dw == 1 ];then 
	stage=0;compile_and_install;
	stage=1;compile_and_install;
	stage=2;compile_and_install;
	stage=3;compile_and_install;
else
	_run_setup
fi




exit 1

# DRAFTS #######################################################################
 

TMP_NAME=libcap-ng
echo $TMP_NAME
mkdir ~/tmpBuilds
cd ~/tmpBuilds; rm -r $TMP_NAME;
wget 'http://github.com/stevegrubb/libcap-ng/archive/v0.7.8.tar.gz'
tar xf v0.7.8.tar.gz
mv libcap-ng-0.7.8 $TMP_NAME;cd $TMP_NAME;
./autogen.sh;./configure --prefix=/usr/local; 
make; make install;

TMP_NAME=util-linux
echo $TMP_NAME
mkdir ~/tmpBuilds
cd ~/tmpBuilds; rm -r $TMP_NAME;
wget 'https://www.kernel.org/pub/linux/utils/util-linux/v2.31/util-linux-2.31.tar.xz'
tar xf util-linux-2.31.tar.xz
mv util-linux-2.31 $TMP_NAME;cd $TMP_NAME
./configure --prefix=/usr/local; 
make; make install;


TMP_NAME=openssh
echo $TMP_NAME
mkdir ~/tmpBuilds
cd ~/tmpBuilds; rm -r $TMP_NAME;
wget 'http://ftp.halifax.rwth-aachen.de/openbsd/OpenSSH/portable/openssh-7.5p1.tar.gz'
tar xf openssh-7.5p1.tar.gz
mv openssh-7.5p1 $TMP_NAME;cd $TMP_NAME
./configure --with-ssh1 --with-kerberos5 --with-pam --with-ssl-engine --with-pie --prefix=/usr/local; 
make; make install;



TMP_NAME=apache-arrow; 
echo $TMP_NAME
mkdir ~/tmpBuilds
cd ~/tmpBuilds; rm -r $TMP_NAME;
wget 'https://github.com/apache/arrow/archive/apache-arrow-0.7.1.tar.gz'
tar xf apache-arrow-0.7.1.tar.gz
mv arrow-apache-arrow-0.7.1 $TMP_NAME; cd $TMP_NAME;
mkdir $TMP_NAME'_build'; cd $TMP_NAME'_build';
cmake ../cpp -DARROW_BUILD_TESTS=OFF -DARROW_PYTHON=on -DARROW_PLASMA=off -DPYTHON_LIBRARY=/opt/pypy2/bin/libpypy-c.so -DCMAKE_INSTALL_PREFIX=/usr/local; 
make; make install;
cmake ../python -DPYTHON_LIBRARY=/opt/pypy2/bin/libpypy-c.so -DCMAKE_INSTALL_PREFIX=/usr/local; 
cd ../python;
pypy setup.py build_ext --with-plasma --inplace  -DPYTHON_LIBRARY=/opt/pypy2/bin/libpypy-c.so 
 
 
 
TMP_NAME=apache-httpd
echo $TMP_NAME
mkdir ~/tmpBuilds
cd ~/tmpBuilds; rm -r $TMP_NAME;
wget 'http://mirrors.ircam.fr/pub/apache//httpd/httpd-2.2.32.tar.gz'
tar xf httpd-2.2.32.tar.gz
mv httpd-2.2.32 $TMP_NAME;cd $TMP_NAME
./configure --prefix=/usr/local; 
make; make install;
 
http://httpd.apache.org/[preferred]/httpd/mod_fcgid/mod_fcgid-2.3.9.tar.gz

http://cache.ruby-lang.org/pub/ruby/2.4/ruby-2.4.1.tar.gz
http://github.com/macournoyer/thin/archive/v1.7.0.tar.gz

TMP_NAME=proxygen; 
echo $TMP_NAME
mkdir ~/tmpBuilds
cd ~/tmpBuilds; rm -r $TMP_NAME;
rm master.zip;
wget 'http://github.com/facebook/proxygen/archive/v2017.05.22.00.tar.gz'
tar xf v2017.05.22.00.tar.gz
mv proxygen-2017.05.22.00 $TMP_NAME; cd $TMP_NAME;







TMP_NAME=greeny; 
echo $TMP_NAME
mkdir ~/tmpBuilds
cd ~/tmpBuilds; rm -r $TMP_NAME;
rm master.zip;
wget 'http://github.com/nifigase/greeny/archive/master.zip'
/usr/local/bin/unzip master.zip
mv greeny-master $TMP_NAME; cd $TMP_NAME;



TMP_NAME=poco
echo $TMP_NAME
mkdir ~/tmpBuilds
cd ~/tmpBuilds; rm -r $TMP_NAME;
wget 'http://pocoproject.org/releases/poco-1.7.8/poco-1.7.8p2.tar.gz'
tar xf poco-1.7.8p2.tar.gz
mv  poco-1.7.8p2 $TMP_NAME;cd $TMP_NAME
./configure --shared --unbundled --everything --config=Linux --prefix=/usr/local; 
make; make install;



TMP_NAME=libev
echo $TMP_NAME
mkdir ~/tmpBuilds
cd ~/tmpBuilds; rm -r $TMP_NAME;
wget 'http://dist.schmorp.de/libev/libev-4.24.tar.gz'
tar xf libev-4.24.tar.gz
mv libev-4.24 $TMP_NAME;cd $TMP_NAME
./configure --prefix=/usr/local/libev; 
make; make install;


TMP_NAME=nghttp2
echo $TMP_NAME
mkdir ~/tmpBuilds
cd ~/tmpBuilds; rm -r $TMP_NAME;
wget 'http://github.com/nghttp2/nghttp2/releases/download/v1.23.1/nghttp2-1.23.1.tar.xz'
tar xf nghttp2-1.23.1.tar.xz
mv nghttp2-1.23.1 $TMP_NAME;cd $TMP_NAME
cmake ./ -DLIBEVENT_INCLUDE_DIR=/usr/local/include -DLIBEV_LIBRARY=/usr/local/libev/lib/libev.so -DLIBEV_INCLUDE_DIR=/usr/local/libev/include
#./configure --without-spdylay --without-systemd --enable-app --prefix=/usr/local; 
make; make install;




TMP_NAME=leveldb
echo $TMP_NAME
mkdir ~/tmpBuilds
cd ~/tmpBuilds; rm -r $TMP_NAME;
wget 'http://github.com/google/leveldb/archive/v1.20.tar.gz'
tar xf v1.20.tar.gz
mv leveldb-1.20 $TMP_NAME;cd $TMP_NAME; 
make;
mv out-shared /usr/local/leveldb;
echo /usr/local/leveldb > "/etc/ld.so.conf.d/leveldb.conf"

TMP_NAME=libibverbs
echo $TMP_NAME
mkdir ~/tmpBuilds
cd ~/tmpBuilds; rm -r $TMP_NAME;
wget 'http://www.openfabrics.org/downloads/libibverbs/libibverbs-1.1.4-1.24.gb89d4d7.tar.gz'  -O $TMP_NAME.tar.gz
tar xf $TMP_NAME.tar.gz
mv libibverbs-1.1.4 $TMP_NAME;cd $TMP_NAME
./configure --prefix=/usr/local; 
make; make install;

TMP_NAME=ceph
echo $TMP_NAME
mkdir ~/tmpBuilds
cd ~/tmpBuilds; rm -r $TMP_NAME;
wget 'http://download.ceph.com/tarballs/ceph-10.2.10.tar.gz'
tar xf ceph-10.2.10.tar.gz
mv ceph-10.2.10 $TMP_NAME;cd $TMP_NAME; 
./autogen.sh;
./configure --enable-client --disable-server --with-cryptopp --with-libzfs --without-cython --build=`uname -m`-Ubuntu-linux-gnu --prefix=/opt/ceph --without-fuse --without-libaio --without-libxfs --without-openldap
 make -j12;
cmake  ~/tmpBuilds/ceph -DWITH_MANPAGE=OFF -DWITH_OPENLDAP=OFF -DWITH_SHARED=ON -DWITH_SPDK=OFF -DWITH_BLUESTORE=OFF -DWITH_LEVELDB=OFF -DWITH_NSS=OFF -DWITH_BLKIN=OFF -DWITH_LTTNG=OFF -DWITH_BABELTRACE=OFF


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
wget 'http://github.com/quantcast/qfs/archive/1.2.1.tar.gz'
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
wget 'ftp://ftp.lyx.org/pub/linux/distributions/0linux/archives_sources/libgssapi/libgssapi-0.11.tar.gz'
tar xzf libgssapi-0.11.tar.gz
mv libgssapi-0.11 $TMP_NAME;cd $TMP_NAME;
./configure  --prefix=/usr/local; 
make;  make install;

TMP_NAME=nfs-ganesha
echo $TMP_NAME
mkdir ~/tmpBuilds
cd ~/tmpBuilds; rm -r $TMP_NAME;
wget 'http://github.com/nfs-ganesha/nfs-ganesha/archive/V2.5-rc7.tar.gz'
tar xzf V2.5-rc7.tar.gz
mv nfs-ganesha-2.5-rc7 $TMP_NAME;
mkdir $TMP_NAME-build;cd $TMP_NAME-build;
cmake -DUSE_GSS=OFF -DUSE_TSAN=ON -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/usr/local  ../$TMP_NAME/src





#### > libX11 > 
apt-get install -y libx11-dev 
libpthread-stubs0-dev libx11-dev libx11-doc libxau-dev libxcb 1-dev libxdmcp-dev x11proto-core-dev x11proto-input-dev x11proto-kb-dev xorg-sgml-doctools xtrans-dev


TMP_NAME=xorg-macros
echo $TMP_NAME
mkdir ~/tmpBuilds
cd ~/tmpBuilds; rm -r $TMP_NAME;
wget 'http://www.x.org/releases/X11R7.7/src/everything/util-macros-1.17.tar.gz'
tar xf util-macros-1.17.tar.gz
mv util-macros-1.17 $TMP_NAME;cd $TMP_NAME; 
./configure  --prefix=/usr/local;
make; make install

ldconfig

TMP_NAME=libpthread-stubs
echo $TMP_NAME
mkdir ~/tmpBuilds
cd ~/tmpBuilds; rm -r $TMP_NAME;
wget 'http://www.x.org/releases/X11R7.7/src/xcb/libpthread-stubs-0.3.tar.gz'
tar xf libpthread-stubs-0.3.tar.gz
mv libpthread-stubs-0.3 $TMP_NAME;cd $TMP_NAME; 
./configure  --prefix=/usr/local;
make; make install

ldconfig

TMP_NAME=libXau
echo $TMP_NAME
mkdir ~/tmpBuilds
cd ~/tmpBuilds; rm -r $TMP_NAME;
wget 'http://www.x.org/releases/X11R7.7/src/lib/libXau-1.0.7.tar.gz'
tar xf libXau-1.0.7.tar.gz
mv libXau-1.0.7 $TMP_NAME;cd $TMP_NAME; 
./configure  --prefix=/usr/local;
make; make install

ldconfig

TMP_NAME=libxcb
echo $TMP_NAME
mkdir ~/tmpBuilds
cd ~/tmpBuilds; rm -r $TMP_NAME;
wget 'http://www.x.org/releases/X11R7.7/src/xcb/libxcb-1.8.1.tar.gz'
tar xf libxcb-1.8.1.tar.gz
mv libxcb-1.8.1 $TMP_NAME;cd $TMP_NAME; 
./configure --disable-static --prefix=/usr/local;
make; make install

ldconfig

TMP_NAME=xtrans
echo $TMP_NAME
mkdir ~/tmpBuilds
cd ~/tmpBuilds; rm -r $TMP_NAME;
wget 'http://www.x.org/releases/X11R7.7/src/lib/xtrans-1.2.7.tar.gz'
tar xf xtrans-1.2.7.tar.gz
mv xtrans-1.2.7 $TMP_NAME;cd $TMP_NAME; 
./configure  --prefix=/usr/local;
make; make install

ldconfig

TMP_NAME=inputproto
echo $TMP_NAME
mkdir ~/tmpBuilds;
cd ~/tmpBuilds; rm -r $TMP_NAME;
wget 'http://www.x.org/releases/X11R7.7/src/proto/inputproto-2.2.tar.gz'
tar xf inputproto-2.2.tar.gz
mv inputproto-2.2 $TMP_NAME;cd $TMP_NAME; 
./configure  --prefix=/usr/local;
make; make install

ldconfig

TMP_NAME=kbproto
echo $TMP_NAME
mkdir ~/tmpBuilds;
cd ~/tmpBuilds; rm -r $TMP_NAME;
wget 'http://www.x.org/releases/X11R7.7/src/proto/kbproto-1.0.6.tar.gz'
tar xf kbproto-1.0.6.tar.gz
mv kbproto-1.0.6 $TMP_NAME;cd $TMP_NAME; 
./configure  --prefix=/usr/local;
make; make install

ldconfig

TMP_NAME=xproto
echo $TMP_NAME
mkdir ~/tmpBuilds
cd ~/tmpBuilds; rm -r $TMP_NAME;
wget 'http://www.x.org/releases/X11R7.7/src/proto/xproto-7.0.23.tar.gz'
tar xf xproto-7.0.23.tar.gz
mv xproto-7.0.23 $TMP_NAME;cd $TMP_NAME; 
./configure  --prefix=/usr/local;
make; make install

ldconfig

TMP_NAME=libX11
echo $TMP_NAME
mkdir ~/tmpBuilds
cd ~/tmpBuilds; rm -r $TMP_NAME;
wget 'http://www.x.org/releases/X11R7.7/src/lib/libX11-1.5.0.tar.gz'
tar xf libX11-1.5.0.tar.gz
mv libX11-1.5.0 $TMP_NAME;cd $TMP_NAME; 
./configure  --prefix=/usr/local;
make; make install

####### > libX11

TMP_NAME=libX11
echo $TMP_NAME
mkdir ~/tmpBuilds
cd ~/tmpBuilds; rm -r $TMP_NAME;
wget 'http://github.com/mirror/libX11/archive/libX11-1.6.5.tar.gz'
tar xf libX11-1.6.5.tar.gz
mv libX11-1.6.5 $TMP_NAME;cd $TMP_NAME; 
./configure  --prefix=/usr/local;
make; make install



TMP_NAME=skia
echo $TMP_NAME
mkdir ~/tmpBuilds
cd ~/tmpBuilds; rm -r $TMP_NAME;
wget 'http://github.com/google/skia/archive/chrome/m38_2125.tar.gz'
tar xf m38_2125.tar.gz
mv skia-chrome-m38_2125 $TMP_NAME;cd $TMP_NAME; 
./configure --enable-timers --prefix=/usr/local; #
make; make check; make install





 librsvg2 libexif

 pixman
xcb-proto libxcb xextproto libX11
renderproto libXrender libXrender





TMP_NAME=xcb-proto
echo $TMP_NAME
mkdir ~/tmpBuilds
cd ~/tmpBuilds; rm -r $TMP_NAME;
wget 'http://www.x.org/releases/X11R7.7/src/xcb/xcb-proto-1.7.1.tar.gz'
tar xf xcb-proto-1.7.1.tar.gz
mv xcb-proto-1.7.1 $TMP_NAME;cd $TMP_NAME; 
./configure  --prefix=/usr/local;
make; make install


TMP_NAME=xextproto
echo $TMP_NAME
mkdir ~/tmpBuilds
cd ~/tmpBuilds; rm -r $TMP_NAME;
wget 'http://www.x.org/releases/X11R7.7/src/proto/xextproto-7.2.1.tar.gz'
tar xf xextproto-7.2.1.tar.gz
mv xextproto-7.2.1 $TMP_NAME;cd $TMP_NAME; 
./configure  --prefix=/usr/local;
make; make install




TMP_NAME=renderproto
echo $TMP_NAME
mkdir ~/tmpBuilds
cd ~/tmpBuilds; rm -r $TMP_NAME;
wget 'http://www.x.org/archive/individual/proto/renderproto-0.11.1.tar.gz'
tar xf renderproto-0.11.1.tar.gz
mv renderproto-0.11.1 $TMP_NAME;cd $TMP_NAME; 
./configure  --prefix=/usr/local;
make; make install

TMP_NAME=libXrender
echo $TMP_NAME
mkdir ~/tmpBuilds
cd ~/tmpBuilds; rm -r $TMP_NAME;
wget 'http://www.x.org/archive//individual/lib/libXrender-0.9.10.tar.gz'
tar xf libXrender-0.9.10.tar.gz
mv libXrender-0.9.10 $TMP_NAME;cd $TMP_NAME; 
./configure  --prefix=/usr/local;
make; make install









##############################
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
wget 'http://ftp.gnu.org/gnu/guile/guile-2.0.13.tar.xz'
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



#http://www.x.org/pub/individual/util/util-macros-1.19.1.tar.bz2
TMP_NAME=mkfontdir
echo $TMP_NAME
mkdir ~/tmpBuilds
cd ~/tmpBuilds; rm -r $TMP_NAME;
wget 'http://www.x.org/releases/individual/app/mkfontdir-1.0.7.tar.gz'
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



#echo openldap
#cd ~/dependeciesBuilds; rm -r openldap;
#wget 'ftp://ftp.openldap.org/pub/OpenLDAP/openldap-release/openldap-2.4.44.tgz'
#tar xzvf openldap-2.4.44.tgz
#mv openldap-2.4.44 openldap; cd openldap
#./configure --enable-backends=no --enable-ldap=yes  --enable-sock=yes --prefix=/usr/local;
#make depend; make; make check; make install
#cd ~; /sbin/ldconfig

http://ftp.ntua.gr/mirror/gnu/libmicrohttpd/






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