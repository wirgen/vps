#!/bin/bash

cd wg-quick
./easy-wg-quick

SEQNO=$(cat seqno.txt)
CURRENT=$((SEQNO-1))
qrencode -o "wgclient_$CURRENT.png" < "wgclient_$CURRENT.conf"

systemctl restart wg-quick@wghub
wg show
