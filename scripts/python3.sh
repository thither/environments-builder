#!/usr/bin/env bash
tn='Python-3.8.0a3'; url='http://www.python.org/ftp/python/3.8.0/Python-3.8.0a3.tar.xz';
set_source 'tar';
if [ $only_dw == 1 ];then return;fi

# if [ ! -f $CUST_INST_PREFIX/bin/python3 ]; then
	#rm_os_pkg $sn;
# fi
config_dest;`src_path`/configure CFLAGS="-P $ADD_O_FS" CPPFLAGS="-P $ADD_O_FS" \
				--with-system-expat --with-system-ffi --with-ensurepip=install --with-computed-gotos 
				--enable-shared --enable-optimizations --enable-ipv6 --with-lto --with-pymalloc --prefix=$CUST_INST_PREFIX; 
do_make build_all;do_make install;
mv $CUST_INST_PREFIX/include/python3.8m / $CUST_INST_PREFIX/include/python3.8
if [ -f $CUST_INST_PREFIX/bin/python3 ]; then
	rm -f /usr/bin/py3; ln -s $CUST_INST_PREFIX/bin/python3.8 /usr/bin/py3;
	echo $CUST_INST_PREFIX/lib/python3.8 > $LD_CONF_PATH/python3.8.conf;
	ldconfig
	py3 -m ensurepip; rm /usr/bin/py3_pip; ln -s $CUST_INST_PREFIX/bin/pip3 /usr/bin/py3_pip;
fi
source /etc/profile;source ~/.bashrc;ldconfig;

(cd $SOURCES_PATH/boost;
./bootstrap.sh --with-python=`_install_prefix`/bin/python3.8 --prefix=`_install_prefix`;
./b2 --with-python  threading=multi link=shared runtime-link=shared install;)

export VERBOSE=1;
export LDFLAGS="-DTCMALLOC_MINIMAL -ltcmalloc_minimal -fno-builtin-malloc -fno-builtin-calloc -fno-builtin-realloc -fno-builtin-free"
export CFLAGS="$ADD_O_FS $LDFLAGS -DNDEBUG"
export CPPFLAGS="$ADD_O_FS $LDFLAGS"
export INCLUDEDIRS="-I$CUST_INST_PREFIX/include"

if [ -f /usr/bin/py3_pip ] && [ $stage -ne 0 ]; then
	
	rm -rf ~/.cache/pip 

	py3_pip install --upgrade --verbose setuptools
	py3_pip install --upgrade --verbose pip
	py3_pip install --upgrade --verbose setuptools

	py3_pip install --upgrade --verbose cffi 
	py3_pip install --upgrade --verbose greenlet
	py3_pip install --upgrade --verbose psutil deepdiff
	py3_pip install --upgrade --verbose xlrd lxml	
	py3_pip install --upgrade --verbose pycrypto 
	py3_pip install --upgrade --verbose cryptography
	py3_pip install --upgrade --verbose pyopenssl #LDFLAGS="-L$CUST_INST_PREFIX/ssl/lib" CFLAGS="-I$CUST_INST_PREFIX/ssl/include" 
	py3_pip install --upgrade --verbose pycryptodomex
	
	py3_pip install --upgrade --verbose pycparser
	
	py3_pip install --upgrade --verbose h2 #https://github.com/python-hyper/hyper-h2/archive/master.zip
	py3_pip install --upgrade --verbose urllib3 dnspython
	py3_pip install --upgrade --verbose linuxfd http://github.com/kashirin-alex/eventlet/archive/master.zip 
   
	py3_pip install --upgrade --verbose msgpack-python
	py3_pip install --upgrade --verbose  webp Pillow Wand
	py3_pip install --upgrade --verbose  weasyprint                 
	py3_pip install --upgrade --verbose  brotli pylzma rarfile  #zipfile pysnappy
	py3_pip install --upgrade --verbose ply slimit
	py3_pip install --upgrade --verbose guess_language
	py3_pip install --upgrade --verbose paypalrestsdk #pygeocoder python-google-places
	py3_pip install --upgrade --verbose josepy acme
	py3_pip install --upgrade --verbose fontTools

	py3_pip install --upgrade --verbose http://github.com/kashirin-alex/libpyhdfs/archive/master.zip
	py3_pip install --upgrade --verbose http://github.com/kashirin-alex/PyHelpers/archive/master.zip

fi

export LDFLAGS=""
export CFLAGS=""
export CPPFLAGS=""
export INCLUDEDIRS=""