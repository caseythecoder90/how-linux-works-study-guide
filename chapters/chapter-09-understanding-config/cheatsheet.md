# Chapter 9: Network Configuration Cheat Sheet

## Essential Network Commands

### Interface Management
```bash
# Show all interfaces
ip addr show
ip a s

# Show specific interface
ip addr show eth0

# Assign IP address
sudo ip addr add 192.168.1.100/24 dev eth0

# Remove IP address
sudo ip addr del 192.168.1.100/24 dev eth0

# Bring interface up/down
sudo ip link set eth0 up
sudo ip link set eth0 down

# Show interface statistics
ip -s link show eth0
```

### Routing
```bash
# Show routing table
ip route show
ip r s

# Add static route
sudo ip route add 192.168.45.0/24 via 10.23.2.44

# Add default gateway
sudo ip route add default via 192.168.1.1

# Delete route
sudo ip route del 192.168.45.0/24

# Delete default route
sudo ip route del default
```

### DHCP
```bash
# Request DHCP lease
sudo dhclient eth0

# Release DHCP lease
sudo dhclient -r eth0

# Show DHCP leases
cat /var/lib/dhcp/dhclient.leases

# Renew DHCP lease
sudo dhclient -r eth0 && sudo dhclient eth0
```

### DNS Tools
```bash
# DNS lookup
host google.com
nslookup google.com
dig google.com

# Reverse DNS lookup
host 8.8.8.8
dig -x 8.8.8.8

# Query specific DNS server
dig @8.8.8.8 google.com

# Trace DNS resolution
dig +trace google.com
```

### Network Testing
```bash
# Ping test
ping 8.8.8.8
ping -c 5 google.com

# Traceroute
traceroute google.com
tracepath google.com
mtr google.com

# Port connectivity
telnet google.com 80
nc -zv google.com 80
```

### Network Monitoring
```bash
# Show listening ports
ss -tulpn
netstat -tulpn

# Show active connections
ss -tn
netstat -tn

# Network statistics
ss -s
netstat -i

# Real-time traffic
sudo tcpdump -i eth0
sudo iftop
sudo nethogs
```

### Wireless
```bash
# Scan networks
sudo iwlist scan
sudo iw dev wlan0 scan

# Connect to open network
sudo iw wlan0 connect "NetworkName"

# Show wireless info
iwconfig
iw dev wlan0 info
```

### NetworkManager
```bash
# Device status
nmcli device status

# Connection list
nmcli connection show

# Connect to WiFi
nmcli dev wifi connect "SSID" password "PASSWORD"

# Bring connection up/down
nmcli connection up "connection_name"
nmcli connection down "connection_name"
```

## Configuration Files

### DNS Configuration
```bash
# DNS servers
/etc/resolv.conf
nameserver 8.8.8.8
nameserver 8.8.4.4

# Local host resolution
/etc/hosts
127.0.0.1    localhost
192.168.1.100    myserver

# Name resolution order
/etc/nsswitch.conf
hosts: files dns
```

### systemd-networkd
```bash
# Network configuration
/etc/systemd/network/eth0.network
[Match]
Name=eth0

[Network]
DHCP=yes
# or
Address=192.168.1.100/24
Gateway=192.168.1.1
DNS=8.8.8.8
```

### Netplan (Ubuntu)
```bash
/etc/netplan/01-network-manager-all.yaml
network:
  version: 2
  ethernets:
    eth0:
      dhcp4: true
      # or
      addresses: [192.168.1.100/24]
      gateway4: 192.168.1.1
      nameservers:
        addresses: [8.8.8.8, 8.8.4.4]
```

### Wireless (wpa_supplicant)
```bash
/etc/wpa_supplicant/wpa_supplicant.conf
ctrl_interface=/var/run/wpa_supplicant
network={
    ssid="NetworkName"
    psk="password"
}
```

## Router Configuration

### Enable IP Forwarding
```bash
# Temporary
sudo sysctl -w net.ipv4.ip_forward=1

# Permanent
echo 'net.ipv4.ip_forward=1' | sudo tee -a /etc/sysctl.conf
sudo sysctl -p
```

### Basic NAT with iptables
```bash
# Enable NAT
sudo iptables -t nat -A POSTROUTING -o eth1 -j MASQUERADE

# Allow forwarding
sudo iptables -A FORWARD -i eth0 -o eth1 -j ACCEPT
sudo iptables -A FORWARD -i eth1 -o eth0 -m state --state RELATED,ESTABLISHED -j ACCEPT
```

## Firewall Basics

### iptables
```bash
# Show rules
sudo iptables -L -n -v

# Allow SSH
sudo iptables -A INPUT -p tcp --dport 22 -j ACCEPT

# Allow HTTP/HTTPS
sudo iptables -A INPUT -p tcp --dport 80 -j ACCEPT
sudo iptables -A INPUT -p tcp --dport 443 -j ACCEPT

# Block all other incoming
sudo iptables -P INPUT DROP
```

### UFW (Ubuntu)
```bash
# Enable firewall
sudo ufw enable

# Allow services
sudo ufw allow ssh
sudo ufw allow http
sudo ufw allow https

# Show status
sudo ufw status verbose
```

## Troubleshooting Workflow

### No Network Connectivity
1. Check physical connection
2. Verify interface is up: `ip link show`
3. Check IP configuration: `ip addr show`
4. Test local connectivity: `ping gateway`
5. Check routing: `ip route show`
6. Test external connectivity: `ping 8.8.8.8`
7. Test DNS: `ping google.com`

### DNS Issues
1. Check `/etc/resolv.conf`
2. Test with different DNS: `dig @8.8.8.8 google.com`
3. Check `/etc/hosts` for conflicts
4. Verify `/etc/nsswitch.conf`

### Performance Issues
1. Test latency: `ping -c 10 target`
2. Check interface errors: `ip -s link show`
3. Monitor bandwidth: `iftop` or `nethogs`
4. Test throughput: `iperf3`

## IPv6 Quick Reference

### Basic Commands
```bash
# Show IPv6 addresses
ip -6 addr show

# Show IPv6 routes
ip -6 route show

# Ping IPv6
ping6 2001:4860:4860::8888

# Enable IPv6 forwarding
sudo sysctl -w net.ipv6.conf.all.forwarding=1
```

### Address Types
- **Loopback**: `::1`
- **Link-local**: `fe80::/64`
- **Global unicast**: `2000::/3`
- **Multicast**: `ff00::/8`

## Common Network Ports

| Service | Port | Protocol |
|---------|------|----------|
| SSH | 22 | TCP |
| HTTP | 80 | TCP |
| HTTPS | 443 | TCP |
| DNS | 53 | TCP/UDP |
| DHCP | 67/68 | UDP |
| SMTP | 25 | TCP |
| POP3 | 110 | TCP |
| IMAP | 143 | TCP |
| FTP | 21 | TCP |
| SFTP | 22 | TCP |

## Subnet Calculations

### Common CIDR Notations
- `/8` = 255.0.0.0 (16,777,214 hosts)
- `/16` = 255.255.0.0 (65,534 hosts)
- `/24` = 255.255.255.0 (254 hosts)
- `/25` = 255.255.255.128 (126 hosts)
- `/26` = 255.255.255.192 (62 hosts)
- `/27` = 255.255.255.224 (30 hosts)
- `/28` = 255.255.255.240 (14 hosts)
- `/29` = 255.255.255.248 (6 hosts)
- `/30` = 255.255.255.252 (2 hosts)

### Private Address Ranges
- **Class A**: 10.0.0.0/8
- **Class B**: 172.16.0.0/12
- **Class C**: 192.168.0.0/16

## Performance Monitoring

### Bandwidth Testing
```bash
# Install iperf3
sudo apt install iperf3

# Server mode
iperf3 -s

# Client mode
iperf3 -c server_ip

# UDP test
iperf3 -c server_ip -u
```

### Traffic Analysis
```bash
# Capture packets
sudo tcpdump -i eth0 -w capture.pcap

# Filter traffic
sudo tcpdump -i eth0 port 80
sudo tcpdump -i eth0 host 192.168.1.1

# Real-time monitoring
sudo iftop -i eth0
sudo nethogs eth0
```

## Advanced Features

### VLAN Configuration
```bash
# Load VLAN module
sudo modprobe 8021q

# Create VLAN interface
sudo ip link add link eth0 name eth0.100 type vlan id 100
sudo ip addr add 192.168.100.1/24 dev eth0.100
sudo ip link set eth0.100 up
```

### Bridge Configuration
```bash
# Create bridge
sudo ip link add br0 type bridge

# Add interfaces
sudo ip link set eth0 master br0
sudo ip link set eth1 master br0

# Configure bridge
sudo ip addr add 192.168.1.1/24 dev br0
sudo ip link set br0 up
```

### Network Namespaces
```bash
# Create namespace
sudo ip netns add test_ns

# List namespaces
ip netns list

# Execute command in namespace
sudo ip netns exec test_ns ping 8.8.8.8

# Delete namespace
sudo ip netns delete test_ns
```

## Quick Diagnostics

### System Status Checks
```bash
# Check network services
systemctl status NetworkManager
systemctl status systemd-networkd
systemctl status networking

# Check interface states
for iface in $(ls /sys/class/net/); do
    echo "$iface: $(cat /sys/class/net/$iface/operstate)"
done

# Check for IP conflicts
sudo arping -D -I eth0 192.168.1.100
```

### Log Analysis
```bash
# Network-related logs
sudo journalctl -u NetworkManager
sudo journalctl -u systemd-networkd
sudo dmesg | grep -i network

# DHCP logs
sudo journalctl -u dhclient
grep -i dhcp /var/log/syslog
```