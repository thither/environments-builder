#!/usr/bin/env bash
if [ ! -f $CUST_INST_PREFIX/bin/python ]; then
	apt-get autoremove --purge python2.7
fi
fn='Python-2.7.13.tgz'; tn='Python-2.7.13'; url='https://www.python.org/ftp/python/2.7.13/Python-2.7.13.tgz';
set_source 'tar' 
configure_build --with-system-expat --enable-unicode --with-ensurepip=install --with-computed-gotos --enable-shared --enable-optimizations --enable-ipv6 --with-lto  --with-system-ffi  --with-signal-module   --with-pth --with-pymalloc --with-fpectl  --prefix=$CUST_INST_PREFIX;   #
make;make install;make all;
if [ -f $CUST_INST_PREFIX/bin/python ]; then
	echo /usr/local/include/python2.7 > $LD_CONF_PATH/python.conf
fi
ldconfig
if [ -f $CUST_INST_PREFIX/bin/pip ]; then
	rm -r ~/.cache/pip 
	pip install --upgrade thrift

	pip install --upgrade setuptools
	pip install --upgrade pip
	pip install --upgrade setuptools
	pip install --upgrade pycparser

	pip install --upgrade cffi greenlet
	pip install --upgrade psutil deepdiff
	pip install --upgrade xlrd lxml
	pip install --upgrade pyopenssl
	pip install --upgrade pycrypto 

	pip install --upgrade h2 urllib3 dnspython pyDNS # dnslib  hypertable
	pip install --upgrade https://github.com/eventlet/eventlet/archive/v0.19.0.tar.gz #eventlet

	pip install --upgrade Wand
	pip install --upgrade weasyprint                 
	pip install --upgrade pylzma rarfile pysnappy  #zipfile
	pip install --upgrade guess_language validate-email-address
	pip install --upgrade paypalrestsdk pygeocoder python-google-places

	cd $DOWNLOAD_PATH
	wget  https://github.com/crs4/pydoop/archive/1.2.0.tar.gz
	tar -zxvf 1.2.0.tar.gz
	mv pydoop-1.2.0/pydoop  $CUST_INST_PREFIX/lib/python2.7/site-packages/
	# pip install --upgrade pydoop #https://github.com/crs4/pydoop/archive/1.2.0.tar.gz

fi

