# Disable connect to ssh
iptables -A INPUT -p tcp --dport 22 -j DROP

# Save iptables rules
echo iptables-persistent iptables-persistent/autosave_v4 boolean true | debconf-set-selections
echo iptables-persistent iptables-persistent/autosave_v6 boolean true | debconf-set-selections
apt -y install iptables-persistent

# Disable sudo for all users
mv -f /etc/sudoers{,.bak}
rm -f /etc/sudoers.d/*
