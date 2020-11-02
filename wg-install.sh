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
./easy-wg-quick

ln -s $(pwd)/wghub.conf /etc/wireguard/
systemctl enable wg-quick@wghub
systemctl start wg-quick@wghub
wg show
