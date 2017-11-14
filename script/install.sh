## Install cobbler in CentOS 7.3

# Pre-defined variables
cobbler_server='172.16.0.103'
tftp_server='172.16.0.103'
selinux_mode='permissive'

# Checking the SELinux setting
echo -e ">> Checking the SELinux setting"
if [ "$(getenforce)" = 'Enforcing' ]; then
    sed -in "s/SELINUX=enforcing/SELINUX=${selinux_mode}/" /etc/selinux/config
    setenforce 0
    echo ">> SELinux is in enforcing mode, now switch to permissive mode." 
else
    echo ">> SELinux mode: $(getenforce)" 
fi

# Installing the EPEL repo
echo -e "\n>> Installing repository: epel-release"
wget https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm /tmp
rpm -ivh /tmp/epel-release-latest-7.noarch.rpm
#yum install -y epel-release
exit

# Installing the Cobbler and its dependency packages
echo -e "\n>> Installing Cobbler package and its dependency packages"
yum install -y cobbler cobbler-web httpd rsync tftp-server xinetd dhcp python-ctypes debmirror pykickstart cman fence-agents dnsmasq

# Enable and start the Cobbler service and Apache service 
echo -e "\n>> Enable and start Cobbler service and Apache service"
systemctl enable cobblerd.service
systemctl start cobblerd.service

systemctl enable httpd.service
systemctl start httpd.service

# Cobbler get loaders
echo -e "\n>> Run command: cobbler get-loaders"
cobbler get-loaders

# Replacing some variables or parameters of the Cobbler setting file
echo -e "\n>> Replacing some parameter of cobbler setting."

echo -e ">> Set the listening IP to $cobbler_server"
sed -i "s/server: 127.0.0.1/server: $cobbler_server/g" /etc/cobbler/settings

echo -e ">> Set the next_server (PXE) IP to $tftp_server"
sed -i "s/next_server: 127.0.0.1/next_server: $tftp_server/g" /etc/cobbler/settings

# Make Cobbler manage rsync service
echo -e "\n>> Make Cobbler can manage rsync service."
sed -i 's/manage_rsync: 0/manage_rsync: 1/g' /etc/cobbler/settings

# Make Cobbler manage DHCP service
echo -e "\n>> Make Cobbler can manage DHCP service."
sed -i 's/manage_dhcp: 0/manage_dhcp: 1/g' /etc/cobbler/settings

# Turn on the TFTP service (xinted)
echo -e "\n>> Turn on the TFTP service."
grep -l 'disable' /etc/xinetd.d/tftp | xargs -i sed -i 's/yes/no/g' {}

# Enable and start rsync and xineted
echo -e "\n>> Enable rsync and xinetd, also start them."
systemctl enable rsyncd.service
systemctl enable xinetd.service
systemctl start rsyncd.service
systemctl start xinetd.service

exit

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
