#!/bin/bash

apt install -y iptables iptables-persistent
dpkg-reconfigure iptables-persistent
