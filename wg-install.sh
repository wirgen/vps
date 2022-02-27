#!/bin/bash

apt update
apt install -y wireguard-tools mawk grep iproute2 qrencode

PORT=3785
DNS="8.8.8.8"
MTU=1500

rm /etc/wireguard/wghub.conf
rm -rf wg-quick

mkdir wg-quick
cd wg-quick
wget https://raw.githubusercontent.com/burghardt/easy-wg-quick/master/easy-wg-quick
chmod +x easy-wg-quick
sed -i "/^DNS =.*/i MTU = $MTU" easy-wg-quick
echo $PORT > portno.txt
echo $DNS > intnetdns.txt
echo $MTU > intnetmtu.txt
./easy-wg-quick

ln -s $(pwd)/wghub.conf /etc/wireguard/
systemctl enable wg-quick@wghub
systemctl start wg-quick@wghub
wg show

SEQNO=$(cat seqno.txt)
CURRENT=$((SEQNO-1))
qrencode -o "wgclient_$CURRENT.png" < "wgclient_$CURRENT.conf"
