#!/usr/bin/env bash
tn='pypy3.6-v7.0.0-src'; url='http://bitbucket.org/pypy/pypy/downloads/pypy3.6-v7.0.0-src.tar.bz2';
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
			--opt=jit targetpypystandalone.py --allworkingmodules \
			--objspace-std-intshortcut --objspace-std-newshortcut --objspace-std-optimized_list_getitem \
			--objspace-std-methodcachesizeexp=15 --objspace-std-withliststrategies\
			--objspace-std-withspecialisedtuple --objspace-std-withtproxy) &
# --objspace-std-withprebuiltint  --lto
while [ ! -f pypy3-c ]; do sleep 60; done;


if [ -f 'pypy3-c' ]; then
	./pypy3-c ../tool/build_cffi_imports.py ;
	python ../tool/release/package.py --without-tk --archive-name $sn --targetdir $DOWNLOAD_PATH/$sn.tar.bz2;

	cd $SOURCES_PATH/$sn;rm -rf built_pkg; mkdir built_pkg; cd built_pkg; tar -xf $DOWNLOAD_PATH/$sn.tar.bz2;
	rm -rf /opt/pypy3;mv pypy3 /opt/;
	rm -f /usr/bin/pypy3; ln -s /opt/pypy3/bin/pypy3 /usr/bin/pypy3
	pypy3 -m ensurepip; rm -f /usr/bin/pypy3_pip; ln -s /opt/pypy3/bin/pip3 /usr/bin/pypy3_pip
	
	source /etc/profile;source ~/.bashrc;ldconfig;

	rm -rf ~/.cache/pip 
	pypy3_pip install --upgrade --verbose setuptools
	pypy3_pip install --upgrade --verbose pip
	pypy3_pip install --upgrade --verbose setuptools

	pypy3_pip install --upgrade --verbose cffi 
	pypy3_pip install --upgrade --verbose greenlet
	pypy3_pip install --upgrade --verbose psutil deepdiff
	pypy3_pip install --upgrade --verbose xlrd lxml	
	with_gmp=no pypy3_pip install --upgrade --verbose  pycrypto 
	pypy3_pip install --upgrade --verbose cryptography
	pypy3_pip install --upgrade --verbose pyopenssl #LDFLAGS="-L$CUST_INST_PREFIX/ssl/lib" CFLAGS="-I$CUST_INST_PREFIX/ssl/include" 
	
	pypy3_pip install --upgrade --verbose pycryptodomex

	pypy3_pip install --upgrade --verbose h2 #https://github.com/python-hyper/hyper-h2/archive/master.zip
	pypy3_pip install --upgrade --verbose urllib3 dnspython
	pypy3_pip install --upgrade --verbose linuxfd http://github.com/kashirin-alex/eventlet/archive/master.zip 

	pypy3_pip install --upgrade --verbose msgpack-python
	pypy3_pip install --upgrade --verbose webp 
	pypy3_pip install --upgrade --verbose Pillow Wand
	pypy3_pip install --upgrade --verbose weasyprint                 
	pypy3_pip install --upgrade --verbose brotli pylzma rarfile zopfli  #zipfile pysnappy
	pypy3_pip install --upgrade --verbose ply slimit
	pypy3_pip install --upgrade --verbose guess_language
	pypy3_pip install --upgrade --verbose paypalrestsdk #pygeocoder python-google-places
	pypy3_pip install --upgrade --verbose josepy acme
	pypy3_pip install --upgrade --verbose fontTools

	pypy3_pip install --upgrade --verbose http://github.com/kashirin-alex/libpyhdfs/archive/master.zip
	pypy3_pip install --upgrade --verbose http://github.com/kashirin-alex/PyHelpers/archive/master.zip

fi


export LDFLAGS=""
export CFLAGS=""
export CPPFLAGS=""
export INCLUDEDIRS=""