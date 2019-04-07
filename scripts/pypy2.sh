#!/usr/bin/env bash
tn='pypy2.7-v7.0.0-src'; url='http://bitbucket.org/pypy/pypy/downloads/pypy2.7-v7.0.0-src.tar.bz2';
set_source 'tar';
if [ $only_dw == 1 ];then return;fi

for n in ncurses panel term; do sed -i 's/'$n'/'$n'w/g' lib_pypy/_curses_build.py; sed -i 's/#include <'$n'w.h>/#include <'$n'.h>/g' lib_pypy/_curses_build.py; done;
sed -i 's/ncurses/ncursesw/g' pypy/module/_minimal_curses/fficurses.py;

cd pypy/goal;
export VERBOSE=1;
export LDFLAGS="-DTCMALLOC_MINIMAL -ltcmalloc_minimal -fno-builtin-malloc -fno-builtin-calloc -fno-builtin-realloc -fno-builtin-free"
export CFLAGS="$ADD_O_FS $LDFLAGS -DNDEBUG"
export CPPFLAGS="$ADD_O_FS $LDFLAGS"
export INCLUDEDIRS="-I$CUST_INST_PREFIX/include"
(
PYPY_LOCALBASE=$SOURCES_PATH/$sn \
python ../../rpython/bin/rpython \
			--no-shared --thread --make-jobs=$NUM_PROCS \
			--verbose --no-profopt --gc=incminimark --gcremovetypeptr --continuation \
			--inline-threshold=33.4 --translation-backendopt-inline --listcompr \
			--translation-backendopt-mallocs --translation-backendopt-constfold --translation-backendopt-stack_optimization \
			--translation-backendopt-storesink --translation-backendopt-remove_asserts --translation-backendopt-really_remove_asserts \
			--if-block-merge --translation-withsmallfuncsets=10 --translation-jit_opencoder_model=big --translation-jit_profiler=off \
			--translation-rweakref \
			--translation-backendopt-print_statistics \
			--opt=jit targetpypystandalone.py --allworkingmodules --withmod-_file \
			--objspace-std-intshortcut --objspace-std-newshortcut --objspace-std-optimized_list_getitem \
			--objspace-std-methodcachesizeexp=15 --objspace-std-withliststrategies\
			--objspace-std-withspecialisedtuple --objspace-std-withtproxy) &
# --objspace-std-withprebuiltint
while [ ! -f pypy-c ]; do sleep 60; done;
# --clever-malloc-removal --clever-malloc-removal-threshold=33.4 --translation-split_gc_address_space    #http://doc.pypy.org/en/latest/config/commandline.html#general-translation-options

if [ -f 'pypy-c' ]; then	
	
	./pypy-c ../tool/build_cffi_imports.py --without-tk;
	./pypy-c ../tool/release/package.py --without-tk --archive-name $sn --targetdir $DOWNLOAD_PATH/$sn.tar.bz2;

	cd $SOURCES_PATH/$sn;rm -rf built_pkg; mkdir built_pkg; cd built_pkg; tar -xf $DOWNLOAD_PATH/$sn.tar.bz2;
	rm -rf /opt/pypy2;mv pypy2 /opt/;
	rm -f /usr/bin/pypy; ln -s /opt/pypy2/bin/pypy /usr/bin/pypy
	pypy -m ensurepip; rm -f /usr/bin/pypy_pip; ln -s /opt/pypy2/bin/pip /usr/bin/pypy_pip
	
	source /etc/profile;source ~/.bashrc;ldconfig;

	rm -rf ~/.cache/pip 
	./../pip_install.sh pypy setuptools
	./../pip_install.sh pypy pip
	./../pip_install.sh pypy setuptools

	./../pip_install.sh pypy cffi 
	./../pip_install.sh pypy greenlet
	./../pip_install.sh pypy psutil deepdiff
	./../pip_install.sh pypy xlrd lxml	
	with_gmp=no ./../pip_install.sh pypy pycrypto 
	./../pip_install.sh pypy cryptography
	./../pip_install.sh pypy pyopenssl #LDFLAGS="-L$CUST_INST_PREFIX/ssl/lib" CFLAGS="-I$CUST_INST_PREFIX/ssl/include" 

	./../pip_install.sh pypy pycryptodomex
	
	./../pip_install.sh pypy h2 #https://github.com/python-hyper/hyper-h2/archive/master.zip
	./../pip_install.sh pypy urllib3 dnspython
	./../pip_install.sh pypy linuxfd http://github.com/kashirin-alex/eventlet/archive/master.zip 

	./../pip_install.sh pypy msgpack-python
	./../pip_install.sh pypy webp 
	./../pip_install.sh pypy Pillow Wand
	./../pip_install.sh pypy weasyprint==0.42.3
	./../pip_install.sh pypy brotli pylzma rarfile zopfli  #zipfile pysnappy
	./../pip_install.sh pypy ply slimit
	./../pip_install.sh pypy guess_language
	./../pip_install.sh pypy paypalrestsdk #pygeocoder python-google-places
	./../pip_install.sh pypy josepy acme
	./../pip_install.sh pypy fontTools

	./../pip_install.sh pypy thrift
	./../pip_install.sh pypy http://github.com/kashirin-alex/libpyhdfs/archive/master.zip
	./../pip_install.sh pypy http://github.com/kashirin-alex/PyHelpers/archive/master.zip
	
	STDCXX=17 ./../pip_install.sh pypy --verbose cppyy
fi


export LDFLAGS=""
export CFLAGS=""
export CPPFLAGS=""
export INCLUDEDIRS=""
