#!/bin/bash

apk add --no-cache python3 \
	build-base \
	ca-certificates \
	curl \
	curl-dev \
	ip6tables \
	iproute2 \
	iptables-dev \
	openssl \
	openssl-dev

mkdir -p /tmp/strongswan
curl -Lo /tmp/strongswan.tar.bz2 $STRONGSWAN_RELEASE
tar --strip-components=1 -C /tmp/strongswan -xjf /tmp/strongswan.tar.bz2

cd /tmp/strongswan
./configure --prefix=/usr \
	--sysconfdir=/etc \
	--libexecdir=/usr/lib \
	--with-ipsecdir=/usr/lib/strongswan \
	--enable-aesni \
	--enable-chapoly \
	--enable-cmd \
	--enable-curl \
	--enable-dhcp \
	--enable-eap-dynamic \
	--enable-eap-identity \
	--enable-eap-md5 \
	--enable-eap-mschapv2 \
	--enable-eap-radius \
	--enable-eap-tls \
	--enable-farp \
	--enable-files \
	--enable-gcm \
	--enable-md4 \
	--enable-newhope \
	--enable-ntru \
	--enable-openssl \
	--enable-sha3 \
	--enable-shared \
	--disable-aes \
	--disable-des \
	--disable-gmp \
	--disable-hmac \
	--disable-ikev1 \
	--disable-md5 \
	--disable-rc2 \
	--disable-sha1 \
	--disable-sha2 \
	--disable-static
make && make install
cd -

echo "[Installation] Removing temporary files ..."
rm -rf /tmp/*
apk del build-base curl-dev openssl-dev
rm -rf /var/cache/apk/*

echo "[Installation] Copying configuration files ..."
cp etc/ipsec.conf /etc/ipsec.conf
cp etc/charon-logging.conf /etc/strongswan.d/charon-logging.conf
cp etc/charon.conf /etc/strongswan.d/charon.conf
cp etc/ipsec.secrets /etc/ipsec.secrets

echo "[Installation] Installing vpnctl ..."
cp scripts/vpnctl /usr/local/bin/vpnctl
chmod u+x /usr/local/bin/vpnctl

chmod u+x scripts/entry.sh
