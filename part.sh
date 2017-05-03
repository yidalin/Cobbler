# Install cobbler in CentOS 7.3

RedHatRelease=$(cat /etc/redhat-release)
echo $RedHatRelease

Distro=$(echo $RedHatRelease | awk -F" " '{ print $1 }')
echo $Distro

DistroVer=$(echo $RedHatRelease | awk -F" " '{ print $4 }' | awk -F"." '{ print $1}')
echo $DistroVer

# Checking the distribution, it should be CentOS
if [ "$Distro" == 'CentOS' ]; then
    echo 'Good, the OS is CentOS!'
else
    echo 'The OS is not CentOS, bye bye.'
    exit
fi


# Checking the distribution version, it should be 7
if [ "$DistroVer" == '7' ]; then
    echo 'Good, the distribution version is 7.'
else
    echo 'The distribution version is not 7, bye bye.'
    exit
fi

if $(grep -q "SELINUX=enforcing" /etc/selinux/config); then
	sed -in 's/SELINUX=enforcing/SELINUX=disabled/' /etc/selinux/config
	#sudo reboot
	echo 'SELinux is enabled, and now switch to disabled.'
else
    echo 'SELinux is already disabled.'
fi
