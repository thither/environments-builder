#!/usr/bin/env bash
tn='Python-2.7.16'; url='http://www.python.org/ftp/python/2.7.16/Python-2.7.16.tar.xz';
set_source 'tar';
if [ $only_dw == 1 ];then return;fi

if [ ! -f $CUST_INST_PREFIX/bin/python ]; then
	rm_os_pkg $sn;
	if [[ $os_r == 'openSUSE' ]];then
		echo "#!/usr/bin/env bash" > $ENV_SETTINGS_PATH/$sn.sh
		echo "export PYTHONHOME=\"$CUST_INST_PREFIX\"" >> $ENV_SETTINGS_PATH/$sn.sh
		source /etc/profile;source ~/.bashrc;ldconfig;
	fi
fi
config_dest;`src_path`/configure CFLAGS="-P $ADD_O_FS" CPPFLAGS="-P $ADD_O_FS" \
				--with-wctype-functions --with-system-expat --with-system-ffi --with-ensurepip=install --with-dbmliborder=bdb:gdbm:ndbm:                \
				--with-computed-gotos --with-lto --with-signal-module --with-pth --with-pymalloc --with-fpectl                \
				--enable-shared --enable-unicode=ucs4 --enable-optimizations --enable-ipv6           \
				--prefix=$CUST_INST_PREFIX --target=`_build`; 
do_make build_all;do_make install;
source /etc/profile;source ~/.bashrc;ldconfig;

export VERBOSE=1;
export LDFLAGS="-DTCMALLOC_MINIMAL -ltcmalloc_minimal -fno-builtin-malloc -fno-builtin-calloc -fno-builtin-realloc -fno-builtin-free"
export CFLAGS="$ADD_O_FS $LDFLAGS -DNDEBUG"
export CPPFLAGS="$ADD_O_FS $LDFLAGS"
export INCLUDEDIRS="-I$CUST_INST_PREFIX/include"

if [ -f $CUST_INST_PREFIX/bin/pip ] && [ $stage -ne 0 ]; then
	ln -s $CUST_INST_PREFIX/bin/python /usr/bin/python;
	if [ $stage -eq 3 ]; then
		pip uninstall -y cffi greenlet psutil deepdiff xlrd lxml pycrypto cryptography pyopenssl pycparser h2 urllib3 dnspython \
						 eventlet msgpack-python Wand weasyprint pylzma rarfile guess_language paypalrestsdk josepy acme pyhdfs
	fi
	rm -rf ~/.cache/pip 

	./pip_install.sh pythonsetuptools
	./pip_install.sh pythonpip
	./pip_install.sh pythonsetuptools

	./pip_install.sh python cffi 
	./pip_install.sh python greenlet
	./pip_install.sh python psutil deepdiff
	./pip_install.sh python xlrd lxml	
	./pip_install.sh python pycrypto 
	./pip_install.sh python cryptography
	./pip_install.sh python pyopenssl #LDFLAGS="-L$CUST_INST_PREFIX/ssl/lib" CFLAGS="-I$CUST_INST_PREFIX/ssl/include" 
	./pip_install.sh python pycryptodomex
	./pip_install.sh python pycparser
	
	./pip_install.sh python h2 #https://github.com/python-hyper/hyper-h2/archive/master.zip
	./pip_install.sh python urllib3 dnspython
   	./pip_install.sh pythonlinuxfd http://github.com/kashirin-alex/eventlet/archive/master.zip 

	./pip_install.sh python msgpack-python
	./pip_install.sh python webp Pillow Wand
	./pip_install.sh python weasyprint==0.42.3                 
	./pip_install.sh python brotli pylzma rarfile  #zipfile pysnappy
	./pip_install.sh pythonply slimit

	./pip_install.sh python guess_language
	./pip_install.sh python paypalrestsdk #pygeocoder python-google-places
	./pip_install.sh python josepy acme
	./pip_install.sh pythonfontTools

	./pip_install.sh pythonhttp://github.com/kashirin-alex/libpyhdfs/archive/master.zip
	./pip_install.sh pythonhttp://github.com/kashirin-alex/PyHelpers/archive/master.zip

	
	#./pip_install.sh pythonninja;
	#./pip_install.sh pythonhttp://chromium.googlesource.com/external/gyp/+archive/master.tar.gz;
	./pip_install.sh pythonCython
fi

export LDFLAGS=""
export CFLAGS=""
export CPPFLAGS=""
export INCLUDEDIRS=""