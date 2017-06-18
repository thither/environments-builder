#!/usr/bin/env bash
if [ ! -f $CUST_INST_PREFIX/bin/openssl ]; then
	apt-get autoremove --purge -y openssl ca-certificates
fi
fn='openssl-1.1.0f.tar.gz'; tn='openssl-1.1.0f'; url='http://www.openssl.org/source/openssl-1.1.0f.tar.gz';
set_source 'tar' 
./config  enable-md2 enable-rc5 enable-ssl3 enable-ssl3-method threads zlib zlib-dynamic shared enable-weak-ssl-ciphers enable-ec_nistp_64_gcc_128 --prefix=$CUST_INST_PREFIX;#  enable-ubsan  enable-asan enable-egd   --openssldir=$CUST_INST_PREFIX/ssl --prefix=$CUST_INST_PREFIX/ssl;
make;make install;make all; 
if [ -f $CUST_INST_PREFIX/bin/openssl ]; then
	rm -r $CUST_INST_PREFIX/ssl/certs /etc/ssl/certs;mkdir /etc/ssl/certs;
	wget --no-check-certificate -O certs.pem http://curl.haxx.se/ca/cacert-2017-01-18.pem; #https://curl.haxx.se/docs/caextract.html 
	mv certs.pem /etc/ssl/certs/certs.pem
	ln -s /etc/ssl/certs $CUST_INST_PREFIX/ssl/certs;
	echo "#!/usr/bin/env bash" > $ENV_SETTINGS_PATH/$sn.sh
	echo "export SSL_CERT_DIR=\"/etc/ssl/certs\"" >> $ENV_SETTINGS_PATH/$sn.sh
	echo "export SSL_CERT_FILE=\"/etc/ssl/certs/certs.pem\"" >> $ENV_SETTINGS_PATH/$sn.sh
	echo "export CURL_CA_BUNDLE=\"/etc/ssl/certs/certs.pem\"" >> $ENV_SETTINGS_PATH/$sn.sh
	
fi
#sctp - https://sourceforge.net/projects/lksctp/files/lksctp-tools/lksctp-tools-1.0.17.tar.gz/download