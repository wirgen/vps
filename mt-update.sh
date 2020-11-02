#!/bin/bash

cd /etc/mtproto-proxy
curl -s https://core.telegram.org/getProxySecret -o proxy-secret
curl -s https://core.telegram.org/getProxyConfig -o proxy-multi.conf

systemctl restart mtproto-proxy
