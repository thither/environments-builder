#!/usr/bin/env bash
tn='openssl-1.1.0g'; url='http://www.openssl.org/source/openssl-1.1.0g.tar.gz';
set_source 'tar';
if [ ! -f $CUST_INST_PREFIX/bin/openssl ]; then
	if [[ $os_r == 'Ubuntu' ]];then
		apt-get autoremove -yq --purge openssl ca-certificates
	elif [ $os_r == 'openSUSE'] && [ $stage == 1 ];then
		echo 'possible? zypper rm -y openssl ca-certificates';
	fi
fi
./config disable-msan disable-ubsan disable-asan disable-egd enable-md2 enable-rc5 enable-ssl3 enable-ssl3-method enable-weak-ssl-ciphers threads zlib zlib-dynamic shared enable-ec_nistp_64_gcc_128 --prefix=$CUST_INST_PREFIX;#  -DPEDANTIC -pedantic enable-ssl-trace  enable-ripemd  enable-blake2 --openssldir=$CUST_INST_PREFIX/ssl --prefix=$CUST_INST_PREFIX/ssl;
do_make;do_make install;do_make all; 
if [ -f $CUST_INST_PREFIX/bin/openssl ]; then
	rm -r $CUST_INST_PREFIX/ssl/certs /etc/ssl/certs;mkdir -p /etc/ssl/certs;
	wget --no-check-certificate -O /etc/ssl/certs/certs.pem https://curl.haxx.se/ca/cacert.pem; #https://curl.haxx.se/docs/caextract.html 

	ln -s /etc/ssl/certs $CUST_INST_PREFIX/ssl/certs;
	echo "#!/usr/bin/env bash" > $ENV_SETTINGS_PATH/$sn.sh
	echo "export SSL_CERT_DIR=\"/etc/ssl/certs\"" >> $ENV_SETTINGS_PATH/$sn.sh
	echo "export SSL_CERT_FILE=\"/etc/ssl/certs/certs.pem\"" >> $ENV_SETTINGS_PATH/$sn.sh
	echo "export CURL_CA_BUNDLE=\"/etc/ssl/certs/certs.pem\"" >> $ENV_SETTINGS_PATH/$sn.sh
	
fi
#sctp - https://sourceforge.net/projects/lksctp/files/lksctp-tools/lksctp-tools-1.0.17.tar.gz/download