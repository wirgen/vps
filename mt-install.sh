#!/bin/bash

apt update
apt install -y git curl build-essential libssl-dev zlib1g-dev qrencode

PORT=8443

DIR=$(pwd)

rm -rf MTProxy
git clone https://github.com/TelegramMessenger/MTProxy.git
cd MTProxy/
make

cp objs/bin/mtproto-proxy /usr/bin/
chmod 777 /usr/bin/mtproto-proxy
cd /etc
rm -rf mtproto-proxy
mkdir mtproto-proxy
cd mtproto-proxy
curl -s https://core.telegram.org/getProxySecret -o proxy-secret
curl -s https://core.telegram.org/getProxyConfig -o proxy-multi.conf

IP=$(wget -qO- ipinfo.io/ip)
SECRET=$(head -c 16 /dev/urandom | xxd -ps)

cat > "/etc/systemd/system/mtproto-proxy.service" << EOF
[Unit]
Description=MTProxy
After=network.target
[Service]
ExecStart=/usr/bin/mtproto-proxy -u nobody -p 6419 -H $PORT -S $SECRET --aes-pwd /etc/mtproto-proxy/proxy-secret /etc/mtproto-proxy/proxy-multi.conf -M 1
Restart=on-failure
[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl start mtproto-proxy
systemctl enable mtproto-proxy

cd $DIR

cp -f mt-update.sh /etc/cron.daily/

qrencode -o mt.png "tg://proxy?server=$IP&port=$PORT&secret=$SECRET"
qrencode -t ansiutf8 "tg://proxy?server=$IP&port=$PORT&secret=$SECRET"
echo "With DD in secret"
qrencode -o mtdd.png "tg://proxy?server=$IP&port=$PORT&secret=dd$SECRET"
qrencode -t ansiutf8 "tg://proxy?server=$IP&port=$PORT&secret=dd$SECRET"
echo "IP: $IP"
echo "PORT: $PORT"
echo "SECRET: $SECRET"
