# Chapter 9: Understanding Your Network and Its Configuration - Detailed Notes

## Table of Contents
1. [Network Basics](#network-basics)
2. [Network Layers](#network-layers)
3. [The Internet Layer](#the-internet-layer)
4. [Routes and Routing Tables](#routes-and-routing-tables)
5. [IPv6 Addresses and Networks](#ipv6-addresses-and-networks)
6. [Basic Network Tools](#basic-network-tools)
7. [Physical Layer and Ethernet](#physical-layer-and-ethernet)
8. [Network Interface Configuration](#network-interface-configuration)
9. [Network Configuration Managers](#network-configuration-managers)
10. [DNS and Hostname Resolution](#dns-and-hostname-resolution)
11. [Transport Layer: TCP and UDP](#transport-layer-tcp-and-udp)
12. [DHCP and Automatic Configuration](#dhcp-and-automatic-configuration)
13. [Linux as a Router](#linux-as-a-router)
14. [Firewalls](#firewalls)
15. [Wireless Networking](#wireless-networking)

---

## Network Basics

### Key Concepts
- **Host**: Any machine connected to a network
- **Router**: A host that can move data from one network to another (also called gateway)
- **LAN (Local Area Network)**: Connected group of hosts, typically in same physical location
- **Subnet**: A connected group of hosts with IP addresses in a particular range

### Network Topology
- Internet is decentralized, made up of smaller networks called subnets
- Subnets are interconnected through routers
- Typical home/office network: multiple hosts + router providing internet access

---

## Network Layers

### Four-Layer Model
1. **Application Layer**: User-level programs (web browsers, email clients)
2. **Transport Layer**: Data integrity and flow control (TCP, UDP)
3. **Network/Internet Layer**: Moving packets between hosts (IP)
4. **Physical Layer**: Hardware transmission (Ethernet, WiFi)

### Layer Interaction
- Each layer handles specific aspects of networking
- Data flows down the stack when sending, up when receiving
- Lower layers are independent of higher layers
- Allows mixing different technologies at each layer

---

## The Internet Layer

### IPv4 Fundamentals
- **IP Address**: 32-bit address (4 bytes) identifying a host
- **Format**: Four decimal numbers separated by dots (e.g., 10.23.2.4)
- **Total addresses**: ~4.3 billion (insufficient for current internet scale)

### Key Commands
```bash
# View IP configuration
ip address show
ip addr show          # Short form

# View specific interface
ip address show eth0

# Legacy command (less capable)
ifconfig             # Older systems only
```

### Subnets
- **Definition**: Group of hosts with IP addresses in specific range
- **Network Prefix**: Common part of all addresses in subnet
- **Subnet Mask**: Defines which bits are common to subnet

#### Subnet Example
- **Range**: 10.23.2.1 to 10.23.2.254
- **Network Prefix**: 10.23.2.0
- **Subnet Mask**: 255.255.255.0

#### Binary Representation
```
10.23.2.0:     00001010 00010111 00000010 00000000
255.255.255.0: 11111111 11111111 11111111 00000000
```

### CIDR Notation
- **Format**: network_address/prefix_length
- **Example**: 10.23.2.0/24 (24 bits for network, 8 bits for host)
- **Common Masks**:
    - /24 = 255.255.255.0 (254 hosts)
    - /16 = 255.255.0.0 (65,534 hosts)
    - /8 = 255.0.0.0 (16,777,214 hosts)

---

## Routes and Routing Tables

### Routing Concepts
- **Routing Table**: Kernel's map for sending packets to destinations
- **Route**: Rule specifying how to reach a network

### Key Commands
```bash
# Show routing table
ip route show
ip route             # Short form

# Legacy command
route -n             # -n shows IPs instead of hostnames
```

### Sample Routing Table Output
```
default via 10.23.2.1 dev enp0s31f6 proto static metric 100
10.23.2.0/24 dev enp0s31f6 proto kernel scope link src 10.23.2.4 metric 100
```

### Route Components
- **Destination**: Network the route applies to
- **via**: Next hop router IP
- **dev**: Network interface to use
- **proto**: How route was established (kernel, static, etc.)
- **scope**: Route scope (link, global)
- **src**: Source IP for outgoing packets
- **metric**: Route priority (lower = higher priority)

### Default Gateway
- **Purpose**: Route for packets with no specific route
- **Notation**: "default" or 0.0.0.0/0 (IPv4)
- **Function**: Matches any destination address
- **Selection**: Kernel chooses route with longest matching prefix

---

## IPv6 Addresses and Networks

### IPv6 Basics
- **Address Size**: 128 bits (32 bytes)
- **Format**: Eight groups of 4 hexadecimal digits
- **Example**: 2001:0db8:0a0b:12f0:0000:0000:0000:8b6e

### IPv6 Address Abbreviation
```bash
# Full form
2001:0db8:0a0b:12f0:0000:0000:0000:8b6e

# Abbreviated form (remove leading zeros, compress consecutive zeros)
2001:db8:a0b:12f0::8b6e
```

### IPv6 Subnets
- **Common Prefix**: /64 (64 bits for network, 64 bits for host)
- **Interface ID**: Host-specific portion of address
- **CIDR Notation**: Same as IPv4 (address/prefix_length)

### IPv6 Commands
```bash
# View IPv6 configuration
ip -6 address show

# Force IPv6 with other commands
ping -6 hostname
host -6 hostname
```

### Dual-Stack Networks
- Run both IPv4 and IPv6 simultaneously
- Applications choose which protocol to use
- Gradual transition strategy from IPv4 to IPv6

---

## Basic Network Tools

### ping Command
- **Purpose**: Test connectivity and round-trip time
- **Protocol**: ICMP echo request/response

```bash
# Basic ping
ping 10.23.2.1
ping google.com

# Specific protocol
ping -4 hostname     # Force IPv4
ping -6 hostname     # Force IPv6

# Limited count
ping -c 5 hostname   # Send 5 packets
```

### Sample ping Output
```
PING 10.23.2.1 (10.23.2.1) 56(84) bytes of data.
64 bytes from 10.23.2.1: icmp_req=1 ttl=64 time=1.76 ms
64 bytes from 10.23.2.1: icmp_req=2 ttl=64 time=2.35 ms
```

### host Command (DNS Lookup)
```bash
# Resolve hostname to IP
host www.example.com

# Reverse lookup (IP to hostname)
host 172.17.216.34

# Force specific protocol for lookup
host -4 hostname     # Query via IPv4
host -6 hostname     # Query via IPv6
```

---

## Physical Layer and Ethernet

### Network Interface Names
- **Predictable Names**: Based on hardware location (e.g., enp0s31f6)
- **Traditional Names**: eth0, wlan0 (temporary at boot)
- **Naming Convention**:
    - en = Ethernet
    - wl = Wireless
    - p0s31f6 = PCI location identifier

### Interface Information
```bash
# View interface details
ip address show enp0s31f6

# Check interface status
ip link show

# Hardware details
ethtool enp0s31f6    # Ethernet-specific settings
```

### Interface States
- **UP**: Interface is operational
- **DOWN**: Interface is disabled
- **BROADCAST**: Supports broadcast
- **MULTICAST**: Supports multicast
- **LOWER_UP**: Physical layer is up

---

## Network Interface Configuration

### Manual Interface Configuration Steps
1. **Hardware Detection**: Ensure kernel has driver
2. **Physical Setup**: Configure hardware-specific settings
3. **IP Assignment**: Assign IP address and subnet
4. **Routing**: Add necessary routes including default gateway

### Manual Configuration Commands

#### Adding IP Address
```bash
# Add IP address to interface
ip address add 10.23.2.100/24 dev eth0

# Remove IP address
ip address del 10.23.2.100/24 dev eth0

# Bring interface up/down
ip link set eth0 up
ip link set eth0 down
```

#### Route Management
```bash
# Add default gateway
ip route add default via 10.23.2.1 dev eth0

# Remove default gateway
ip route del default

# Add specific route
ip route add 192.168.45.0/24 via 10.23.2.44

# Remove specific route
ip route del 192.168.45.0/24
```

### Boot-Activated Configuration
- **Traditional**: Scripts run at boot time
- **Tools**: ifup/ifdown (distribution-specific)
- **Problem**: Different distributions use different implementations
- **Modern Solution**: Network configuration managers

### Netplan
- **Purpose**: Unified network configuration standard
- **Location**: /etc/netplan/
- **Format**: YAML files
- **Function**: Generates configuration for other network managers
- **Backends**: NetworkManager, systemd-networkd

---

## Network Configuration Managers

### NetworkManager

#### Key Features
- **Automatic Detection**: Hardware devices via udev/D-Bus
- **Connection Management**: Maintains list of known connections
- **Delegation**: Uses specialized tools (dhclient, wpa_supplicant)
- **Plugin Support**: Distribution-specific configurations

#### NetworkManager Operation
1. **Startup**: Gather device information
2. **Connection Priority**:
    - Try wired connection first
    - Fall back to wireless
    - Prefer recently used networks
3. **Maintenance**: Monitor connection status

#### NetworkManager Commands
```bash
# Quick status overview
nmcli

# Detailed device information
nmcli device show

# Connection management
nmcli connection show
nmcli connection up connection_name
nmcli connection down connection_name

# Check if network is online
nm-online                    # Returns 0 if online
```

#### NetworkManager Configuration
- **Main Config**: /etc/NetworkManager/NetworkManager.conf
- **Format**: INI-style sections and key-value pairs
- **Connections**: /etc/NetworkManager/system-connections/

```ini
# Example NetworkManager.conf
[main]
plugins=ifupdown,keyfile
```

#### Unmanaged Interfaces
- **Purpose**: Prevent NetworkManager from managing specific interfaces
- **Common**: localhost (lo) interface
- **Method**: Configure via plugins or configuration files

---

## DNS and Hostname Resolution

### DNS Process
1. Application calls hostname resolution function
2. Function checks local configuration
3. If needed, queries DNS server
4. Returns IP address to application

### /etc/hosts
- **Purpose**: Local hostname to IP mapping
- **Priority**: Usually checked before DNS

```bash
# Example /etc/hosts
127.0.0.1    localhost
10.23.2.3    atlantic.aem7.net atlantic
10.23.2.4    pacific.aem7.net pacific
::1          localhost ip6-localhost
```

### /etc/resolv.conf
- **Purpose**: DNS server configuration
- **Modern Systems**: Often managed automatically

```bash
# Traditional resolv.conf
search mydomain.example.com example.com
nameserver 10.32.45.23
nameserver 10.3.2.3
```

### DNS Caching
- **Problem**: No local caching of DNS responses
- **Solutions**:
    - systemd-resolved (most common)
    - dnsmasq
    - nscd
    - BIND as cache

```bash
# Check DNS status
resolvectl status              # Current command
systemd-resolve --status      # Older systems

# Signs of caching daemon
# 127.0.0.53 or 127.0.0.1 in resolv.conf
nslookup -debug hostname
```

### Zero-Configuration DNS
- **mDNS**: Multicast DNS for local network
- **LLMNR**: Link-Local Multicast Name Resolution
- **Function**: Broadcast name requests on local network
- **Implementation**: Often via systemd-resolved

### /etc/nsswitch.conf
- **Purpose**: Control name lookup precedence
- **Scope**: Users, passwords, hosts, etc.

```bash
# Example hosts line
hosts: files dns myhostname
```

---

## Transport Layer: TCP and UDP

### Transport Layer Purpose
- **Data Integrity**: Ensure complete data delivery
- **Flow Control**: Manage data transmission rate
- **Connection Management**: Establish and maintain connections

### TCP (Transmission Control Protocol)
- **Connection-Oriented**: Establishes dedicated connections
- **Reliable**: Guarantees data delivery and ordering
- **Flow Control**: Manages transmission speed
- **Error Detection**: Retransmits lost packets

#### TCP Ports and Connections
```bash
# View listening TCP ports
netstat -tln
ss -tln                      # Modern alternative

# View established connections
netstat -t
ss -t

# Port ranges
# 0-1023: Well-known ports (require root)
# 1024-49151: Registered ports
# 49152-65535: Dynamic/private ports
```

#### Common TCP Ports
- **22**: SSH
- **25**: SMTP
- **53**: DNS
- **80**: HTTP
- **443**: HTTPS
- **993**: IMAPS

### UDP (User Datagram Protocol)
- **Connectionless**: No connection establishment
- **Unreliable**: No delivery guarantee
- **Fast**: Minimal overhead
- **Use Cases**: DNS queries, video streaming, NTP

```bash
# View UDP ports
netstat -uln
ss -uln
```

### /etc/services
- **Purpose**: Maps service names to port numbers
- **Format**: service_name port/protocol [aliases]

```bash
# Example entries
ssh             22/tcp
ssh             22/udp
domain          53/tcp
domain          53/udp
http            80/tcp
https           443/tcp
```

---

## DHCP and Automatic Configuration

### DHCP (Dynamic Host Configuration Protocol)
- **Purpose**: Automatic network configuration
- **Provides**: IP address, subnet mask, default gateway, DNS servers
- **Advantages**: No manual configuration, prevents IP conflicts

### DHCP Process
1. Client broadcasts DHCP discover
2. Server responds with DHCP offer
3. Client sends DHCP request
4. Server confirms with DHCP ACK

### Linux DHCP Clients
- **dhclient**: ISC DHCP client
- **dhcpcd**: Alternative DHCP client
- **systemd-networkd**: systemd's network daemon

```bash
# Manual DHCP request
dhclient eth0

# Release DHCP lease
dhclient -r eth0

# View current leases
cat /var/lib/dhcp/dhclient.leases
```

### DHCP Servers
- **Linux**: Can run DHCP server (dhcpd)
- **Recommendation**: Use router's built-in DHCP for small networks
- **Important**: Only one DHCP server per subnet

### IPv6 Stateless Configuration
- **Alternative**: DHCPv6 exists but stateless is more common
- **Process**:
    1. Generate link-local address (fe80::/64)
    2. Check for address conflicts
    3. Listen for Router Advertisement (RA)
    4. Configure global address from RA prefix

---

## Linux as a Router

### Router Requirements
- **Multiple Interfaces**: Two or more network interfaces
- **IP Forwarding**: Kernel packet forwarding enabled
- **Routing Configuration**: Proper routing table entries

### Enabling IP Forwarding
```bash
# Check current status
sysctl net.ipv4.ip_forward

# Enable temporarily
sysctl -w net.ipv4.ip_forward=1

# Enable permanently
echo 'net.ipv4.ip_forward=1' >> /etc/sysctl.conf
# Or add to /etc/sysctl.d/99-ipforward.conf
```

### Router Configuration Example
- **Subnets**: 10.23.2.0/24 and 192.168.45.0/24
- **Router IPs**: 10.23.2.1 and 192.168.45.1
- **Internet Uplink**: Third interface

```bash
# Example routing table on router
ip route show
10.23.2.0/24 dev enp0s31f6 proto kernel scope link src 10.23.2.1
192.168.45.0/24 dev enp0s1 proto kernel scope link src 192.168.45.1
```

### Private Networks (IPv4)
- **RFC 1918 Ranges**:
    - 10.0.0.0/8 (10.0.0.0 - 10.255.255.255)
    - 172.16.0.0/12 (172.16.0.0 - 172.31.255.255)
    - 192.168.0.0/16 (192.168.0.0 - 192.168.255.255)

### Network Address Translation (NAT)
- **Purpose**: Allow private networks to access internet
- **Process**: Replace private IPs with public IP in outgoing packets
- **Linux**: IP masquerading with iptables

```bash
# Enable NAT/masquerading
iptables -t nat -A POSTROUTING -o internet_interface -j MASQUERADE

# Enable IP forwarding (required for NAT)
sysctl -w net.ipv4.ip_forward=1
```

---

## Firewalls

### Linux Firewall Basics
- **Framework**: Netfilter in kernel
- **User Tools**: iptables, nftables
- **Principle**: Control packet flow through chains

### iptables Concepts
- **Tables**: nat, filter, mangle
- **Chains**: INPUT, OUTPUT, FORWARD
- **Rules**: Match criteria and actions
- **Targets**: ACCEPT, DROP, REJECT

### Basic iptables Commands
```bash
# List current rules
iptables -L
iptables -L -n              # Show IPs instead of hostnames
iptables -L -v              # Verbose (packet counts)

# Add rules
iptables -A INPUT -p tcp --dport 22 -j ACCEPT
iptables -A INPUT -p tcp --dport 80 -j ACCEPT

# Insert rule at specific position
iptables -I INPUT 1 -p tcp --dport 443 -j ACCEPT

# Delete rules
iptables -D INPUT -p tcp --dport 22 -j ACCEPT
iptables -D INPUT 1         # Delete by line number

# Set default policies
iptables -P INPUT DROP
iptables -P FORWARD DROP
iptables -P OUTPUT ACCEPT
```

### Firewall Strategy Example
```bash
# Allow loopback
iptables -A INPUT -i lo -j ACCEPT

# Allow established connections
iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT

# Allow specific services
iptables -A INPUT -p tcp --dport 22 -j ACCEPT    # SSH
iptables -A INPUT -p tcp --dport 80 -j ACCEPT    # HTTP
iptables -A INPUT -p tcp --dport 443 -j ACCEPT   # HTTPS

# Allow local network
iptables -A INPUT -s 10.23.2.0/24 -j ACCEPT

# Allow non-SYN TCP (outgoing connections)
iptables -A INPUT -p tcp '!' --syn -j ACCEPT

# Allow DNS responses
iptables -A INPUT -p udp --source-port 53 -s dns_server_ip -j ACCEPT

# Drop everything else (should be default policy)
iptables -P INPUT DROP
```

### Firewall Best Practices
- **Default Deny**: Block everything, then allow specific traffic
- **Minimize Services**: Only allow necessary services
- **Use Established**: Allow return traffic for outgoing connections
- **Log Dropped**: Monitor blocked attempts
- **Regular Review**: Audit rules periodically

---

## Wireless Networking

### Wireless Components
- **Network Identification**: SSID (Service Set Identifier)
- **Management**: Access points bridge wireless/wired
- **Authentication**: Password/key requirements
- **Encryption**: Protect radio transmissions

### iw Command
```bash
# Scan for wireless networks
iw dev wlp1s0 scan

# View current connection
iw dev wlp1s0 link

# Connect to open network
iw wlp1s0 connect network_name

# Bring interface up (required for scanning)
ip link set wlp1s0 up
```

### Wireless Security
- **WEP**: Deprecated, insecure
- **WPA/WPA2/WPA3**: WiFi Protected Access (use WPA2+ only)
- **Tool**: wpa_supplicant daemon

#### wpa_supplicant
- **Purpose**: Handle wireless authentication and encryption
- **Config**: /etc/wpa_supplicant.conf
- **Manual**: wpa_supplicant(8) for detailed options

### NetworkManager and Wireless
- **Advantage**: Automates entire wireless connection process
- **Process**:
    1. Scan for networks
    2. Run wpa_supplicant for authentication
    3. Configure network layer (DHCP)
    4. Maintain connection

---

## Advanced Topics

### ARP (Address Resolution Protocol)
- **Purpose**: Map IP addresses to MAC addresses
- **IPv4**: Uses ARP cache
- **IPv6**: Uses NDP (Neighbor Discovery Protocol)

```bash
# View ARP cache
ip neigh                     # Modern command
arp                         # Legacy command
```

### Localhost
- **Address**: 127.0.0.1 (IPv4), ::1 (IPv6)
- **Purpose**: Local machine communication
- **Interface**: lo (loopback)
- **Always Present**: Available even without network

### Network Monitoring
```bash
# Network interface statistics
ip -s link show

# Detailed network monitoring
ss -tuln                    # Listening ports
ss -tun                     # All connections
netstat -tuln              # Legacy equivalent

# Real-time monitoring
iftop                       # Interface traffic
nethogs                     # Per-process network usage
```

---

## Key Files and Directories

### Configuration Files
- `/etc/NetworkManager/NetworkManager.conf` - NetworkManager main config
- `/etc/NetworkManager/system-connections/` - NetworkManager connections
- `/etc/netplan/` - Netplan configuration files
- `/etc/hosts` - Local hostname resolution
- `/etc/resolv.conf` - DNS configuration
- `/etc/nsswitch.conf` - Name service configuration
- `/etc/services` - Port to service mapping
- `/etc/wpa_supplicant.conf` - Wireless authentication

### System Files
- `/proc/net/route` - Kernel routing table
- `/proc/net/dev` - Network interface statistics
- `/sys/class/net/` - Network interface information
- `/var/lib/dhcp/dhclient.leases` - DHCP lease information

---

## Troubleshooting Commands

### Network Connectivity
```bash
# Test connectivity
ping -c 4 8.8.8.8           # Test internet
ping -c 4 gateway_ip        # Test local gateway
ping -c 4 local_host        # Test local network

# Trace route to destination
traceroute destination
tracepath destination        # Alternative

# DNS testing
nslookup hostname
dig hostname
host hostname
```

### Interface Status
```bash
# Check interface status
ip link show
ip addr show

# Check for carrier (physical connection)
cat /sys/class/net/eth0/carrier

# Hardware details
ethtool eth0
lspci | grep -i network     # PCI network devices
lsusb | grep -i network     # USB network devices
```

### Process and Port Monitoring
```bash
# What's using a port
lsof -i :80                 # Port 80
lsof -i tcp:22              # TCP port 22
fuser -n tcp 80            # Alternative

# Network-related processes
ps aux | grep -E '(dhcp|network|wpa)'
```

---

## Security Considerations

### Network Security Best Practices
- **Minimize Attack Surface**: Disable unnecessary services
- **Use Encryption**: SSH instead of Telnet, HTTPS instead of HTTP
- **Firewall Configuration**: Block unused ports
- **Regular Updates**: Keep network software updated
- **Monitor Logs**: Watch for suspicious activity

### Common Vulnerabilities
- **Open Ports**: Unnecessary services listening
- **Weak Authentication**: Default passwords, weak keys
- **Unencrypted Traffic**: Clear text protocols
- **Misconfigured Firewalls**: Too permissive rules

---

## Summary

Chapter 9 covers the fundamental concepts of Linux networking, from basic network layers to advanced configuration topics. Key takeaways for engineers:

1. **Understand the Four-Layer Model**: Application, Transport, Internet, Physical
2. **Master the ip Command**: Modern tool for network configuration
3. **Learn Routing Basics**: How packets find their destination
4. **Use Network Managers**: NetworkManager for desktop, systemd-networkd for servers
5. **Implement Security**: Firewalls, encryption, minimal services
6. **Troubleshoot Systematically**: Layer by layer approach

The most important skill is understanding how different layers interact and being able to configure and troubleshoot each layer independently. Modern Linux systems provide powerful tools for network management, but understanding the underlying concepts is crucial for effective system administration and engineering work.