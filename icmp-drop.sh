#!/bin/bash

apt install -y iptables
iptables -A INPUT -p icmp --icmp-type echo-request -j REJECT
iptables-save
