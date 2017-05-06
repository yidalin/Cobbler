# Install cobbler in CentOS 7.3

RedHatRelease=$(cat /etc/redhat-release)
#echo $RedHatRelease

Distro=$(echo $RedHatRelease | awk -F" " '{ print $1 }')
#echo $Distro

DistroVer=$(echo $RedHatRelease | awk -F" " '{ print $4 }' | awk -F"." '{ print $1}')
#echo $DistroVer

CobblerServer=$(hostname -I)
TFTPServer=$(hostname -I)

# Checking the distribution, it should be CentOS
if [ "$Distro" == 'CentOS' ]; then
    echo -e "\n>> Good, the OS is CentOS!"
else
    echo -e "\n>> The OS is not CentOS, bye bye."
    exit
fi

# Checking the distribution version, it should be 7
if [ "$DistroVer" == '7' ]; then
    echo -e "\n>> Good, the distribution version is 7."
else
    echo -e "\n>> The distribution version is not 7, bye bye."
    exit
fi

# Checking the SELinux setting
if $(grep -q "SELINUX=enforcing" /etc/selinux/config); then
    sed -in 's/SELINUX=enforcing/SELINUX=disabled/' /etc/selinux/config
    echo -e "\n>> SELinux is enabled, and now switch to disabled, the OS will reboot in 30 second."
    sleep 10
    sudo reboot
else
    echo -e "\n>> SELinux is already disabled."
fi

# Checking the network can reach to internet

ping -c 2 8.8.8.8 > /dev/null

if [ $? != '0' ]; then
    echo -e "\n>> Please make sure your network is workable."
    exit
else
    echo -e "\n>> OK, keep going."
fi

echo -e "\n>> Installing repository: epel-release"
#sleep 3
yum install -y epel-release

echo -e "\n>> Installing Cobbler package and its dependency packages"
#sleep 3
yum install -y cobbler cobbler-web dhcp xinetd tftp-server python-ctypes pykickstart fence-agents

echo -e "\n>> Enable and start Cobbler service and Apache service"
systemctl enable cobblerd.service
systemctl enable httpd.service
systemctl start cobblerd.service
systemctl start httpd.service

echo -e "\n>> Run command: cobbler get-loaders"
cobbler get-loaders

echo -e "\n>> Replacing some parameter of cobbler setting."
sed -i "s/server: 127.0.0.1/server: $CobblerServer/g" /etc/cobbler/settings
sed -i "s/next_server: 127.0.0.1/next_server: $TFTPServer/g" /etc/cobbler/settings

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

echo -e "\n>> Restarting Cobbler service..."
systemctl restart cobblerd.service
sleep 1

echo -e "\n>> Syncing Cobbler settings"
cobbler sync

echo -e "\n>> Check the prerequisites..."
CobblerCheck=$(cobbler check | tee /dev/tty)

if [ "$CobblerCheck" != 'No configuration problems found.  All systems go.' ]; then
    echo -e "\n>> Please check the prerequisites of Cobbler"
    exit
fi
