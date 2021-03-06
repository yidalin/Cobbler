## Install cobbler in CentOS 7.3

# Pre-defined variables
cobbler_server='172.16.0.100'
tftp_server='172.16.0.100'
selinux_mode='disabled'
new_root_password='password'

DHCP_NETWORK='172.16.0.0'
DHCP_SUBNETMASK='255.255.255.0'
DHCP_GATEWAY='192.168.0.1'
DHCP_DNS='192.168.0.1'
DHCP_RELEASE_START='172.16.0.201'
DHCP_RELEASE_END='172.16.0.210'
DHCP_LISTEN_INTERFASE="enp0s8"

# Stop firewalld during installation
echo -e "\n>> Stopping firewalld"
systemctl stop firewalld.service

echo -e "\n>> The firewalld status:"
systemctl status firewalld.service | head -n 3 | tail -n 2


# Checking the SELinux setting
echo -e "\n>> Checking the SELinux setting"
if [ "$(getenforce)" = 'Enforcing' ]; then
    sed -in "s/SELINUX=enforcing/SELINUX=${selinux_mode}/" /etc/selinux/config
    echo " >> SELinux is in $(getenforce) mode, now switch to ${selinux_mode} mode."
    sleep 3
    reboot
else
    echo " >> SELinux mode: $(getenforce)" 
fi

# setsebool -P httpd_can_network_connect true

# Installing the EPEL repo
echo -e "\n>> Installing repository: epel-release"
yum install -y epel-release

# Installing the Cobbler and its dependency packages
echo -e "\n>> Installing Cobbler package and its dependency packages"
yum install -y cobbler cobbler-web httpd tftp-server rsync dhcp debmirror pykickstart cman fence-agents
#yum install -y cobbler cobbler-web httpd rsync tftp-server xinetd dhcp python-ctypes debmirror pykickstart cman fence-agents dnsmasq

echo -e "\n>> Enable services: httpd, cobblerd"
systemctl enable httpd.service
systemctl enable cobblerd.service

echo -e "\n>> Start services: httpd, cobblerd"
systemctl start httpd.service
systemctl start cobblerd.service

# Check Cobbler environment
echo -e "\n>> Checking the Cobbler environment"
cobbler check

# Replacing some variables or parameters of the Cobbler setting file
echo -e "\n>> Replacing some parameter of cobbler setting."
echo -e " >> Switching the listening IP to $cobbler_server"
sed -i "s/server: 127.0.0.1/server: $cobbler_server/g" /etc/cobbler/settings

echo -e " >> Switching the next_server (PXE) IP to $tftp_server"
sed -i "s/next_server: 127.0.0.1/next_server: $tftp_server/g" /etc/cobbler/settings

# Turn on the TFTP service (xinted)
echo -e "\n>> Turn on the TFTP service."
grep -l 'disable' /etc/xinetd.d/tftp | xargs -i sed -i 's/yes/no/g' {}

# Enable and start tftp.socket
echo -e "\n>> Enable and start the tftp.socket"
systemctl enable tftp.socket
systemctl start tftp.socket

# Restart httpd and cobblerd
echo -e "\n>> Restart httpd and cobblerd"
systemctl restart httpd.service
systemctl restart cobblerd.service

# Sync cobbler setting
echo -e "\nSynchronizing the cobbler setting"
cobbler sync

# Check Cobbler service
echo -e "\nChecking the Cobbler service"
cobbler check

# Download boot loaders
echo -e "\n>> Downloading boot loaders"
cobbler get-loaders

# Enable and restart rsync service
echo -e "\n>> Enable and restart rsync service"
systemctl enable rsyncd.service
systemctl start rsyncd.service

echo -e "\n>> Changing /etc/debmirror.conf (Only needed when install Debian OS)"
sed -i 's/@dists="sid";/#@dists="sid";/g' /etc/debmirror.conf
sed -i 's/@arches="i386";/#@arches="i386";/g' /etc/debmirror.conf

root_password_old=$(grep default_password_crypted /etc/cobbler/settings | awk '{ print$2 }')
root_password_new=$(openssl passwd -1 -salt 'salt' $new_root_password)
echo -e "\n>> Replacing the default root password"
sed -i "s|$root_password_old|$root_password_new|g" /etc/cobbler/settings

systemctl restart cobblerd.service

cobbler sync

cobbler_check=$(cobbler check | tee /dev/tty)
echo -e "\n>> Check the prerequisites..."
if [ "$cobbler_check" != 'No configuration problems found.  All systems go.' ]; then
    echo -e "\n>> Please check the prerequisites of Cobbler"
fi

echo -e "\n>> Use Cobbler to manage dhcp config."
sed -i 's/manage_dhcp: 0/manage_dhcp: 1/g' /etc/cobbler/settings

echo -e "\n>> Changing some setting within the dhcp.template"
mv -f /etc/cobbler/dhcp.template /etc/cobbler/dhcp.template.bk

echo -e "\n>> Replacing the /etc/cobbler/dhcp.tempate with the dhcp.template"
cp -av ./dhcp.template /etc/cobbler/dhcp.template

echo -e "\n>> Replacing some DHCP setting"
sed -i "s/DHCP_NETWORK/$DHCP_NETWORK/g" /etc/cobbler/dhcp.template
sed -i "s/DHCP_SUBNETMASK/$DHCP_SUBNETMASK/g" /etc/cobbler/dhcp.template
sed -i "s/DHCP_GATEWAY/$DHCP_GATEWAY/g" /etc/cobbler/dhcp.template
sed -i "s/DHCP_DNS/$DHCP_DNS/g" /etc/cobbler/dhcp.template
sed -i "s/DHCP_RELEASE_START/$DHCP_RELEASE_START/g" /etc/cobbler/dhcp.template
sed -i "s/DHCP_RELEASE_END/$DHCP_RELEASE_END/g" /etc/cobbler/dhcp.template

#echo -e "\n>> Change listen interface"
#echo "DHCPDARGS=\"$DHCPListenInterface\";" >> /etc/sysconfig/dhcpd

echo -e "\n>> Syncing Cobbler settings."
cobbler sync && cobbler sync

sleep 2

echo -e "\n>> Restart DHCP service"
systemctl restart dhcpd.service

sleep 2

echo -e "\n>> Restart Cobblerd"
systemctl restart cobblerd.service

obbler_check=$(cobbler check | tee /dev/tty)
echo -e "\n>> Check the prerequisites..."
if [ "$cobbler_check" != 'No configuration problems found.  All systems go.' ]; then
    echo -e "\n>> Please check the prerequisites of Cobbler"
    exit
fi
