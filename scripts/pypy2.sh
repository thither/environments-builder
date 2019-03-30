#!/usr/bin/env bash
tn='pypy2.7-v7.1.0-src'; url='http://bitbucket.org/pypy/pypy/downloads/pypy2.7-v7.1.0-src.tar.bz2';
set_source 'tar';
if [ $only_dw == 1 ];then return;fi

for n in ncurses panel term; do sed -i 's/'$n'/'$n'w/g' lib_pypy/_curses_build.py; sed -i 's/#include <'$n'w.h>/#include <'$n'.h>/g' lib_pypy/_curses_build.py; done;
sed -i 's/ncurses/ncursesw/g' pypy/module/_minimal_curses/fficurses.py;

cd pypy/goal;export VERBOSE=1;
(
LDFLAGS="-DTCMALLOC_MINIMAL -ltcmalloc_minimal -fno-builtin-malloc -fno-builtin-calloc -fno-builtin-realloc -fno-builtin-free" \
CFLAGS="$ADD_O_FS $LDFLAGS" \
INCLUDEDIRS="-I/usr/local/include" \
VERBOSE=1 \
PYPY_LOCALBASE=$BUILDS_PATH/$sn \
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

	cd $BUILDS_PATH/$sn;rm -rf built_pkg; mkdir built_pkg; cd built_pkg; tar -xf $DOWNLOAD_PATH/$sn.tar.bz2;
	rm -rf /opt/pypy2;mv pypy2 /opt/;
	rm -f /usr/bin/pypy; ln -s /opt/pypy2/bin/pypy /usr/bin/pypy
	pypy -m ensurepip; rm -f /usr/bin/pypy_pip; ln -s /opt/pypy2/bin/pip /usr/bin/pypy_pip
	
	source /etc/profile;source ~/.bashrc;ldconfig;

	rm -rf ~/.cache/pip 
	pypy_pip install --upgrade setuptools
	pypy_pip install --upgrade pip
	pypy_pip install --upgrade setuptools

	pypy_pip install --upgrade cffi 
	pypy_pip install --upgrade greenlet
	pypy_pip install --upgrade psutil deepdiff
	pypy_pip install --upgrade xlrd lxml	
	with_gmp=no pypy_pip install --upgrade  pycrypto 
	pypy_pip install --upgrade cryptography
	pypy_pip install --upgrade pyopenssl #LDFLAGS="-L$CUST_INST_PREFIX/ssl/lib" CFLAGS="-I$CUST_INST_PREFIX/ssl/include" 

	pypy_pip install --upgrade pycryptodomex
	
	pypy_pip install --upgrade h2 #https://github.com/python-hyper/hyper-h2/archive/master.zip
	pypy_pip install --upgrade urllib3 dnspython
	pypy_pip install --upgrade linuxfd https://github.com/kashirin-alex/eventlet/archive/master.zip 

	pypy_pip install --upgrade msgpack-python
	pypy_pip install --upgrade webp 
	pypy_pip install --upgrade Pillow Wand
	pypy_pip install --upgrade weasyprint==0.42.3
	pypy_pip install --upgrade brotli pylzma rarfile zopfli  #zipfile pysnappy
	pypy_pip install --upgrade ply slimit
	pypy_pip install --upgrade guess_language
	pypy_pip install --upgrade paypalrestsdk #pygeocoder python-google-places
	pypy_pip install --upgrade josepy acme
	pypy_pip install --upgrade fontTools

	pypy_pip install --upgrade https://github.com/kashirin-alex/libpyhdfs/archive/master.zip
	pypy_pip install --upgrade https://github.com/kashirin-alex/PyHelpers/archive/master.zip
	
	STDCXX=17 pypy_pip install --upgrade --verbose cppyy
fi
