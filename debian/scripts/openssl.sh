#!/usr/bin/env bash
fn='openssl-1.0.2l.tar.gz'; tn='openssl-1.0.2l'; url='ftp://ftp.pca.dfn.de/pub/tools/net/openssl/source/openssl-1.0.2l.tar.gz';
set_source 'tar' 
./config enable-ssl3 enable-ssl3-method enable-threads enable-zlib enable-zlib-dynamic enable-shared enable-ec_nistp_64_gcc_128 enable-weak-ssl-ciphers  --prefix=$CUST_INST_PREFIX;#--openssldir=$CUST_INST_PREFIX/ssl --prefix=$CUST_INST_PREFIX/ssl;
make;make install;make all; 
if [ -f $CUST_INST_PREFIX/bin/openssl ]; then
	if [ -f /usr/bin/openssl ]; then
		apt-get autoremove --purge openssl ca-certificates
		if [ ! -f /usr/bin/openssl_older ]; then
			mv /usr/bin/openssl /usr/bin/openssl_older;
		fi			
	fi
	rm -r $CUST_INST_PREFIX/ssl/certs /etc/ssl/certs;mkdir /etc/ssl/certs;
	wget --no-check-certificate -O certs.pem http://curl.haxx.se/ca/cacert-2017-01-18.pem; #https://curl.haxx.se/docs/caextract.html 
	mv certs.pem /etc/ssl/certs/certs.pem
	ln -s /etc/ssl/certs $CUST_INST_PREFIX/ssl/certs;
	echo "#!/usr/bin/env bash" > $ENV_SETTINGS_PATH/$sn.sh
	echo "export SSL_CERT_DIR=\"/etc/ssl/certs\"" >> $ENV_SETTINGS_PATH/$sn.sh
	echo "export SSL_CERT_FILE=\"/etc/ssl/certs/certs.pem\"" >> $ENV_SETTINGS_PATH/$sn.sh
	echo "export CURL_CA_BUNDLE=\"/etc/ssl/certs/certs.pem\"" >> $ENV_SETTINGS_PATH/$sn.sh
	
fi