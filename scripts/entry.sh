#!/bin/bash

if [ ! -d $PKIDIR ]; then
    mkdir -p $PKIDIR
fi
chmod 700 $PKIDIR

cd $PKIDIR

echo "[Entry] Creating a certificate authority ..."
if [ ! -f "ca-key.pem" -o ! -f "ca-cert.pem" ]; then
	rm -f server-key.pem
	rm -f server-cert.pem
	ipsec pki --gen --size 4096 --outform pem > ca-key.pem
	ipsec pki --self --ca --lifetime 3650 --in ca-key.pem --type rsa --dn "C=CN, O=$ORGANIZATION, CN=$CA_NAME" --outform pem > ca-cert.pem
	echo "[Entry]    - DN: C=CN, O=$ORGANIZATION, CN=$CA_NAME"
fi

echo "[Entry] Generating a certificate for the VPN server ..."
if [ ! -f "server-key.pem" -o ! -f "server-cert.pem" ]; then
	ipsec pki --gen --size 4096 --outform pem > server-key.pem
	ipsec pki --pub --in server-key.pem --type rsa > server-pub.pem
	ipsec pki --issue --lifetime 3650 \
		--cacert ca-cert.pem \
		--cakey ca-key.pem \
		--in server-pub.pem \
		--dn "C=CN, O=$ORGANIZATION, CN=$HOST" \
		--san $HOST \
		--flag serverAuth \
		--flag ikeIntermediate \
		--outform pem  > server-cert.pem
	rm -f server-pub.pem
	echo "[Entry]    - DN: C=CN, O=$ORGANIZATION, CN=$HOST"
	echo "[Entry]    - HOST: $HOST"
fi

echo "[Entry] Replacing tags in configuration file ..."
sed -i "s/{host}/$HOST/g" /etc/ipsec.conf

echo "[Entry] Installing certificates ..."
cp ca-key.pem /etc/ipsec.d/private/ca-key.pem
cp ca-cert.pem /etc/ipsec.d/cacerts/ca-cert.pem
cp server-key.pem /etc/ipsec.d/private/server-key.pem
cp server-cert.pem /etc/ipsec.d/certs/server-cert.pem

echo "[Entry] Initializing iptables ..."
iptables -A INPUT -i lo -j ACCEPT
iptables -A INPUT -p udp --dport 500 -j ACCEPT
iptables -A INPUT -p udp --dport 4500 -j ACCEPT
iptables -A FORWARD --match policy --pol ipsec --dir in --proto esp -s 10.10.10.0/24 -j ACCEPT
iptables -A FORWARD --match policy --pol ipsec --dir out --proto esp -d 10.10.10.0/24 -j ACCEPT
iptables -t nat -A POSTROUTING -s 10.10.10.0/24 -m policy --pol ipsec --dir out -j ACCEPT
iptables -t nat -A POSTROUTING -s 10.10.10.0/24 -j MASQUERADE
iptables -t mangle -A FORWARD -m policy --pol ipsec --dir in -p tcp -m tcp --tcp-flags SYN,RST SYN -m tcpmss --mss 1361:1536 -j TCPMSS --set-mss 1360
iptables -t mangle -A FORWARD -m policy --pol ipsec --dir out -p tcp -m tcp --tcp-flags SYN,RST SYN -m tcpmss --mss 1361:1536 -j TCPMSS --set-mss 1360

echo "[Entry] Starting IPsec ..."
ipsec start --nofork
