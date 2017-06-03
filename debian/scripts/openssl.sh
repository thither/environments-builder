#!/usr/bin/env bash
fn='openssl-1.1.0f.tar.gz'; tn='openssl-1.1.0f'; url='https://ftp.openssl.org/source/openssl-1.1.0f.tar.gz';
set_source 'tar' 
./config enable-ssl3 enable-ssl3-method enable-threads enable-zlib enable-zlib-dynamic enable-shared enable-ec_nistp_64_gcc_128 enable-weak-ssl-ciphers  --prefix=$CUST_INST_PREFIX;#--openssldir=$CUST_INST_PREFIX/ssl --prefix=$CUST_INST_PREFIX/ssl;
make;make install;make all; 
if [ -f $CUST_INST_PREFIX/bin/openssl ]; then
	if [ -f /usr/bin/openssl ]; then
		if [ ! -f /usr/bin/openssl_older ]; then
			mv /usr/bin/openssl /usr/bin/openssl_older;
			update-alternatives --install /usr/bin/openssl openssl $CUST_INST_PREFIX/bin/openssl 60
		fi
	fi
	rm -r $CUST_INST_PREFIX/ssl/certs;
	sudo apt-get install -y --reinstall ca-certificates
	ln -s /etc/ssl/certs $CUST_INST_PREFIX/ssl/certs;
	echo "#!/usr/bin/env bash" > $ENV_SETTINGS_PATH/$sn.sh
	echo "export SSL_CERT_DIR=\"/etc/ssl/certs\"" >> $ENV_SETTINGS_PATH/$sn.sh
fi