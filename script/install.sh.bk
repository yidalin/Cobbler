# Install cobbler in CentOS 7.3

logfile='./history.log'

os_info=$(cat /etc/redhat-release)
distribution=$(echo ${os_info} | awk -F" " '{ print $1 }')
distribution_version=$(echo $os_info | awk -F" " '{ print $4 }' | awk -F"." '{ print $1}')

cobbler_server='172.16.0.103'
tftp_server='172.16.0.103'

echo -e "\n>> OS Information <<"
echo -e "OS: ${os_info}"
echo -e "Distribution: $distribution"
echo -e "Distribution Version: $distribution_version"

cobbler_server='172.16.0.103'
tftp_server='172.16.0.103'

echo -e "\n>> Bacis Setting <<"
echo -e "Cobbler Server: $cobbler_server"
echo -e "TFTP Server: $tftp_server"

# Checking the distribution, it should be CentOS
if [ "$distribution" == 'CentOS' ]; then
    echo ">> Good, the OS is CentOS."
else
    echo ">> The OS is not CentOS, bye bye."
    exit
fi

# Checking the distribution version, it should be 7
if [ "$distribution_version" == '7' ]; then
    echo ">> Good, the distribution version is 7." 
else
    echo ">> The distribution version is not 7, bye bye."
    exit
fi

echo -e ""

# Checking the SELinux setting
if [ "$(getenforce)" = 'Enforcing' ]; then
    sed -in 's/SELINUX=enforcing/SELINUX=permissive/' /etc/selinux/config
    setenforce 0
    echo ">> SELinux is in enforcing mode, now switch to permissive mode." 
else
    echo ">> SELinux is already in permissive mode." 
fi

# Checking the network can reach to internet

ping -c 2 8.8.8.8 > /dev/null

echo -e "" 

if [ $? != '0' ]; then
    echo ">> Please make sure your network is workable." 
    exit
else
    echo ">> OK, keep going." 
fi

echo -e "\n>> Installing repository: epel-release"
yum install -y epel-release

echo -e "\n>> Installing Cobbler package and its dependency packages"
yum install -y cobbler cobbler-web dhcp xinetd tftp-server python-ctypes pykickstart fence-agents

echo -e "\n>> Enable and start Cobbler service and Apache service"
systemctl enable cobblerd.service
systemctl enable httpd.service
systemctl start cobblerd.service
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
