# Install cobbler in CentOS 7.3

cobbler_server='172.16.0.103'
tftp_server='172.16.0.103'
selinux_mode='permissive'

# Checking the SELinux setting
if [ "$(getenforce)" = 'Enforcing' ]; then
    sed -in "s/SELINUX=enforcing/SELINUX=${selinux_mode}/" /etc/selinux/config
    setenforce 0
    echo ">> SELinux is in enforcing mode, now switch to permissive mode." 
else
    echo ">> SELinux mode: $(getenforce)" 
fi

exit

echo -e "\n>> Installing repository: epel-release"
yum install -y epel-release

echo -e "\n>> Installing Cobbler package and its dependency packages"
yum install -y cobbler cobbler-web httpd rsync tftp-server xinetd dhcp python-ctypes debmirror pykickstart cman fence-agents dnsmasq

echo -e "\n>> Enable and start Cobbler service and Apache service"
systemctl enable cobblerd.service
systemctl start cobblerd.service
systemctl enable httpd.service
systemctl start httpd.service

echo -e "\n>> Run command: cobbler get-loaders"
cobbler get-loaders

echo -e "\n>> Replacing some parameter of cobbler setting."
sed -i "s/server: 127.0.0.1/server: $cobbler_server/g" /etc/cobbler/settings
sed -i "s/next_server: 127.0.0.1/next_server: $tftp_server/g" /etc/cobbler/settings

echo -e "\n>> Turn on the TFTP service."
grep -l 'disable' /etc/xinetd.d/tftp | xargs -i sed -i 's/yes/no/g' {}

echo -e "\n>> Enable rsync and xinetd, also start them."
systemctl enable rsyncd.service
systemctl enable xinetd.service
systemctl start rsyncd.service
systemctl start xinetd.service

echo -e "\n>> Installing debmirror for install Debian OS"
yum install -y debmirror

echo -e "\n>> Changing /etc/debmirror.conf (Only needed when install Debian OS)"
sed -i 's/@dists="sid";/#@dists="sid";/g' /etc/debmirror.conf
sed -i 's/@arches="i386";/#@arches="i386";/g' /etc/debmirror.conf

OldCobblerPassword=$(grep default_password_crypted /etc/cobbler/settings | awk '{ print$2 }')
NewCobblerPassword=$(openssl passwd -1 -salt 'salt' 'cobbler')
echo -e "\n>> Replacing the default root password"
sed -i "s|$OldCobblerPassword|$NewCobblerPassword|g" /etc/cobbler/settings

echo -e "\n>> Get the loaders again"
cobbler get-loaders

echo -e "\n>> Restarting Cobbler service..."
systemctl restart cobblerd.service

echo -e "\n>> Syncing Cobbler settings"
cobbler sync

echo -e "\n>> Check the prerequisites..."
CobblerCheck=$(cobbler check | tee /dev/tty)

if [ "$CobblerCheck" != 'No configuration problems found.  All systems go.' ]; then
    echo -e "\n>> Please check the prerequisites of Cobbler"
    exit
fi
