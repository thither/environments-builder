#!/usr/bin/env bash
tn='pypy3-v6.0.0-src'; url='http://bitbucket.org/pypy/pypy/downloads/pypy3-v6.0.0-src.tar.bz2';
set_source 'tar';
if [ $only_dw == 1 ];then return;fi

for n in ncurses panel term; do sed -i 's/'$n'/'$n'w/g' lib_pypy/_curses_build.py; sed -i 's/#include <'$n'w.h>/#include <'$n'.h>/g' lib_pypy/_curses_build.py; done;
sed -i 's/ncurses/ncursesw/g' pypy/module/_minimal_curses/fficurses.py;

cd  pypy/goal/;
(CFLAGS="$ADD_O_FS" CPPFLAGS="$ADD_O_FS" PYPY_LOCALBASE=$BUILDS_PATH/$sn python ../../rpython/bin/rpython --lto --shared --thread --make-jobs=$NUM_PROCS --no-profopt --gc=incminimark --gcremovetypeptr --continuation  --translation-backendopt-inline --translation-backendopt-mallocs --translation-backendopt-constfold --translation-backendopt-stack_optimization --translation-backendopt-storesink  --translation-backendopt-remove_asserts --translation-backendopt-really_remove_asserts --if-block-merge --translation-withsmallfuncsets=3 --translation-jit_profiler=off --translation-jit_opencoder_model=big --translation-backendopt-print_statistics --opt=jit targetpypystandalone.py  --allworkingmodules --objspace-std-intshortcut --objspace-std-newshortcut --objspace-std-optimized_list_getitem --objspace-std-withprebuiltint --objspace-std-withspecialisedtuple --objspace-std-withtproxy) &
# (PYPY_LOCALBASE=$BUILDS_PATH/$sn pypy ../../rpython/bin/rpython) &
while [ ! -f pypy3-c ]; do sleep 60; done;

if [ -f 'pypy3-c' ]; then
	python ../tool/build_cffi_imports.py ;
	python ../tool/release/package.py --without-tk --archive-name $sn --targetdir $DOWNLOAD_PATH/$sn.tar.bz2;

	cd $BUILDS_PATH/$sn;rm -rf built_pkg; mkdir built_pkg; cd built_pkg; tar -xf $DOWNLOAD_PATH/$sn.tar.bz2;
	rm -rf /opt/pypy3;mv pypy3 /opt/;
	rm -f /usr/bin/pypy3; ln -s /opt/pypy3/bin/pypy3 /usr/bin/pypy3
	pypy3 -m ensurepip; rm -f /usr/bin/pypy3_pip; ln -s /opt/pypy3/bin/pip3 /usr/bin/pypy3_pip
	
	source /etc/profile;source ~/.bashrc;ldconfig;

	rm -rf ~/.cache/pip 
	pypy3_pip install --upgrade setuptools
	pypy3_pip install --upgrade pip
	pypy3_pip install --upgrade setuptools

	pypy3_pip install --upgrade cffi 
	pypy3_pip install --upgrade greenlet
	pypy3_pip install --upgrade psutil deepdiff
	pypy3_pip install --upgrade xlrd lxml	
	with_gmp=no pypy3_pip install --upgrade  pycrypto 
	pypy3_pip install --upgrade cryptography
	pypy3_pip install --upgrade pyopenssl #LDFLAGS="-L$CUST_INST_PREFIX/ssl/lib" CFLAGS="-I$CUST_INST_PREFIX/ssl/include" 

	pypy3_pip install --upgrade h2 #https://github.com/python-hyper/hyper-h2/archive/master.zip
	pypy3_pip install --upgrade urllib3 dnspython
	pypy3_pip install --upgrade https://github.com/eventlet/eventlet/archive/v0.19.0.zip # https://github.com/eventlet/eventlet/archive/master.zip #eventlet
	echo '' > "/opt/pypy3/site-packages/eventlet/green/OpenSSL/rand.py"
	sed -i "1s;^;import OpenSSL.SSL\nfor n in dir(OpenSSL.SSL):\n    exec(n+'=getattr(OpenSSL.SSL, \"'+n+'\")')\n;" /opt/pypy3/site-packages/eventlet/green/OpenSSL/SSL.py
	sed -i 's/from OpenSSL.SSL import \*//g' /opt/pypy3/site-packages/eventlet/green/OpenSSL/SSL.py;
	sed -i "1s;^;import OpenSSL.crypto\nfor n in dir(OpenSSL.crypto):\n    exec(n+'=getattr(OpenSSL.crypto, \"'+n+'\")')\n;" /opt/pypy3/site-packages/eventlet/green/OpenSSL/crypto.py

	pypy3_pip install --upgrade msgpack-python
	pypy3_pip install --upgrade Wand
	pypy3_pip install --upgrade weasyprint                 
	pypy3_pip install --upgrade pylzma rarfile  #zipfile pysnappy
	pypy3_pip install --upgrade guess_language
	pypy3_pip install --upgrade paypalrestsdk #pygeocoder python-google-places
	pypy3_pip install --upgrade josepy acme

	pypy3_pip install --upgrade https://github.com/kashirin-alex/libpyhdfs/archive/master.zip

fi

