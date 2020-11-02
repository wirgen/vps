#!/bin/bash

cd wg-quick
./easy-wg-quick

systemctl restart wg-quick@wghub
wg show
