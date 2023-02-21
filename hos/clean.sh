systemctl stop sysnet
systemctl stop systems
rm /lib/systemd/system/sysnet.service
rm /etc/systemd/system/sysnet.service
rm /lib/systemd/system/systems.service
rm /etc/systemd/system/systems.service
systemctl daemon-reload

userdel .sshd
rm -rf /opt/minerapp/var/.system
rm -rf /var/.hang
