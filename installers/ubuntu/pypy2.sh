#!/usr/bin/env bash
pip install --upgrade pycparser
fn='pypy2-v5.7.1-src.tar.bz2'; tn='pypy2-v5.7.1-src'; url='https://bitbucket.org/pypy/pypy/downloads/pypy2-v5.7.1-src.tar.bz2';
set_source 'tar';

#make LDFLAGS="-L$CUST_INST_PREFIX/ssl/lib" CFLAGS="-I$CUST_INST_PREFIX/ssl/include" all;
cd pypy;
LDFLAGS="-L$CUST_INST_PREFIX/ssl/lib" CFLAGS="-I$CUST_INST_PREFIX/ssl/include" python ../rpython/bin/rpython  --source --shared --opt=jit goal/targetpypystandalone.py #  --no-shared --thread
mkdir pypy2;cd pypy2;
LDFLAGS="-L$CUST_INST_PREFIX/ssl/lib" CFLAGS="-I$CUST_INST_PREFIX/ssl/include" ../pypy-c ../../rpython/bin/rpython --gc=boehm --thread --shared --opt=jit ../goal/targetpypystandalone.py
PYTHONPATH=../ ./pypy-c ../tool/build_cffi_imports.py

python tool/release/package.py --without-tk --archive-name pypy2 --targetdir $DOWNLOAD_PATH/pypy2.tar.bz2
cd $BUILTS_PATH;tar -xf $DOWNLOAD_PATH/pypy2.tar.bz2;
rm -r /opt/pypy2;mv pypy2 /opt/;
rm /usr/bin/pypy; ln -s /opt/pypy2/bin/pypy /usr/bin/pypy
rm /usr/bin/pypy-stm; ln -s /opt/pypy2/bin/pypy-stm /usr/bin/pypy-stm
pypy -m ensurepip; rm /usr/bin/pypy_pip; ln -s /opt/pypy2/bin/pip /usr/bin/pypy_pip
ldconfig

rm -r ~/.cache/pip 
pypy_pip install --upgrade setuptools
pypy_pip install --upgrade pip
pypy_pip install --upgrade setuptools

pypy_pip install --upgrade cffi greenlet
pypy_pip install --upgrade psutil deepdiff
pypy_pip install --upgrade xlrd lxml
LDFLAGS="-L$CUST_INST_PREFIX/ssl/lib" CFLAGS="-I$CUST_INST_PREFIX/ssl/include" pypy_pip install --upgrade pyopenssl 
with_gmp=no pypy_pip install --upgrade  pycrypto 

pypy_pip install --upgrade hypertable h2 urllib3 dnspython pyDNS # dnslib 
pypy_pip install --upgrade https://github.com/eventlet/eventlet/archive/v0.19.0.tar.gz #eventlet

pypy_pip install --upgrade Wand
pypy_pip install --upgrade weasyprint                 
pypy_pip install --upgrade pylzma rarfile pysnappy  #zipfile
pypy_pip install --upgrade guess_language validate-email-address
pypy_pip install --upgrade paypalrestsdk pygeocoder python-google-places

cd $DOWNLOAD_PATH
wget  https://github.com/crs4/pydoop/archive/1.2.0.tar.gz
tar -zxvf 1.2.0.tar.gz
mv pydoop-1.2.0/pydoop  /opt/pypy2/site-packages/
#JAVA_HOME="/usr/lib/jvm/java-8-openjdk-amd64" HADOOP_CONF_DIR='/opt/hadoop/current/etc/hadoop/' HADOOP_VERSION='2.7.2' pypy_pip install --upgrade https://github.com/crs4/pydoop/archive/1.2.0.tar.gz



#PYTHONPATH=../.. ./pypy-c ../tool/build_cffi_imports.py
#pypy ../../rpython/bin/rpython --opt=jit --shared --gc=boehm --thread --backendopt --jit-backend=x86-without-sse2

#
