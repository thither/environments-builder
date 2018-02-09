#!/usr/bin/env bash
tn='pypy3-v5.10.1-src'; url='http://bitbucket.org/pypy/pypy/downloads/pypy3-v5.10.1-src.tar.bz2';
set_source 'tar';
if [ $only_dw == 1 ];then return;fi

cd pypy/goal; (INCLUDEDIRS=-I$BUILDS_PATH/$sn/inlcude PYTHONPATH=../../pypy ../../rpython/bin/rpython  --thread --translation-jit_opencoder_model=big --shared --opt=jit targetpypystandalone.py) &
while [ ! -f pypy3-c ]; do sleep 60; done; sleep 300; 

if [ -f 'pypy3-c' ]; then
	PYTHONPATH=../../ ./pypy3-c  --without-tk ../tool/build_cffi_imports.py;
	PYTHONPATH=../../ ./pypy3-c ../tool/release/package.py --without-tk --archive-name $sn --targetdir $DOWNLOAD_PATH/$sn.tar.bz2;

	cd $BUILDS_PATH/pypy3;rm -r built_pkg; mkdir built_pkg; cd built_pkg; tar -xf $DOWNLOAD_PATH/pypy3.tar.bz2;
	rm -r /opt/pypy3;mv pypy3 /opt/;
	rm /usr/bin/pypy3; ln -s /opt/pypy3/bin/pypy3 /usr/bin/pypy3
	PYTHONPATH=''
	pypy3 -m ensurepip; rm /usr/bin/pypy3_pip; ln -s /opt/pypy3/bin/pip /usr/bin/pypy3_pip
	ldconfig
	
	rm -r ~/.cache/pip 
	pypy3_pip install --upgrade setuptools
	pypy3_pip install --upgrade pip
	pypy3_pip install --upgrade setuptools

	pypy3_pip install --upgrade cffi greenlet
	pypy3_pip install --upgrade psutil deepdiff
	pypy3_pip install --upgrade xlrd lxml	
	with_gmp=no pypy3_pip install --upgrade  pycrypto 
	pypy3_pip install --upgrade cryptography
	pypy3_pip install --upgrade pyopenssl #LDFLAGS="-L$CUST_INST_PREFIX/ssl/lib" CFLAGS="-I$CUST_INST_PREFIX/ssl/include" 

	pypy3_pip install --upgrade h2 #https://github.com/python-hyper/hyper-h2/archive/master.zip
	pypy3_pip install --upgrade urllib3 dnspython pyDNS # dnslib  hypertable
	pypy3_pip install --upgrade https://github.com/eventlet/eventlet/archive/v0.19.0.zip # https://github.com/eventlet/eventlet/archive/master.zip #eventlet

	pypy3_pip install --upgrade msgpack-python
	pypy3_pip install --upgrade Wand
	pypy3_pip install --upgrade weasyprint                 
	pypy3_pip install --upgrade pylzma rarfile  #zipfile pysnappy
	pypy3_pip install --upgrade guess_language validate-email-address
	pypy3_pip install --upgrade paypalrestsdk #pygeocoder python-google-places
	pypy3_pip install --upgrade acme

	pypy3_pip install --upgrade https://github.com/kashirin-alex/libpyhdfs/archive/master.zip

fi

