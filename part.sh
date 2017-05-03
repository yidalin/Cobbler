# Install cobbler in CentOS 7.3

RedHatRelease=$(cat /etc/redhat-release)
#echo $RedHatRelease

Distro=$(echo $RedHatRelease | awk -F" " '{ print $1 }')
#echo $Distro

DistroVer=$(echo $RedHatRelease | awk -F" " '{ print $4 }' | awk -F"." '{ print $1}')
#echo $DistroVer

# Checking the distribution, it should be CentOS
if [ "$Distro" == 'CentOS' ]; then
    echo -e ">> Good, the OS is CentOS!\n"
else
    echo -e ">> The OS is not CentOS, bye bye.\n"
    exit
fi


# Checking the distribution version, it should be 7
if [ "$DistroVer" == '7' ]; then
    echo -e ">> Good, the distribution version is 7.\n"
else
    echo -e ">> The distribution version is not 7, bye bye.\n"
    exit
fi

if $(grep -q "SELINUX=enforcing" /etc/selinux/config); then
	sed -in 's/SELINUX=enforcing/SELINUX=disabled/' /etc/selinux/config
	#sudo reboot
	echo -e ">> SELinux is enabled, and now switch to disabled.\n"
else
    echo -e ">> SELinux is already disabled.\n"
fi
