#!/usr/bin/env bash
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
	update-alternatives --install /usr/bin/ar ar $CUST_INST_PREFIX/bin/ar 60
fi
if [ -f $CUST_INST_PREFIX/bin/ranlib ]; then
	mv /usr/bin/ranlib /usr/bin/ranlib_os;
	update-alternatives --install /usr/bin/ranlib ranlib $CUST_INST_PREFIX/bin/ranlib 60
fi
# --with-cloog=$CUST_INST_PREFIX --disable-cloog-version-check --enable-fixed-point  --enable-stage1-checking=all  --enable-stage1-languages=all #http://gcc.gnu.org/install/configure.html
#http://stackoverflow.com/questions/7832892/how-to-change-the-default-gcc-compiler-in-ubuntu
