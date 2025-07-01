# Chapter 9: Understanding Your Network and Its Configuration

## Overview
This chapter covers the fundamentals of Linux networking, from basic network concepts to practical configuration and troubleshooting. Understanding networking is crucial for system administration, security, and modern DevOps practices.

## Learning Objectives
By the end of this chapter, you should be able to:
- [ ] Understand the network layer model and how data flows through networks
- [ ] Configure network interfaces manually and automatically
- [ ] Work with routing tables and understand network routing
- [ ] Troubleshoot network connectivity issues
- [ ] Configure both IPv4 and IPv6 networks
- [ ] Understand DHCP, DNS, and other network services
- [ ] Set up wireless networking
- [ ] Configure Linux as a router
- [ ] Use network monitoring and diagnostic tools

## Prerequisites
- Understanding of basic Linux commands and file system
- Knowledge of processes and system configuration
- Basic understanding of IP addresses and networking concepts

---

# Complete Study Notes

## 1. Network Fundamentals

### 1.1 Network Layers Overview
Linux networking follows a layered approach:

**Physical Layer**: Hardware (cables, wireless, network cards)
**Network Layer**: IP addressing, routing (IPv4/IPv6)
**Transport Layer**: TCP/UDP protocols
**Application Layer**: HTTP, SSH, FTP, etc.

### 1.2 Packets and Data Flow
- Data is broken into **packets** for transmission
- Each packet contains source/destination addresses
- Packets can take different routes to reach destination
- Destination reassembles packets into original data

### 1.3 Key Networking Concepts
- **IP Address**: Unique identifier for network interface
- **Subnet**: Group of IP addresses on same network segment
- **Gateway**: Router that connects different networks
- **DNS**: Translates domain names to IP addresses
- **DHCP**: Automatically assigns network configuration

## 2. IP Addressing and Subnets

### 2.1 IPv4 Addresses
- 32-bit addresses written as four octets: `192.168.1.1`
- Classes: A (1-126), B (128-191), C (192-223)
- Private ranges: 10.0.0.0/8, 172.16.0.0/12, 192.168.0.0/16

### 2.2 CIDR Notation
- Combines IP address with subnet mask
- `/24` means first 24 bits are network, last 8 are host
- Examples:
    - `192.168.1.0/24` = 254 usable host addresses
    - `10.0.0.0/8` = ~16 million host addresses

### 2.3 Subnet Masks
Common subnet masks and their CIDR equivalents:
- `255.255.255.0` = `/24` (254 hosts)
- `255.255.0.0` = `/16` (65,534 hosts)
- `255.0.0.0` = `/8` (16,777,214 hosts)

### 2.4 IPv6 Addresses
- 128-bit addresses written in hexadecimal
- Format: `2001:db8:85a3::8a2e:370:7334`
- Link-local addresses: `fe80::/64`
- Global unicast addresses for internet communication

## 3. Network Interface Configuration

### 3.1 Viewing Network Interfaces

```bash
# Modern ip command (preferred)
ip addr show
ip a s

# Show specific interface
ip addr show eth0

# Legacy ifconfig (deprecated but still used)
ifconfig
ifconfig eth0
```

### 3.2 Manual Interface Configuration

```bash
# Assign IP address to interface
sudo ip addr add 192.168.1.100/24 dev eth0

# Bring interface up
sudo ip link set eth0 up

# Bring interface down
sudo ip link set eth0 down

# Remove IP address
sudo ip addr del 192.168.1.100/24 dev eth0
```

### 3.3 Interface Naming Conventions
- **Predictable names**: `enp0s3`, `wlp2s0`, `eno1`
- **Classic names**: `eth0`, `wlan0` (legacy)
- **Prefix meanings**:
    - `en` = Ethernet
    - `wl` = Wireless LAN
    - `lo` = Loopback

## 4. Routing and the Kernel Routing Table

### 4.1 Understanding Routes
Routes determine where network traffic should be sent:
- **Direct routes**: Traffic to local subnet
- **Gateway routes**: Traffic through router
- **Default route**: Catch-all for non-local traffic

### 4.2 Viewing Routes

```bash
# Show routing table
ip route show
ip r s

# Show specific destination
ip route show 192.168.1.0/24

# Legacy route command
route -n
```

### 4.3 Adding and Removing Routes

```bash
# Add static route
sudo ip route add 192.168.45.0/24 via 10.23.2.44

# Add default gateway
sudo ip route add default via 192.168.1.1

# Delete route
sudo ip route del 192.168.45.0/24

# Delete default route
sudo ip route del default
```

### 4.4 Route Table Example
```
default via 192.168.1.1 dev eth0 proto static metric 100
192.168.1.0/24 dev eth0 proto kernel scope link src 192.168.1.100
```

## 5. Network Configuration Methods

### 5.1 Manual Configuration (Temporary)
Commands using `ip` are temporary and lost on reboot.

### 5.2 Boot-Time Configuration
Different distributions use different methods:
- **systemd-networkd**: Modern systemd approach
- **NetworkManager**: Desktop-focused manager
- **ifupdown**: Traditional Debian/Ubuntu method
- **Netplan**: Ubuntu's unified configuration

### 5.3 NetworkManager
Common on desktop systems:

```bash
# Command-line interface
nmcli device status
nmcli connection show
nmcli connection up "Wired connection 1"

# GUI tools
nm-applet        # System tray applet
nm-connection-editor  # Configuration GUI
```

### 5.4 systemd-networkd
Systemd's networking service:

```bash
# Enable and start
sudo systemctl enable systemd-networkd
sudo systemctl start systemd-networkd

# Configuration files in /etc/systemd/network/
```

Example configuration (`/etc/systemd/network/eth0.network`):
```ini
[Match]
Name=eth0

[Network]
DHCP=yes
```

## 6. DHCP Configuration

### 6.1 DHCP Client Configuration

```bash
# Request DHCP lease
sudo dhclient eth0

# Release DHCP lease
sudo dhclient -r eth0

# Show DHCP leases
cat /var/lib/dhcp/dhclient.leases
```

### 6.2 DHCP Server Setup (dnsmasq)

```bash
# Install dnsmasq
sudo apt install dnsmasq

# Configuration in /etc/dnsmasq.conf
interface=eth1
dhcp-range=192.168.1.50,192.168.1.150,255.255.255.0,12h
dhcp-option=3,192.168.1.1  # Default gateway
dhcp-option=6,8.8.8.8,8.8.4.4  # DNS servers
```

## 7. DNS Configuration

### 7.1 DNS Resolution Files

**`/etc/resolv.conf`**: DNS server configuration
```
nameserver 8.8.8.8
nameserver 8.8.4.4
search example.com
domain example.com
```

**`/etc/hosts`**: Local hostname resolution
```
127.0.0.1    localhost
192.168.1.100    myserver.example.com myserver
```

**`/etc/nsswitch.conf`**: Name resolution order
```
hosts: files dns
```

### 7.2 DNS Tools

```bash
# Lookup hostname
host google.com
nslookup google.com
dig google.com

# Reverse DNS lookup
host 8.8.8.8
dig -x 8.8.8.8

# Detailed DNS query
dig @8.8.8.8 google.com MX
dig +trace google.com
```

## 8. Network Troubleshooting Tools

### 8.1 Connectivity Testing

```bash
# Test reachability
ping 8.8.8.8
ping6 2001:4860:4860::8888

# Continuous ping
ping -c 5 google.com

# Test specific port
telnet google.com 80
nc -zv google.com 80
```

### 8.2 Network Analysis

```bash
# Show network statistics
netstat -tuln          # Listening ports
netstat -i              # Interface statistics
ss -tuln                # Modern replacement for netstat

# Show active connections
ss -tulpn
netstat -tulpn

# Show routing table
ip route
route -n
```

### 8.3 Traffic Analysis

```bash
# Capture network traffic
sudo tcpdump -i eth0
sudo tcpdump -i eth0 port 80
sudo tcpdump -i eth0 host 192.168.1.1

# Monitor bandwidth usage
iftop
nethogs
vnstat
```

### 8.4 Traceroute

```bash
# Trace packet path
traceroute google.com
tracepath google.com
mtr google.com          # Continuous traceroute
```

## 9. Wireless Networking

### 9.1 Wireless Tools

```bash
# Scan for networks
sudo iwlist scan
sudo iw dev wlan0 scan

# Show wireless info
iwconfig
iw dev wlan0 info

# Connect to open network
sudo iw wlan0 connect "NetworkName"
```

### 9.2 WPA/WPA2 Configuration

**Manual wpa_supplicant setup:**

1. Create configuration file (`/etc/wpa_supplicant/wpa_supplicant.conf`):
```
ctrl_interface=/var/run/wpa_supplicant
network={
    ssid="MyNetwork"
    psk="MyPassword"
}
```

2. Start wpa_supplicant:
```bash
sudo wpa_supplicant -B -i wlan0 -c /etc/wpa_supplicant/wpa_supplicant.conf
```

3. Get DHCP lease:
```bash
sudo dhclient wlan0
```

### 9.3 NetworkManager Wireless

```bash
# List available networks
nmcli dev wifi list

# Connect to network
nmcli dev wifi connect "NetworkName" password "MyPassword"

# Show saved connections
nmcli connection show
```

## 10. Configuring Linux as a Router

### 10.1 Enable IP Forwarding

```bash
# Temporary
sudo sysctl -w net.ipv4.ip_forward=1
sudo sysctl -w net.ipv6.conf.all.forwarding=1

# Permanent (add to /etc/sysctl.conf)
net.ipv4.ip_forward=1
net.ipv6.conf.all.forwarding=1

# Apply sysctl changes
sudo sysctl -p
```

### 10.2 Router Configuration Example

For a router with interfaces:
- `eth0`: LAN (192.168.1.0/24)
- `eth1`: WAN (DHCP or static)

```bash
# Configure LAN interface
sudo ip addr add 192.168.1.1/24 dev eth0
sudo ip link set eth0 up

# Configure WAN interface (if static)
sudo ip addr add 203.0.113.10/24 dev eth1
sudo ip link set eth1 up
sudo ip route add default via 203.0.113.1

# Or use DHCP for WAN
sudo dhclient eth1
```

### 10.3 NAT with iptables

```bash
# Enable NAT for outgoing traffic
sudo iptables -t nat -A POSTROUTING -o eth1 -j MASQUERADE

# Allow forwarding
sudo iptables -A FORWARD -i eth0 -o eth1 -j ACCEPT
sudo iptables -A FORWARD -i eth1 -o eth0 -m state --state RELATED,ESTABLISHED -j ACCEPT

# Save rules (varies by distribution)
sudo iptables-save > /etc/iptables/rules.v4
```

## 11. Network Security Basics

### 11.1 Firewall with iptables

```bash
# Show current rules
sudo iptables -L -n -v

# Block all incoming traffic
sudo iptables -P INPUT DROP

# Allow loopback
sudo iptables -A INPUT -i lo -j ACCEPT

# Allow established connections
sudo iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT

# Allow SSH
sudo iptables -A INPUT -p tcp --dport 22 -j ACCEPT

# Allow HTTP/HTTPS
sudo iptables -A INPUT -p tcp --dport 80 -j ACCEPT
sudo iptables -A INPUT -p tcp --dport 443 -j ACCEPT
```

### 11.2 Firewall with ufw (Ubuntu)

```bash
# Enable firewall
sudo ufw enable

# Allow services
sudo ufw allow ssh
sudo ufw allow http
sudo ufw allow https

# Allow specific port
sudo ufw allow 8080

# Show status
sudo ufw status verbose
```

### 11.3 Port Scanning Detection

```bash
# Check for open ports
nmap localhost
nmap -sT 192.168.1.1

# Check specific ports
nmap -p 22,80,443 192.168.1.1
```

## 12. Advanced Network Configuration

### 12.1 VLAN Configuration

```bash
# Load 8021q module
sudo modprobe 8021q

# Create VLAN interface
sudo ip link add link eth0 name eth0.100 type vlan id 100
sudo ip addr add 192.168.100.1/24 dev eth0.100
sudo ip link set eth0.100 up
```

### 12.2 Bridge Configuration

```bash
# Create bridge
sudo ip link add br0 type bridge

# Add interfaces to bridge
sudo ip link set eth0 master br0
sudo ip link set eth1 master br0

# Configure bridge
sudo ip addr add 192.168.1.1/24 dev br0
sudo ip link set br0 up
```

### 12.3 Bonding/Teaming

```bash
# Create bond interface
sudo ip link add bond0 type bond mode 802.3ad

# Add slaves
sudo ip link set eth0 down
sudo ip link set eth1 down
sudo ip link set eth0 master bond0
sudo ip link set eth1 master bond0

# Configure bond
sudo ip addr add 192.168.1.1/24 dev bond0
sudo ip link set bond0 up
```

## 13. Network Monitoring and Performance

### 13.1 Bandwidth Monitoring

```bash
# Real-time interface statistics
watch -n 1 cat /proc/net/dev

# Historical network usage
vnstat -d    # Daily
vnstat -m    # Monthly
vnstat -h    # Hourly

# Live bandwidth usage per process
sudo nethogs

# Live connection monitoring
sudo iftop
```

### 13.2 Network Performance Testing

```bash
# Test bandwidth between hosts
# On server:
iperf3 -s

# On client:
iperf3 -c server_ip

# HTTP download speed test
wget -O /dev/null http://speedtest.example.com/file.bin

# Latency testing
ping -c 100 8.8.8.8 | tail -1
```

### 13.3 Connection Analysis

```bash
# Show socket statistics
ss -s

# Show TCP connections with details
ss -tn

# Show UDP sockets
ss -un

# Show listening processes
ss -tulpn
```

---

# Quick Reference Commands

## Essential Network Commands

| Task | Command |
|------|---------|
| Show interfaces | `ip addr show` |
| Show routes | `ip route show` |
| Ping host | `ping hostname` |
| DNS lookup | `host hostname` |
| Show listening ports | `ss -tulpn` |
| Scan for wireless | `iwlist scan` |
| DHCP renew | `dhclient eth0` |
| Show ARP table | `ip neigh show` |
| Traceroute | `traceroute hostname` |
| Network statistics | `netstat -i` |

## Configuration Files

| File | Purpose |
|------|---------|
| `/etc/resolv.conf` | DNS configuration |
| `/etc/hosts` | Local hostname resolution |
| `/etc/hostname` | System hostname |
| `/etc/nsswitch.conf` | Name resolution order |
| `/etc/systemd/network/` | systemd-networkd config |
| `/etc/NetworkManager/` | NetworkManager config |
| `/etc/wpa_supplicant/` | Wireless configuration |
| `/etc/sysctl.conf` | Kernel network parameters |

## Important Directories

| Directory | Contents |
|-----------|----------|
| `/sys/class/net/` | Network interface information |
| `/proc/net/` | Kernel network statistics |
| `/var/lib/dhcp/` | DHCP lease information |
| `/etc/netplan/` | Netplan configuration (Ubuntu) |

---

# Practice Exercises

## Exercise 1: Basic Network Configuration
1. Find your current IP address and network interface name
2. Temporarily change your IP address using the `ip` command
3. Test connectivity to your default gateway
4. Restore your original network configuration

## Exercise 2: Static Route Configuration
1. Add a static route to a remote network
2. Test connectivity to that network
3. View the routing table to confirm your route
4. Remove the static route

## Exercise 3: DNS Troubleshooting
1. Test DNS resolution using different tools (`host`, `dig`, `nslookup`)
2. Temporarily change your DNS server
3. Test resolution again and compare results
4. Add a custom entry to `/etc/hosts` and test

## Exercise 4: Network Monitoring
1. Monitor network traffic using `tcpdump`
2. Check bandwidth usage with `iftop` or `nethogs`
3. Use `ss` to view active connections
4. Test network performance with `iperf3`

## Exercise 5: Wireless Configuration
1. Scan for available wireless networks
2. Connect to a wireless network using command-line tools
3. Verify connectivity and configuration
4. Disconnect and reconnect using NetworkManager

---

# Key Concepts for Certification

## CompTIA Linux+ / LPIC-1 Topics
- Network interface configuration (`ip`, `ifconfig`)
- Routing table management
- DNS configuration and troubleshooting
- DHCP client configuration
- Network troubleshooting tools
- Firewall basics (`iptables`, `ufw`)

## Red Hat/CentOS Specific
- NetworkManager configuration
- `nmcli` command usage
- systemd-networkd configuration
- Firewalld management

## Ubuntu/Debian Specific
- Netplan configuration
- `ufw` firewall management
- Network interface naming conventions

## Advanced Networking Topics
- VLAN configuration
- Network bonding/teaming
- Bridge configuration
- Network namespaces
- Container networking

---

# Troubleshooting Scenarios

## Common Network Issues

### 1. No Network Connectivity
**Symptoms**: Cannot reach any external hosts
**Troubleshooting steps**:
1. Check physical connection
2. Verify interface is up: `ip link show`
3. Check IP configuration: `ip addr show`
4. Test local connectivity: `ping gateway`
5. Check routing: `ip route show`
6. Test DNS: `ping 8.8.8.8` vs `ping google.com`

### 2. Slow Network Performance
**Symptoms**: High latency or low bandwidth
**Troubleshooting steps**:
1. Test with `ping` and `traceroute`
2. Check interface errors: `ip -s link show`
3. Monitor bandwidth usage: `iftop`
4. Check for duplex mismatches
5. Test with `iperf3` for baseline

### 3. DNS Resolution Issues
**Symptoms**: Cannot resolve hostnames
**Troubleshooting steps**:
1. Check `/etc/resolv.conf`
2. Test different DNS servers
3. Verify `/etc/nsswitch.conf`
4. Check `/etc/hosts` for conflicts
5. Use `dig` for detailed DNS queries

### 4. Intermittent Connectivity
**Symptoms**: Network works sometimes
**Troubleshooting steps**:
1. Monitor with continuous ping
2. Check DHCP lease time
3. Look for IP conflicts
4. Monitor interface statistics
5. Check for wireless interference

---

# Security Considerations

## Network Security Best Practices

### 1. Firewall Configuration
- Always use a firewall (iptables, ufw, firewalld)
- Follow principle of least privilege
- Block unnecessary ports
- Log suspicious activity

### 2. SSH Security
- Disable root login
- Use key-based authentication
- Change default port
- Use fail2ban for brute-force protection

### 3. Network Monitoring
- Monitor unusual traffic patterns
- Log network connections
- Use intrusion detection systems
- Regular security audits

### 4. Wireless Security
- Use WPA3 or WPA2 (never WEP)
- Strong pre-shared keys
- Hide SSID if appropriate
- MAC address filtering for additional security

---

This comprehensive study guide covers all the essential networking concepts from Chapter 9 of "How Linux Works" and includes practical examples, exercises, and real-world scenarios that will help you master Linux networking for both daily administration tasks and certification exams.