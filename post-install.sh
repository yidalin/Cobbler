echo -e "\n>> Use Cobbler to manage dhcp config."
sed -i 's/manage_dhcp: 0/manage_dhcp: 1/g' /etc/cobbler/settings

DHCPSubnet='172.16.0.0'
DHCPNetmask='255.255.255.0'
DHCPGateway='172.16.0.1'
DHCP_DNS='172.16.0.100'
DHCPReleaseStart='172.16.0.200'
DHCPReleaseEnd='172.16.0.220'
DHCPListenInterface="ens19"

sed -i "s/RELEASE_SUBNET/$DHCPSubnet/g" dhcp.template
sed -i "s/SUBNET_MASK/$DHCPNetmask/g" dhcp.template
sed -i "s/GATEWAY/$DHCPGateway/g" dhcp.template
sed -i "s/DNS/$DHCP_DNS/g" dhcp.template
sed -i "s/RELEASE_START/$DHCPReleaseStart/g" dhcp.template
sed -i "s/RELEASE_END/$DHCPReleaseEnd/g" dhcp.template

echo -e "\n>> Changing some setting within the dhcp.template"
mv -f /etc/cobbler/dhcp.template /etc/cobbler/dhcp.template.bk

echo -e "\n>> Replacing the /etc/cobbler/dhcp.tempate with the dhcp.template"
cp  ./dhcp.template /etc/cobbler/dhcp.template

echo -e "\n>> Restarting Cobbler service..."
systemctl restart cobblerd.service

sleep 2

echo -e "\n>> Syncing Cobbler settings."
cobbler sync 

echo -e "\n>> Change listen interface"
echo "DHCPDARGS=\"$DHCPListenInterface\";" >> /etc/sysconfig/dhcpd

echo -e "\n>> Restarting dhcp service..."
systemctl restart dhcpd.service
