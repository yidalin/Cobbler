## Install cobbler in CentOS 7.3

# Pre-defined variables
cobbler_server='172.16.0.103'
tftp_server='172.16.0.103'
selinux_mode='disabled'
new_root_password='password'

# Stop firewalld during installation
echo -e "\n>> Stopping firewalld"
systemctl stop firewalld.service
echo -e " >> The firewalld status:"
systemctl status firewalld.service | head -n 3 | tail -n 2

# Checking the SELinux setting
echo -e "\n>> Checking the SELinux setting"
if [ "$(getenforce)" = 'Enforcing' ]; then
    sed -in "s/SELINUX=enforcing/SELINUX=${selinux_mode}/" /etc/selinux/config
    setenforce 0
    echo " >> SELinux is in enforcing mode, now switch to permissive mode." 
else
    echo " >> SELinux mode: $(getenforce)" 
fi

# setsebool -P httpd_can_network_connect true

# Installing the EPEL repo
echo -e "\n>> Installing repository: epel-release"
#https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
yum install -y epel-release

# Installing the Cobbler and its dependency packages
echo -e "\n>> Installing Cobbler package and its dependency packages"
yum install -y cobbler cobbler-web httpd rsync tftp-server xinetd dhcp python-ctypes debmirror pykickstart cman fence-agents dnsmasq

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

echo -e "\n>> Installing debmirror for install Debian OS"
yum install -y debmirror

echo -e "\n>> Changing /etc/debmirror.conf (Only needed when install Debian OS)"
sed -i 's/@dists="sid";/#@dists="sid";/g' /etc/debmirror.conf
sed -i 's/@arches="i386";/#@arches="i386";/g' /etc/debmirror.conf

root_password_old=$(grep default_password_crypted /etc/cobbler/settings | awk '{ print$2 }')
root_password_new=$(openssl passwd -1 -salt 'salt' $new_root_password)
echo -e "\n>> Replacing the default root password"
sed -i "s|$root_password_old|$root_password_new|g" /etc/cobbler/settings

# Enable and start rsync and xineted
echo -e "\n>> Enable rsync and xinetd, also start them."
systemctl enable rsyncd.service
systemctl enable xinetd.service
systemctl enable httpd.service
systemctl enable cobblerd.service

systemctl start rsyncd.service
systemctl start xinetd.service
systemctl start httpd.service
systemctl start cobblerd.service
exit
echo -e "\n>> Get the loaders again"
cobbler get-loaders

echo -e "\n>> Restarting Cobbler service..."
systemctl restart cobblerd.service

echo -e "\n>> Syncing Cobbler settings"
cobbler sync

cobbler_check=$(cobbler check | tee /dev/tty)
echo -e "\n>> Check the prerequisites..."
if [ "$cobbler_check" != 'No configuration problems found.  All systems go.' ]; then
    echo -e "\n>> Please check the prerequisites of Cobbler"
    exit
fi
