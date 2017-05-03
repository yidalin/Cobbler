# Install cobbler in CentOS 7.3

RedHatRelease=$(cat /etc/redhat-release)
echo $RedHatRelease

Ditro=$(echo $RedHatRelease | awk -F" " '{ print $1 }')
echo $Ditro

DistroVer=$(echo $RedHatRelease | awk -F" " '{ print $4 }' | awk -F"." '{ print $1}')
echo $DistroVer

if [ $DistroVer == '6' ]; then
    echo 'it is 7'
else
    echo 'it is not 7'
    exit
fi

if $(grep -q "SELINUX=enforcing" /etc/selinux/config); then
	sed -in 's/SELINUX=enforcing/SELINUX=disabled/' /etc/selinux/config
	#sudo reboot
	echo 'SELinux is enabled'
else
    echo 'Keep going'
fi
