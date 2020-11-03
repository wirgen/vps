#!/bin/bash

apt update
apt install -y shadowsocks-libev certbot wget nginx qrencode iptables

DOMAIN="example.com"
FAILOVER_URL="https://google.com"
SECRET=$(head -c 32 /dev/urandom | xxd -ps -c 32)
METHOD="xchacha20-ietf-poly1305"
DNS="1.1.1.1"
ACME_EMAIL="admin@example.com"

DIR=$(pwd)

cat > "/etc/shadowsocks-libev/config.json" << EOF
{
"server": ["::1", "127.0.0.1"],
"server_port": 8001,
"password": "$SECRET",
"timeout": 300,
"method": "$METHOD",
"no_delay": true,
"fast_open": true,
"reuse_port": true,
"workers": 1,
"plugin": "v2ray-plugin",
"nameserver": "$DNS",
"plugin_opts": "server;loglevel=none",
"mode": "tcp_only"
}
EOF

if ! grep -Fxq "# Shadowsocks" /etc/sysctl.conf ; then
  cat >> "/etc/sysctl.conf" << EOF
# Shadowsocks
net.ipv6.conf.all.accept_ra = 2

kernel.sysrq=0
vm.swappiness=0
kernel.core_uses_pid=1
kernel.randomize_va_space=1
kernel.msgmnb=65536
kernel.msgmax=65536
net.core.default_qdisc=fq
net.ipv4.tcp_congestion_control=bbr
net.ipv4.tcp_notsent_lowat = 16384
net.ipv4.tcp_syncookies=0
net.ipv4.ip_forward = 0
net.ipv4.conf.all.accept_source_route=0
net.ipv4.conf.default.accept_source_route=0
net.ipv4.conf.all.accept_redirects=0
net.ipv4.conf.default.accept_redirects=0
net.ipv4.conf.all.send_redirects=0
net.ipv4.conf.default.send_redirects=0
net.ipv4.conf.all.rp_filter=1
net.ipv4.conf.default.rp_filter=1
net.ipv4.conf.all.arp_ignore = 1
net.ipv4.conf.default.arp_ignore = 1
net.ipv4.icmp_echo_ignore_all=1
net.ipv4.icmp_echo_ignore_broadcasts=1
net.ipv4.icmp_ignore_bogus_error_responses=1
net.ipv4.conf.all.secure_redirects=0
net.ipv4.conf.default.secure_redirects=0
net.ipv4.conf.all.secure_redirects=0
net.ipv4.conf.default.secure_redirects=0

fs.file-max = 131072
net.core.rmem_max = 8388608
net.core.wmem_max = 8388608
net.core.rmem_default = 8388608
net.core.wmem_default = 8388608
net.core.optmem_max = 8388608
net.core.netdev_max_backlog = 131072
net.core.somaxconn = 131072
net.ipv4.ip_local_port_range = 1024 65535
net.ipv4.tcp_mem = 25600 51200 102400
net.ipv4.tcp_rmem = 4096 1048576 4194304
net.ipv4.tcp_wmem = 4096 1048576 4194304
net.ipv4.tcp_fastopen=3
net.ipv4.tcp_low_latency = 1
net.ipv4.tcp_no_metrics_save = 1
net.ipv4.tcp_adv_win_scale = 1
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_timestamps = 0
net.ipv4.tcp_fin_timeout = 30
net.ipv4.tcp_window_scaling = 1
net.ipv4.tcp_keepalive_time = 150
net.ipv4.tcp_keepalive_probes = 5
net.ipv4.tcp_keepalive_intvl = 30
net.ipv4.tcp_synack_retries = 1
net.ipv4.tcp_slow_start_after_idle=0
net.ipv4.tcp_max_syn_backlog = 65536
net.ipv4.tcp_max_tw_buckets = 720000
net.ipv4.tcp_mtu_probing = 1
EOF

  sysctl -p
fi

cd /usr/local/bin
rm -rf v2ray-plugin
wget https://github.com/shadowsocks/v2ray-plugin/releases/download/v1.3.1/v2ray-plugin-linux-amd64-v1.3.1.tar.gz
tar zxf v2ray-plugin-linux-amd64-v1.3.1.tar.gz
rm v2ray-plugin-linux-amd64-v1.3.1.tar.gz
mv v2ray-plugin_linux_amd64 v2ray-plugin
setcap 'cap_net_bind_service=+eip' v2ray-plugin

if ! grep -Fxq "# Shadowsocks" /etc/security/limits.conf ; then
  cat >> "/etc/security/limits.conf" << EOF
# Shadowsocks
* soft nofile 131072
* hard nofile 131072
EOF

  ulimit -n 131072
fi

if ! grep -Fxq "# Shadowsocks" /etc/pam.d/common-session ; then
  cat >> "/etc/pam.d/common-session" << EOF
# Shadowsocks
session required pam_limits.so
EOF
fi

mkdir -p /var/www/letsencrypt

cat > "/etc/nginx/sites-available/default" << EOF
server {
    server_name $DOMAIN;
    listen 80;
    listen [::]:80;

    location ^~ /.well-known/acme-challenge/ {
        auth_basic off;
        alias /var/www/letsencrypt/.well-known/acme-challenge/;
    }

    location / {
        return 301 https://\$host\$request_uri;
    }

    access_log off;
}
EOF

systemctl enable nginx && systemctl restart nginx

certbot register --agree-tos --email $ACME_EMAIL --no-eff-email
certbot certonly -d $DOMAIN --cert-name ss --quiet --webroot -w /var/www/letsencrypt/

cat >> "/etc/nginx/sites-available/default" << EOF
server {
    server_name $DOMAIN;
    listen 443 ssl http2 reuseport backlog=131072 fastopen=256;
    listen [::]:443 ssl http2 reuseport backlog=131072 fastopen=256;

    add_header Allow "GET" always;
    if ( \$request_method !~ ^(GET)$ ) {
        return 444;
    }

    ssl_certificate "/etc/letsencrypt/live/ss/fullchain.pem";
    ssl_certificate_key "/etc/letsencrypt/live/ss/privkey.pem";

    add_header Content-Security-Policy "default-src https: data: 'unsafe-inline' 'unsafe-eval'" always;
    add_header Strict-Transport-Security "max-age=31536000; preload" always;
    add_header X-Robots-Tag "noindex, nofollow" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Xss-Protection "1; mode=block" always;

    location / {
        proxy_pass $FAILOVER_URL;
        limit_rate 1000k;
        proxy_redirect off;
    }

    location /ss1 {
        proxy_redirect off;
        proxy_buffering off;
        proxy_http_version 1.1;
        proxy_pass http://localhost:8001/;
        proxy_set_header Host \$http_host;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
    }

    access_log off;
}
EOF

systemctl restart nginx
systemctl enable shadowsocks-libev.service && systemctl restart shadowsocks-libev

iptables -A INPUT -p tcp --dport 80 -j REJECT
iptables-save

cd $DIR

cp -f ss-update-cert.sh /etc/cron.monthly/

URL="ss://`echo -n "$METHOD:$SECRET" | base64 -w 0`@$DOMAIN:443?plugin=v2ray-plugin%3Bpath%3D%2Fss1%3Bloglevel%3Derror%3Bhost%3D$DOMAIN%3Btls"

qrencode -o ss.png $URL
qrencode -t ansiutf8 $URL

echo "DOMAIN: $DOMAIN"
echo "PORT: 443"
echo "SECRET: $SECRET"
echo "METHOD: $METHOD"
