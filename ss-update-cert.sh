#!/bin/bash

iptables -D INPUT -p tcp --dport 80 -j DROP

certbot certonly -d $DOMAIN --cert-name ss --quiet --webroot -w /var/www/letsencrypt/
systemctl reload nginx

iptables -A INPUT -p tcp --dport 80 -j DROP
iptables-save
