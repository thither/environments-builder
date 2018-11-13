#!/usr/bin/env bash
tn='pypy-pypy-333cd7c29400'; url='http://bitbucket.org/pypy/pypy/get/stmgc-c8.zip';
set_source 'zip';
if [ $only_dw == 1 ];then return;fi

rm -r $BUILTS_PATH/$sn;export PYPY_USESSION_DIR=$BUILTS_PATH/$sn;mkdir -p $BUILTS_PATH/$sn; ln -s gcc $CUST_INST_PREFIX/bin/gcc-seg-gs;

for n in ncurses panel term; do
	sed -i 's/'$n'/'$n'w/g' lib_pypy/_curses_build.py;
	sed -i 's/#include <'$n'w.h>/#include <'$n'.h>/g' lib_pypy/_curses_build.py; 
done;
sed -i 's/ncurses/ncursesw/g' pypy/module/_minimal_curses/fficurses.py;

(PYPY_LOCALBASE=$BUILDS_PATH/$sn pypy rpython/bin/rpython --shared --thread --make-jobs=12 --translation-jit_profiler=off --translation-jit_opencoder_model=big --translation-backendopt-print_statistics --stm --opt=jit pypy/goal/targetpypystandalone.py) & 
while [ ! -f pypy-c ]; do sleep 60; done;

if [ -f 'pypy-c' ]; then
	cp pypy-c pypy/goal/;cp libpypy-c.so pypy/goal/;
	export CPATH=$PYPY_USESSION_DIR/usession-stmgc-c8-0/include/:$BUILDS_PATH/$sn/pypy/module/cpyext/include/
	./pypy-c pypy/tool/build_cffi_imports.py --without-tk;
	./pypy-c pypy/tool/release/package.py --without-tk --archive-name $sn --targetdir $DOWNLOAD_PATH/$sn.tar.bz2;
	export CPATH='';
	cd $BUILDS_PATH/$sn;rm -r built_pkg; mkdir built_pkg; cd built_pkg; tar -xf $DOWNLOAD_PATH/$sn.tar.bz2;
	rm -r /opt/pypy2stm;mv pypy2stm /opt/;
	rm /usr/bin/pypy2stm; ln -s /opt/pypy2stm/bin/pypy /usr/bin/pypy2stm
	pypy2stm -m ensurepip; rm /usr/bin/pypy2stm_pip; ln -s /opt/pypy2stm/bin/pip /usr/bin/pypy2stm_pip
	
	unset PYPY_USESSION_DIR;unset PYPY_LOCALBASE;
	source /etc/profile;source ~/.bashrc;ldconfig;
	
	rm -r ~/.cache/pip 
	pypy2stm_pip install --upgrade setuptools
	pypy2stm_pip install --upgrade pip
	pypy2stm_pip install --upgrade setuptools

	pypy2stm_pip install --upgrade cffi 
	pypy2stm_pip install --upgrade greenlet
	pypy2stm_pip install --upgrade psutil deepdiff
	pypy2stm_pip install --upgrade xlrd lxml	
	with_gmp=no pypy2stm_pip install --upgrade  pycrypto 
	pypy2stm_pip install --upgrade cryptography
	pypy2stm_pip install --upgrade pyopenssl #LDFLAGS="-L$CUST_INST_PREFIX/ssl/lib" CFLAGS="-I$CUST_INST_PREFIX/ssl/include" 
	pypy2stm_pip install --upgrade pycryptodomex

	pypy2stm_pip install --upgrade h2 #https://github.com/python-hyper/hyper-h2/archive/master.zip
	pypy2stm_pip install --upgrade urllib3 dnspython
	pypy2stm_pip install --upgrade linuxfd https://github.com/kashirin-alex/eventlet/archive/master.zip 

	pypy2stm_pip install --upgrade msgpack-python
	pypy2stm_pip install --upgrade webp Pillow Wand
	pypy2stm_pip install --upgrade weasyprint==0.42.3                 
	pypy2stm_pip install --upgrade brotli pylzma rarfile zopfli  #zipfile pysnappy
	pypy2stm_pip install --upgrade ply slimit
	pypy2stm_pip install --upgrade guess_language
	pypy2stm_pip install --upgrade paypalrestsdk #pygeocoder python-google-places
	pypy2stm_pip install --upgrade josepy acme
	pypy2stm_pip install --upgrade fontTools

	pypy2stm_pip install --upgrade https://github.com/kashirin-alex/libpyhdfs/archive/master.zip

fi
rm $CUST_INST_PREFIX/bin/gcc-seg-gs;
