# Install cobbler in CentOS 7.3

if $(grep -q "SELINUX=enforcing" /etc/selinux/config); then
	sed -in 's/SELINUX=enforcing/SELINUX=disabled/' /etc/selinux/config
	sudo reboot
else
    echo 'Keep going';
fi