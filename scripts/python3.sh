#!/usr/bin/env bash
tn='Python-3.7.0a2'; url='https://www.python.org/ftp/python/3.7.0/Python-3.7.0a2.tar.xz';
set_source 'tar';
if [ ! -f $CUST_INST_PREFIX/bin/python3 ]; then
	if [[ $os_r == 'Ubuntu' ]];then
		apt-get autoremove -yq --purge python3
	elif [ $os_r == 'openSUSE'] && [ $stage == 1 ];then
		echo 'possible? zypper rm -y python3';
	fi
fi
configure_build  --with-system-expat --with-system-ffi --enable-unicode --with-ensurepip=install --with-computed-gotos --enable-shared --enable-optimizations --enable-ipv6 --with-lto  --with-signal-module  --with-pth --with-pymalloc --with-fpectl  --prefix=$CUST_INST_PREFIX;   #
do_make;do_make install;
if [ -f $CUST_INST_PREFIX/bin/python3 ]; then
	rm /usr/bin/py3; ln -s $CUST_INST_PREFIX/bin/python3 /usr/bin/py3;
	echo $CUST_INST_PREFIX/lib/python3 > $LD_CONF_PATH/python3.conf;
	py3 -m ensurepip; rm /usr/bin/py3_pip; ln -s $CUST_INST_PREFIX/bin/pip3 /usr/bin/py3_pip;
fi

ldconfig
if [ -f $CUST_INST_PREFIX/bin/py3_pip ]; then
	
	rm -r ~/.cache/pip 

	py3_pip install --upgrade setuptools
	py3_pip install --upgrade pip
	py3_pip install --upgrade setuptools
	py3_pip install --upgrade pycparser
	py3_pip install --upgrade thrift

	py3_pip install --upgrade cffi greenlet
	py3_pip install --upgrade psutil deepdiff
	py3_pip install --upgrade xlrd lxml
	py3_pip install --upgrade pycrypto
	py3_pip install --upgrade cryptography 
	py3_pip install --upgrade pyopenssl

	py3_pip install --upgrade h2 urllib3 dnspython  # pyDNS dnslib  hypertable
	py3_pip install --upgrade https://github.com/eventlet/eventlet/archive/master.zip  #https://github.com/eventlet/eventlet/archive/v0.19.0.tar.gz #eventlet

	
	py3_pip install --upgrade msgpack-python
	py3_pip install --upgrade Wand
	py3_pip install --upgrade weasyprint                 
	py3_pip install --upgrade pylzma rarfile  #zipfile pysnappy
	py3_pip install --upgrade guess_language validate-email-address
	py3_pip install --upgrade paypalrestsdk # pygeocoder python-google-places
	py3_pip install --upgrade acme

	py3_pip install --upgrade https://github.com/kashirin-alex/libpyhdfs/archive/master.zip


fi

