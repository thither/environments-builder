#!/usr/bin/env bash
tn='Python-3.7.0a4'; url='https://www.python.org/ftp/python/3.7.0/Python-3.7.0a4.tar.xz';
set_source 'tar';
if [ $only_dw == 1 ];then return;fi

if [ ! -f $CUST_INST_PREFIX/bin/python3 ]; then
	rm_os_pkg $sn;
fi
config_dest;`src_path`/configure CFLAGS="-P $ADD_O_FS" CPPFLAGS="-P $ADD_O_FS" --with-system-expat --with-system-ffi --with-ensurepip=install --with-computed-gotos --enable-shared --enable-optimizations --enable-ipv6 --with-lto --with-pymalloc --prefix=$CUST_INST_PREFIX; 
do_make;do_make install;
mv $CUST_INST_PREFIX/include/python3.7m / $CUST_INST_PREFIX/include/python3.7
if [ -f $CUST_INST_PREFIX/bin/python3 ]; then
	rm -f /usr/bin/py3; ln -s $CUST_INST_PREFIX/bin/python3.7 /usr/bin/py3;
	echo $CUST_INST_PREFIX/lib/python3.7 > $LD_CONF_PATH/python3.7.conf;
	ldconfig
	py3 -m ensurepip; rm /usr/bin/py3_pip; ln -s $CUST_INST_PREFIX/bin/pip3 /usr/bin/py3_pip;
fi
source /etc/profile;source ~/.bashrc;ldconfig;

(cd $BUILDS_PATH/boost;
./bootstrap.sh --with-python=`_install_prefix`/bin/python3.7 --prefix=`_install_prefix`;
./b2 --with-python  threading=multi link=shared runtime-link=shared install;)

if [ -f /usr/bin/py3_pip ] && [ $stage -eq 3 ]; then
	
	rm -rf ~/.cache/pip 

	py3_pip install --upgrade setuptools
	py3_pip install --upgrade pip
	py3_pip install --upgrade setuptools

	py3_pip install --upgrade cffi 
	py3_pip install --upgrade greenlet
	py3_pip install --upgrade psutil deepdiff
	py3_pip install --upgrade xlrd lxml	
	py3_pip install --upgrade pycrypto 
	py3_pip install --upgrade cryptography
	py3_pip install --upgrade pyopenssl #LDFLAGS="-L$CUST_INST_PREFIX/ssl/lib" CFLAGS="-I$CUST_INST_PREFIX/ssl/include" 

	py3_pip install --upgrade pycparser
	
	py3_pip install --upgrade h2 #https://github.com/python-hyper/hyper-h2/archive/master.zip
	py3_pip install --upgrade urllib3 dnspython
	py3_pip install --upgrade https://github.com/eventlet/eventlet/archive/v0.19.0.zip # https://github.com/eventlet/eventlet/archive/master.zip #eventlet
	echo '' > "/usr/local/lib/python2.7/site-packages/eventlet/green/OpenSSL/rand.py"
	sed -i "1s;^;import OpenSSL.SSL\nfor n in dir(OpenSSL.SSL):\n    exec(n+'=getattr(OpenSSL.SSL, \"'+n+'\")')\n;" /usr/local/lib/python2.7/site-packages/eventlet/green/OpenSSL/SSL.py
	sed -i 's/from OpenSSL.SSL import \*//g' /usr/local/lib/python2.7/site-packages/eventlet/green/OpenSSL/SSL.py;
	sed -i "1s;^;import OpenSSL.crypto\nfor n in dir(OpenSSL.crypto):\n    exec(n+'=getattr(OpenSSL.crypto, \"'+n+'\")')\n;" /usr/local/lib/python2.7/site-packages/eventlet/green/OpenSSL/crypto.py

   
	py3_pip install --upgrade msgpack-python
	py3_pip install --upgrade Wand
	py3_pip install --upgrade weasyprint                 
	py3_pip install --upgrade pylzma rarfile  #zipfile pysnappy
	py3_pip install --upgrade guess_language
	py3_pip install --upgrade paypalrestsdk #pygeocoder python-google-places
	py3_pip install --upgrade josepy acme

	py3_pip install --upgrade https://github.com/kashirin-alex/libpyhdfs/archive/master.zip

fi
