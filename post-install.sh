echo -e "\n>> Use Cobbler to manage dhcp config."
sed -i 's/manage_dhcp: 0/manage_dhcp: 1/g' /etc/cobbler/settings

DHCPSubnet='192.168.0.0'
DHCPNetmask='255.255.255.0'
DHCPGateway='192.168.0.1'
DHCP_DNS='192.168.0.100'
DHCPReleaseStart='192.168.0.200'
DHCPReleaseEnd='192.168.0.220'


sed -i "s/192.168.1.0/$DHCPSubnet/g" dhcp.template
sed -i "s/255.255.255.0/$DHCPNetmask/g" dhcp.template
sed -i "s/192.168.1.5/$DHCPGateway/g" dhcp.template
sed -i "s/192.168.1.1/$DHCP_DNS/g" dhcp.template
sed -i "s/192.168.1.100/$DHCPReleaseStart/g" dhcp.template
sed -i "s/192.168.1.254/$DHCPReleaseEnd/g" dhcp.template

exit

echo -e "\nSyncing Cobbler settings."
cobbler sync 

echo -e "\nRestarting dhcp service..."
systemctl restart dhcpd.service

echo -e "\nRestarting Cobbler service..."
systemctl restart cobblerd.service
