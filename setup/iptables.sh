#!/bin/bash

# reset
iptables -F
iptables -X

# set OUTPUT,FORWARD policies. After set the INPUT policy
iptables -P OUTPUT ACCEPT
iptables -P FORWARD DROP

# loopback
iptables -A INPUT -i lo -j ACCEPT
iptables -A OUTPUT -o lo -j ACCEPT

# accept packets on the established connectiones
iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT

# accept mainly protcoles
iptables -A INPUT -p icmp -j ACCEPT
iptables -A INPUT -p tcp -j ACCEPT
iptables -A INPUT -p udp -j ACCEPT

# accept ssh
iptables -A INPUT -p tcp --dport 10022 -j ACCEPT
iptables -A INPUT -p tcp --sport 10022 -j ACCEPT

# accept http
iptables -A INPUT -p tcp --dport 80 -j ACCEPT
iptables -A INPUT -p tcp --sport 80 -j ACCEPT

# accept https
iptables -A INPUT -p tcp --dport 443 -j ACCEPT
iptables -A INPUT -p tcp --sport 443 -j ACCEPT

# accept smtp
iptables -A INPUT -p tcp --dport 25 -j ACCEPT
iptables -A INPUT -p tcp --sport 25 -j ACCEPT

# accept submission
iptables -A INPUT -p tcp --dport 587 -j ACCEPT

# accept MySQL port
iptables -A INPUT -p tcp --dport 3306 -j ACCEPT

# drop ssh port
iptables -A INPUT -p tcp --dport 22 -j DROP

# Only one syn packet is accepted per 1 second.
iptables -A INPUT -i ppp+ -p tcp --syn -m limit --limit 1/s -j ACCEPT
iptables -A INPUT -i ppp+ -p icmp --icmp-type echo-request -m limit --limit 1/s -j ACCEPT

# drop others
iptables -P INPUT DROP
