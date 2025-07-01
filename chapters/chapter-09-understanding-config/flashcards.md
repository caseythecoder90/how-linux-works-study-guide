# Chapter 9 Flashcards: Understanding Your Network and Its Configuration

## Network Fundamentals

**Q: What are the four main network layers in the Linux networking model?**
A: Physical Layer (hardware), Network Layer (IP addressing/routing), Transport Layer (TCP/UDP), Application Layer (HTTP/SSH/FTP)

**Q: What is a packet in networking?**
A: A packet is a unit of data that includes source/destination addresses and payload data, used to transmit information across networks

**Q: What does CIDR notation /24 mean?**
A: It means the first 24 bits are the network portion, leaving 8 bits for host addresses (254 usable host IPs in IPv4)

**Q: What are the three private IPv4 address ranges?**
A: 10.0.0.0/8, 172.16.0.0/12, and 192.168.0.0/16

---

## IP Commands and Interface Management

**Q: What command shows all network interfaces and their IP addresses?**
A: `ip addr show` or `ip a s`

**Q: How do you assign an IP address to an interface using the ip command?**
A: `sudo ip addr add 192.168.1.100/24 dev eth0`

**Q: What command brings a network interface up?**
A: `sudo ip link set eth0 up`

**Q: How do you remove an IP address from an interface?**
A: `sudo ip addr del 192.168.1.100/24 dev eth0`

**Q: What is the modern replacement for ifconfig?**
A: The `ip` command (part of iproute2 package)

---

## Routing

**Q: What command displays the kernel routing table?**
A: `ip route show` or `ip r s`

**Q: How do you add a static route to a specific network?**
A: `sudo ip route add 192.168.45.0/24 via 10.23.2.44`

**Q: What is the default route in routing table output?**
A: A route with destination "default" or "0.0.0.0/0" that matches any address not covered by more specific routes

**Q: How do you add a default gateway?**
A: `sudo ip route add default via 192.168.1.1`

**Q: How do you delete a route?**
A: `sudo ip route del 192.168.45.0/24`

---

## DHCP and Network Configuration

**Q: What does DHCP stand for and what does it do?**
A: Dynamic Host Configuration Protocol - automatically assigns IP addresses, subnet masks, default gateways, and DNS servers to clients

**Q: What command requests a DHCP lease for an interface?**
A: `sudo dhclient eth0`

**Q: How do you release a DHCP lease?**
A: `sudo dhclient -r eth0`

**Q: Where are DHCP lease files typically stored?**
A: `/var/lib/dhcp/dhclient.leases`

**Q: What are three common network configuration managers in Linux?**
A: NetworkManager (desktop-focused), systemd-networkd (systemd native), and traditional ifupdown

---

## DNS Configuration

**Q: What file contains DNS server configuration?**
A: `/etc/resolv.conf`

**Q: What file allows local hostname resolution?**
A: `/etc/hosts`

**Q: What file controls the order of name resolution methods?**
A: `/etc/nsswitch.conf`

**Q: What command performs a DNS lookup?**
A: `host hostname`, `nslookup hostname`, or `dig hostname`

**Q: How do you perform a reverse DNS lookup?**
A: `host 8.8.8.8` or `dig -x 8.8.8.8`

---

## Network Troubleshooting

**Q: What command tests network connectivity to a host?**
A: `ping hostname` or `ping IP_address`

**Q: What command shows listening network ports and processes?**
A: `ss -tulpn` or `netstat -tulpn`

**Q: What command traces the path packets take to reach a destination?**
A: `traceroute hostname` or `tracepath hostname`

**Q: How do you capture network traffic for analysis?**
A: `sudo tcpdump -i interface_name`

**Q: What command shows network interface statistics?**
A: `ip -s link show` or `netstat -i`

---

## Wireless Networking

**Q: What command scans for available wireless networks?**
A: `sudo iwlist scan` or `sudo iw dev wlan0 scan`

**Q: What daemon handles WPA/WPA2 wireless authentication?**
A: `wpa_supplicant`

**Q: How do you connect to an open wireless network using iw?**
A: `sudo iw wlan0 connect "NetworkName"`

**Q: What is the default location for wpa_supplicant configuration?**
A: `/etc/wpa_supplicant/wpa_supplicant.conf`

**Q: What NetworkManager command connects to a wireless network?**
A: `nmcli dev wifi connect "NetworkName" password "MyPassword"`

---

## IPv6

**Q: How many bits are in an IPv6 address?**
A: 128 bits

**Q: What is the IPv6 loopback address?**
A: `::1`

**Q: What prefix is used for IPv6 link-local addresses?**
A: `fe80::/64`

**Q: How do you view IPv6 addresses on interfaces?**
A: `ip -6 addr show`

**Q: What is a dual-stack network?**
A: A network that runs both IPv4 and IPv6 protocols simultaneously

---

## Linux Router Configuration

**Q: What kernel parameter enables IP forwarding?**
A: `net.ipv4.ip_forward=1`

**Q: How do you enable IP forwarding temporarily?**
A: `sudo sysctl -w net.ipv4.ip_forward=1`

**Q: Where do you add permanent kernel parameter changes?**
A: `/etc/sysctl.conf` or files in `/etc/sysctl.d/`

**Q: What iptables target is used for NAT?**
A: `MASQUERADE` in the `nat` table's `POSTROUTING` chain

**Q: How do you check if IP forwarding is enabled?**
A: `sysctl net.ipv4.ip_forward` or `cat /proc/sys/net/ipv4/ip_forward`

---

## Network Security Basics

**Q: What command shows current iptables rules?**
A: `sudo iptables -L -n -v`

**Q: How do you allow SSH through UFW firewall?**
A: `sudo ufw allow ssh` or `sudo ufw allow 22`

**Q: What does the iptables MASQUERADE target do?**
A: Performs source NAT, changing the source IP of outgoing packets to the interface's IP address

**Q: How do you scan for open ports on a host?**
A: `nmap hostname` or `nmap IP_address`

**Q: What is the difference between TCP and UDP?**
A: TCP is connection-oriented and reliable (ensures delivery), UDP is connectionless and faster but unreliable

---

## Advanced Networking

**Q: What command creates a VLAN interface?**
A: `sudo ip link add link eth0 name eth0.100 type vlan id 100`

**Q: How do you create a bridge interface?**
A: `sudo ip link add br0 type bridge`

**Q: What module must be loaded for VLAN support?**
A: `8021q` module

**Q: What command shows ARP table entries?**
A: `ip neigh show` or `arp -a`

**Q: How do you add an interface to a bridge?**
A: `sudo ip link set eth0 master br0`

---

## Network Monitoring

**Q: What command shows real-time bandwidth usage by process?**
A: `sudo nethogs`

**Q: What command shows real-time network traffic by connection?**
A: `sudo iftop`

**Q: How do you view historical network usage statistics?**
A: `vnstat` (with options like `-d` for daily, `-m` for monthly)

**Q: What command tests network bandwidth between two hosts?**
A: `iperf3` (server: `iperf3 -s`, client: `iperf3 -c server_ip`)

**Q: Where can you find kernel network statistics?**
A: `/proc/net/` directory

---

## NetworkManager

**Q: What command shows NetworkManager device status?**
A: `nmcli device status` or `nmcli dev status`

**Q: How do you show all NetworkManager connections?**
A: `nmcli connection show`

**Q: What command brings up a NetworkManager connection?**
A: `nmcli connection up "connection_name"`

**Q: How do you reload NetworkManager configuration?**
A: `sudo nmcli connection reload`

**Q: What is the NetworkManager configuration directory?**
A: `/etc/NetworkManager/`

---

## Common Network Issues

**Q: What are the steps to troubleshoot no network connectivity?**
A: 1) Check physical connection, 2) Verify interface is up, 3) Check IP config, 4) Test gateway, 5) Check routing, 6) Test DNS

**Q: How do you test if a network issue is DNS-related?**
A: Try `ping 8.8.8.8` (should work) vs `ping google.com` (may fail if DNS issue)

**Q: What could cause intermittent network connectivity?**
A: DHCP lease expiration, IP conflicts, wireless interference, hardware issues, or routing problems

**Q: How do you check for network interface errors?**
A: `ip -s link show interface_name` or check `/proc/net/dev`

**Q: What indicates a potential IP address conflict?**
A: Duplicate IP address messages in logs, intermittent connectivity, or ARP table inconsistencies

---

## System Files and Directories

**Q: Where are systemd-networkd configuration files located?**
A: `/etc/systemd/network/`

**Q: What directory contains network interface information?**
A: `/sys/class/net/`

**Q: Where does Netplan store configuration files?**
A: `/etc/netplan/`

**Q: What file shows network interface statistics in proc filesystem?**
A: `/proc/net/dev`

**Q: Where are network interface hardware addresses stored?**
A: `/sys/class/net/interface_name/address`

---

## Performance and Optimization

**Q: What causes high network latency?**
A: Network congestion, routing issues, DNS delays, physical distance, or hardware problems

**Q: How do you monitor network buffer usage?**
A: Check `/proc/net/sockstat` and use `ss -m` for socket memory info

**Q: What command shows TCP connection states?**
A: `ss -t` or `netstat -t`

**Q: How do you test maximum network throughput?**
A: Use `iperf3` between two hosts with `iperf3 -s` (server) and `iperf3 -c server_ip` (client)

**Q: What could cause packet loss?**
A: Network congestion, faulty hardware, buffer overflows, or misconfigured routing