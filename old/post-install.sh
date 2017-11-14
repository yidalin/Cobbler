echo -e "\n>> Use Cobbler to manage dhcp config."
sed -i 's/manage_dhcp: 0/manage_dhcp: 1/g' /etc/cobbler/settings

DHCP_NETWORK='192.168.0.0'
DHCP_SUBNETMASK='255.255.255.0'
DHCP_GATEWAY='192.168.0.1'
DHCP_DNS='192.168.0.1'
DHCP_RELEASE_START='192.168.0.220'
DHCP_RELEASE_END='192.168.0.210'
DHCP_LISTEN_INTERFASE="eth0"

echo -e "\n>> Changing some setting within the dhcp.template"
mv -f /etc/cobbler/dhcp.template /etc/cobbler/dhcp.template.bk

echo -e "\n>> Replacing the /etc/cobbler/dhcp.tempate with the dhcp.template"
cp -av ./dhcp.template /etc/cobbler/dhcp.template

sed -i "s/DHCP_NETWORK/$DHCP_NETWORK/g" /etc/cobbler/dhcp.template
sed -i "s/DHCP_SUBNETMASK/$DHCP_SUBNETMASK/g" /etc/cobbler/dhcp.template
sed -i "s/DHCP_GATEWAY/$DHCP_GATEWAY/g" /etc/cobbler/dhcp.template
sed -i "s/DHCP_DNS/$DHCP_DNS/g" /etc/cobbler/dhcp.template
sed -i "s/DHCP_RELEASE_START/$DHCP_RELEASE_START/g" /etc/cobbler/dhcp.template
sed -i "s/DHCP_RELEASE_END/$DHCP_RELEASE_END/g" /etc/cobbler/dhcp.template

echo -e "\n>> Restarting Cobbler service..."
systemctl restart dhcpd.service
systemctl restart cobblerd.service

echo -e "\n>> Syncing Cobbler settings."
cobbler sync 

#echo -e "\n>> Change listen interface"
#echo "DHCPDARGS=\"$DHCPListenInterface\";" >> /etc/sysconfig/dhcpd
