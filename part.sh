# Install cobbler in CentOS 7.3

RedHatRelease=$(cat /etc/redhat-release)
echo $RedHatRelease

if $(grep -q "SELINUX=enforcing" /etc/selinux/config); then
	sed -in 's/SELINUX=enforcing/SELINUX=disabled/' /etc/selinux/config
	#sudo reboot
	echo 'SELinux is enabled'
else
    echo 'Keep going'
fi
