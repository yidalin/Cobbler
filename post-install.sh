echo -e "\n>> Use Cobbler to manage dhcp config."
sed -i 's/manage_dhcp: 0/manage_dhcp: 1/g' /etc/cobbler/settings

DHCPSubnet='192.168.0.0'
DHCPNetmask='255.255.255.0'
DHCPGateway='192.168.0.1'
DHCP_DNS='192.168.0.100'
DHCPReleaseStart='192.168.0.200'
DHCPReleaseEnd='192.168.0.220'


sed -i "s/RELEASE_SUBNET/$DHCPSubnet/g" dhcp.template
sed -i "s/SUBNET_MASK/$DHCPNetmask/g" dhcp.template
sed -i "s/GATEWAY/$DHCPGateway/g" dhcp.template
sed -i "s/DNS/$DHCP_DNS/g" dhcp.template
sed -i "s/RELEASE_START/$DHCPReleaseStart/g" dhcp.template
sed -i "s/RELEASE_END/$DHCPReleaseEnd/g" dhcp.template

echo -e ">> \nChanging some setting within the dhcp.template"
mv /etc/cobbler/dhcp.template /etc/cobbler/dhcp.template.bk

echo -e "\n>> Replacing the /etc/cobbler/dhcp.tempate with the dhcp.template"
cp  ./dhcp.template /etc/cobbler/dhcp.template

echo -e "\nSyncing Cobbler settings."
cobbler sync 

echo -e "\nRestarting dhcp service..."
systemctl restart dhcpd.service

echo -e "\nRestarting Cobbler service..."
systemctl restart cobblerd.service
