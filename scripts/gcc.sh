#!/usr/bin/env bash
tn='gcc-7.2.0'; url='http://mirrors.concertpass.com/gcc/releases/gcc-7.2.0/gcc-7.2.0.tar.xz';
set_source 'tar';
ln -s /usr/include/asm-generic /usr/include/asm;
configure_build --disable-multilib --target=`_build` --enable-default-pie --enable-gold=yes --enable-languages=all --enable-shared --enable-libiberty --enable-libssp --enable-libasan --enable-libtsan --enable-libgomp --enable-libgcc --enable-libstdc++ --enable-libada --enable-initfini-array --enable-vtable-verify  --enable-objc-gc --enable-lto --enable-tls --enable-threads=posix --with-long-double-128 --enable-decimal-float=yes --with-mpfr=$CUST_INST_PREFIX --with-mpc=$CUST_INST_PREFIX --with-isl=$CUST_INST_PREFIX --with-gmp=$CUST_INST_PREFIX --prefix=$CUST_INST_PREFIX; 
#--enable-noexist#--enable-multilib  --with-multilib-list=m64 --libdir=$CUST_INST_PREFIX/lib
do_make;do_make install;do_make all;

if [ -f $CUST_INST_PREFIX != '/usr' ]; then
	if [ -f $CUST_INST_PREFIX/bin/gcc ]; then
		if [ -f /usr/bin/gcc ]; then rm /usr/bin/gcc;fi
		if [ -f /usr/bin/cc ]; then rm /usr/bin/cc;fi
		ln -s $CUST_INST_PREFIX/bin/gcc $CUST_INST_PREFIX/bin/cc
	fi
	if [ -f $CUST_INST_PREFIX/bin/cpp ] && [ -f /usr/bin/cpp ]; then rm /usr/bin/cpp;fi
	if [ -f $CUST_INST_PREFIX/bin/c++ ] && [ -f /usr/bin/c++ ]; then rm /usr/bin/c++;fi
	if [ -f $CUST_INST_PREFIX/bin/g++ ] && [ -f /usr/bin/g++ ]; then rm /usr/bin/g++;fi
	if [ -f $CUST_INST_PREFIX/bin/ar ] && [ -f /usr/bin/ar ]; then mv /usr/bin/ar /usr/bin/ar_os;fi
	if [ -f $CUST_INST_PREFIX/bin/ranlib ] && [ -f /usr/bin/ranlib ]; then mv /usr/bin/ranlib /usr/bin/ranlib_os;fi
fi;

# --with-cloog=$CUST_INST_PREFIX --disable-cloog-version-check --enable-fixed-point  --enable-stage1-checking=all  --enable-stage1-languages=all #http://gcc.gnu.org/install/configure.html
