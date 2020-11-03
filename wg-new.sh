#!/bin/bash

cd wg-quick
./easy-wg-quick

systemctl restart wg-quick@wghub
wg show

SEQNO=$(cat seqno.txt)
CURRENT=$((SEQNO-1))
qrencode -o "wgclient_$CURRENT.png" < "wgclient_$CURRENT.conf"
