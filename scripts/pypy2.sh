#!/usr/bin/env bash
tn='pypy2-v5.10.0-src'; url='http://bitbucket.org/pypy/pypy/downloads/pypy2-v5.10.0-src.tar.bz2';
set_source 'tar';
if [ $only_dw == 1 ];then return;fi

for n in ncurses panel term; do sed -i 's/'$n'/'$n'w/g' lib_pypy/_curses_build.py; sed -i 's/#include <'$n'w.h>/#include <'$n'.h>/g' lib_pypy/_curses_build.py; done;
sed -i 's/ncurses/ncursesw/g' pypy/module/_minimal_curses/fficurses.py;

(PYPY_LOCALBASE=$BUILDS_PATH/$sn python rpython/bin/rpython --make-jobs=$NUM_PROCS --lto --no-shared --translation-backendopt-print_statistics --opt=jit pypy/goal/targetpypystandalone.py) & 
while [ ! -f pypy-c ]; do sleep 60; done; sleep 300; 
	
mv pypy-c pypy-tmp;
#(PYPY_LOCALBASE=$BUILDS_PATH/$sn ./pypy-tmp rpython/bin/rpython --lto --shared --thread --make-jobs=$NUM_PROCS --translation-jit_opencoder_model=big --translation-backendopt-print_statistics --opt=jit pypy/goal/targetpypystandalone.py) &
(PYPY_LOCALBASE=$BUILDS_PATH/$sn ./pypy-tmp rpython/bin/rpython --lto --shared --thread --make-jobs=$NUM_PROCS --no-profopt --gc=incminimark --gcremovetypeptr --continuation  --translation-backendopt-inline --translation-backendopt-mallocs --translation-backendopt-constfold --translation-backendopt-stack_optimization --translation-backendopt-storesink  --translation-backendopt-remove_asserts --translation-backendopt-really_remove_asserts --if-block-merge --translation-withsmallfuncsets=3 --translation-jit_profiler=off --translation-jit_opencoder_model=big --translation-backendopt-print_statistics --opt=jit pypy/goal/targetpypystandalone.py  --allworkingmodules --objspace-std-intshortcut --objspace-std-newshortcut --objspace-std-optimized_list_getitem --objspace-std-withprebuiltint --objspace-std-withspecialisedtuple --objspace-std-withtproxy) &
while [ ! -f pypy-c ]; do sleep 60; done; sleep 300; 
#--clever-malloc-removal --clever-malloc-removal-threshold=20   #http://doc.pypy.org/en/latest/config/commandline.html#general-translation-options

if [ -f 'pypy-c' ]; then	
	cp pypy-c pypy/goal/;cp libpypy-c.so pypy/goal/;
	./pypy-c pypy/tool/build_cffi_imports.py --without-tk;
	./pypy-c pypy/tool/release/package.py --without-tk --archive-name $sn --targetdir $DOWNLOAD_PATH/$sn.tar.bz2;

	cd $BUILDS_PATH/$sn;rm -r built_pkg; mkdir built_pkg; cd built_pkg; tar -xf $DOWNLOAD_PATH/pypy2.tar.bz2;
	rm -r /opt/pypy2;mv pypy2 /opt/;
	rm /usr/bin/pypy; ln -s /opt/pypy2/bin/pypy /usr/bin/pypy
	pypy -m ensurepip; rm /usr/bin/pypy_pip; ln -s /opt/pypy2/bin/pip /usr/bin/pypy_pip
	
	unset PYPY_LOCALBASE;
	source /etc/profile;source ~/.bashrc;ldconfig;

	# pypy_pip uninstall -y pyhdfs josepy acme paypalrestsdk guess_language pylzma rarfile cffi Wand weasyprint greenlet psutil deepdiff xlrd lxml pycrypto cryptography pyopenssl pycparser h2 urllib3 dnspython eventlet msgpack-python

	rm -r ~/.cache/pip 
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

	pypy_pip install --upgrade h2 #https://github.com/python-hyper/hyper-h2/archive/master.zip
	pypy_pip install --upgrade urllib3 dnspython
	pypy_pip install --upgrade https://github.com/eventlet/eventlet/archive/v0.19.0.zip # https://github.com/eventlet/eventlet/archive/master.zip #eventlet
	echo '' > "/opt/pypy2/site-packages/eventlet/green/OpenSSL/rand.py"
	sed -i "1s;^;import OpenSSL.SSL\nfor n in dir(OpenSSL.SSL):\n    exec(n+'=getattr(OpenSSL.SSL, \"'+n+'\")')\n;" /opt/pypy2/site-packages/eventlet/green/OpenSSL/SSL.py
	sed -i 's/from OpenSSL.SSL import \*//g' /opt/pypy2/site-packages/eventlet/green/OpenSSL/SSL.py;
	sed -i "1s;^;import OpenSSL.crypto\nfor n in dir(OpenSSL.crypto):\n    exec(n+'=getattr(OpenSSL.crypto, \"'+n+'\")')\n;" /opt/pypy2/site-packages/eventlet/green/OpenSSL/crypto.py

	pypy_pip install --upgrade msgpack-python
	pypy_pip install --upgrade Wand
	pypy_pip install --upgrade weasyprint                 
	pypy_pip install --upgrade pylzma rarfile  #zipfile pysnappy
	pypy_pip install --upgrade guess_language
	pypy_pip install --upgrade paypalrestsdk #pygeocoder python-google-places
	pypy_pip install --upgrade josepy acme

	pypy_pip install --upgrade https://github.com/kashirin-alex/libpyhdfs/archive/master.zip

fi

