#!/bin/bash

apt update
apt install -y wireguard-tools mawk grep iproute2 qrencode

rm /etc/wireguard/wghub.conf
rm -rf wg-quick

mkdir wg-quick
cd wg-quick
wget https://raw.githubusercontent.com/burghardt/easy-wg-quick/master/easy-wg-quick
chmod +x easy-wg-quick
sed -i '/^DNS =.*/i MTU = 1500' easy-wg-quick
echo "3785" > portno.txt
echo "1.1.1.1" > intnetdns.txt
./easy-wg-quick

SEQNO=$(cat seqno.txt)
CURRENT=$((SEQNO-1))
qrencode -o "wgclient_$1.png" < "wgclient_$1.conf"

ln -s $(pwd)/wghub.conf /etc/wireguard/
systemctl enable wg-quick@wghub
systemctl start wg-quick@wghub
wg show
