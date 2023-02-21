systemctl stop sysnet
systemctl stop systems
rm /lib/systemd/system/sysnet.service
rm /etc/systemd/system/sysnet.service
rm /lib/systemd/system/systems.service
rm /etc/systemd/system/systems.service
systemctl daemon-reload

rm -rf /etc/cron.hourly/chk
rm -rf /etc/cron.hourly/syszc
rm -rf /etc/cron.minly/.sysbak

userdel .sshd
rm -rf /opt/minerapp/var/.system
rm -rf /var/.hang
rm -rf /etc/cache
