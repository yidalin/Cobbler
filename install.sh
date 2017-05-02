# Install cobbler in CentOS 7.3

if $(grep -q "SELINUX=enforcing" /etc/selinux/config); then
	sed -in 's/SELINUX=enforcing/SELINUX=disabled/' /etc/selinux/config
	sudo reboot
else
    echo 'Keep going';
fi

yum install -y epel-release
yum install -y vim bind-utils
yum install -y httpd dhcp tftp-server python-ctypes cobbler cobbler-web pykickstart fence-agents xinetd

systemctl enable cobblerd.service
systemctl enable httpd.service
systemctl start cobblerd.service
systemctl start httpd.service

setenforce 0

cobbler get-loaders

cobbler check

CobblerServer='192.168.0.103'
TFTPServer='192.168.0.103'
sed -i "s/server: 127.0.0.1/server: $CobblerServer/g" /etc/cobbler/settings
sed -i "s/next_server: 127.0.0.1/next_server: $TFTPServer/g" /etc/cobbler/settings

grep -l 'disable' /etc/xinetd.d/tftp | xargs -i sed -i 's/yes/no/g' {}

systemctl start rsyncd.service
systemctl start xinetd.service
systemctl enable rsyncd.service
systemctl enable xinetd.service
ss -tnulp | grep xinetd

yum install -y debmirror

sed -i 's/@dists="sid";/#@dists="sid";/g' /etc/debmirror.conf
sed -i 's/@arches="i386";/#@arches="i386";/g' /etc/debmirror.conf

OldPassword=$(grep default_password_crypted /etc/cobbler/settings | awk '{print$2}')
CobblerPassword=$(openssl passwd -1 -salt 'cobbler-salt' 'cobbler')
sed -i "s|$OldPassword|\"$CobblerPassword\"|g" /etc/cobbler/settings

systemctl restart cobblerd
cobbler sync
cobbler check

