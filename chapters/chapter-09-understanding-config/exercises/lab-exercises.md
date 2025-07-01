# Chapter 9: Network Configuration - Practical Exercises

## Prerequisites
- Linux VM or lab environment
- Root/sudo access
- Basic familiarity with command line
- Network connectivity for testing

**⚠️ Warning**: These exercises modify network configuration. Have a backup plan to restore connectivity if needed.

---

## Exercise 1: Basic Network Discovery and Configuration

### Objective
Learn to identify and configure network interfaces using modern tools.

### Tasks

#### 1.1 Network Interface Discovery
```bash
# 1. List all network interfaces
ip addr show

# 2. Identify your primary network interface name
# Record the interface name (e.g., eth0, enp0s3, etc.)

# 3. Show only your primary interface
ip addr show [your_interface_name]

# 4. Check interface statistics
ip -s link show [your_interface_name]

# 5. Compare with legacy command
ifconfig [your_interface_name]
```

**Questions:**
- What is your primary interface name?
- What is your current IP address and subnet?
- How many packets have been transmitted/received?

#### 1.2 Manual IP Configuration
```bash
# 1. Record current configuration
ip addr show [interface] > /tmp/original_config.txt

# 2. Add a secondary IP address
sudo ip addr add 192.168.100.50/24 dev [interface]

# 3. Verify the addition
ip addr show [interface]

# 4. Test the new IP (if possible)
ping -c 3 -I 192.168.100.50 127.0.0.1

# 5. Remove the secondary IP
sudo ip addr del 192.168.100.50/24 dev [interface]

# 6. Verify removal
ip addr show [interface]
```

**Expected Results:**
- Secondary IP should appear in interface listing
- Ping should work with new IP as source
- IP should be cleanly removed

---

## Exercise 2: Routing Table Management

### Objective
Understand and manipulate kernel routing tables.

### Tasks

#### 2.1 Route Analysis
```bash
# 1. Display current routing table
ip route show

# 2. Identify default gateway
ip route show default

# 3. Show route to specific destination
ip route get 8.8.8.8

# 4. Display detailed route information
ip route show table all

# 5. Compare with legacy command
route -n
```

**Questions:**
- What is your default gateway IP?
- What interface is used for the default route?
- How many total routes are configured?

#### 2.2 Static Route Configuration
```bash
# 1. Save current routes
ip route show > /tmp/original_routes.txt

# 2. Add a static route to test network
sudo ip route add 203.0.113.0/24 via [your_gateway_ip]

# 3. Verify route addition
ip route show | grep 203.0.113

# 4. Test route (this will likely fail - that's expected)
ping -c 2 203.0.113.1

# 5. Remove the test route
sudo ip route del 203.0.113.0/24

# 6. Verify removal
ip route show | grep 203.0.113 || echo "Route removed successfully"
```

**Expected Results:**
- Route should appear in routing table
- Ping will likely timeout (test network doesn't exist)
- Route should be cleanly removed

---

## Exercise 3: DNS Configuration and Testing

### Objective
Master DNS configuration and troubleshooting techniques.

### Tasks

#### 3.1 DNS Configuration Analysis
```bash
# 1. Examine current DNS configuration
cat /etc/resolv.conf

# 2. Check name resolution order
cat /etc/nsswitch.conf | grep hosts

# 3. View local hostname resolution
cat /etc/hosts

# 4. Check system hostname
hostname
hostnamectl status
```

#### 3.2 DNS Testing and Troubleshooting
```bash
# 1. Test basic DNS resolution
host google.com

# 2. Use different DNS tools
nslookup google.com
dig google.com

# 3. Test specific DNS servers
dig @8.8.8.8 google.com
dig @1.1.1.1 google.com

# 4. Perform reverse DNS lookup
host 8.8.8.8
dig -x 8.8.8.8

# 5. Trace DNS resolution path
dig +trace google.com

# 6. Test with custom hosts entry
echo "127.0.0.1 testhost.local" | sudo tee -a /etc/hosts
ping testhost.local
# Clean up
sudo sed -i '/testhost.local/d' /etc/hosts
```

**Questions:**
- What DNS servers are configured?
- Do different DNS servers return the same results?
- How long does DNS resolution take?

---

## Exercise 4: Network Connectivity Troubleshooting

### Objective
Develop systematic network troubleshooting skills.

### Tasks

#### 4.1 Connectivity Testing
```bash
# 1. Test local connectivity
ping -c 3 127.0.0.1

# 2. Test gateway connectivity
ping -c 3 [your_gateway_ip]

# 3. Test external connectivity
ping -c 3 8.8.8.8

# 4. Test DNS-dependent connectivity
ping -c 3 google.com

# 5. Trace packet path
traceroute 8.8.8.8
tracepath google.com

# 6. Use MTR for continuous tracing
mtr --report-cycles=5 google.com
```

#### 4.2 Port and Service Testing
```bash
# 1. Check listening ports
ss -tulpn | head -20

# 2. Test specific service ports
nc -zv google.com 80
nc -zv google.com 443

# 3. Test SSH connectivity
nc -zv [your_gateway_ip] 22

# 4. Show active network connections
ss -tn | head -10

# 5. Monitor network statistics
watch -n 2 'ss -s'
# Press Ctrl+C to stop after observing
```

**Expected Results:**
- Local and gateway pings should succeed
- External connectivity should work
- Traceroute should show packet path
- Port tests should show open/closed status

---

## Exercise 5: DHCP and Network Services

### Objective
Understand DHCP client operations and network service dependencies.

### Tasks

#### 5.1 DHCP Analysis (if using DHCP)
```bash
# 1. Check current DHCP lease
cat /var/lib/dhcp/dhclient.leases

# 2. Show DHCP process (if running)
ps aux | grep dhclient

# 3. Release current DHCP lease
sudo dhclient -r [interface]

# 4. Check connectivity (should fail)
ping -c 2 8.8.8.8

# 5. Request new DHCP lease
sudo dhclient [interface]

# 6. Verify connectivity restored
ping -c 2 8.8.8.8

# 7. Check new lease information
ip addr show [interface]
```

#### 5.2 Network Service Testing
```bash
# 1. Check NetworkManager status
systemctl status NetworkManager

# 2. List NetworkManager connections
nmcli connection show

# 3. Show device status
nmcli device status

# 4. Test network connectivity with nmcli
nmcli general status

# 5. Monitor NetworkManager logs
sudo journalctl -u NetworkManager -f &
# Let it run for 30 seconds, then stop with:
sudo pkill journalctl
```

**Expected Results:**
- DHCP release should remove IP address
- DHCP request should restore connectivity
- NetworkManager should show active status

---

## Exercise 6: Network Monitoring and Analysis

### Objective
Learn to monitor network traffic and performance.

### Tasks

#### 6.1 Traffic Monitoring
```bash
# 1. Monitor interface statistics
watch -n 1 'cat /proc/net/dev'
# Press Ctrl+C after observing for 30 seconds

# 2. Capture network traffic (run in background)
sudo tcpdump -i [interface] -c 20 -w /tmp/traffic.pcap &

# 3. Generate some traffic
ping -c 5 google.com
curl -s http://httpbin.org/ip

# 4. Wait for capture to complete
wait

# 5. Analyze captured traffic
sudo tcpdump -r /tmp/traffic.pcap

# 6. Show packet details
sudo tcpdump -r /tmp/traffic.pcap -v
```

#### 6.2 Performance Testing
```bash
# 1. Test network latency
ping -c 10 8.8.8.8 | tail -1

# 2. Test with different packet sizes
ping -c 5 -s 1024 8.8.8.8

# 3. Test bandwidth (if iperf3 available)
# Server (run on another machine if available):
# iperf3 -s

# Client (if server available):
# iperf3 -c [server_ip]

# 4. Monitor real-time network usage
# Install if not available: sudo apt install iftop
# sudo iftop -i [interface]
# Run for 30 seconds, then press 'q' to quit

# 5. Check network buffer usage
cat /proc/net/sockstat
```

**Expected Results:**
- Traffic capture should show actual packets
- Latency should be consistent and reasonable
- Network statistics should show current usage

---

## Exercise 7: Wireless Configuration (if wireless available)

### Objective
Configure wireless networking using command-line tools.

### Tasks

#### 7.1 Wireless Discovery
```bash
# 1. List wireless interfaces
iw dev

# 2. Check wireless capabilities
iw list | head -50

# 3. Scan for available networks
sudo iw [wireless_interface] scan | grep -E "SSID|signal"

# 4. Show current wireless connection
iwconfig [wireless_interface]

# 5. Check wireless statistics
cat /proc/net/wireless
```

#### 7.2 NetworkManager Wireless (if available)
```bash
# 1. Show available WiFi networks
nmcli dev wifi list

# 2. Show current WiFi status
nmcli dev wifi

# 3. Show saved WiFi connections
nmcli connection show --active

# 4. Get detailed connection info
nmcli connection show [connection_name]

# Note: Don't actually connect to unknown networks
# This is just to practice the commands
```

**Expected Results:**
- Wireless interfaces should be detected
- Available networks should be listed
- Current connection details should display

---

## Exercise 8: Advanced Network Configuration

### Objective
Explore advanced networking features and configurations.

### Tasks

#### 8.1 Network Namespace Exploration
```bash
# 1. List current network namespaces
ip netns list

# 2. Create a test namespace
sudo ip netns add test_ns

# 3. List namespaces again
ip netns list

# 4. Execute command in namespace
sudo ip netns exec test_ns ip addr show

# 5. Show namespace routing
sudo ip netns exec test_ns ip route show

# 6. Test connectivity from namespace
sudo ip netns exec test_ns ping -c 2 127.0.0.1

# 7. Clean up namespace
sudo ip netns delete test_ns
```

#### 8.2 Advanced Route Configuration
```bash
# 1. Show routing tables
ip route show table all

# 2. Create custom routing table entry
echo "200 custom" | sudo tee -a /etc/iproute2/rt_tables

# 3. Add route to custom table
sudo ip route add 192.168.200.0/24 via [gateway] table custom

# 4. Show custom table
ip route show table custom

# 5. Clean up
sudo ip route del 192.168.200.0/24 table custom
sudo sed -i '/custom/d' /etc/iproute2/rt_tables
```

**Expected Results:**
- Network namespace should isolate network view
- Custom routing tables should be configurable
- Routes should be cleanly added and removed

---

## Exercise 9: Firewall and Security Basics

### Objective
Understand basic network security and firewall configuration.

### Tasks

#### 9.1 Firewall Status Check
```bash
# 1. Check iptables rules
sudo iptables -L -n -v

# 2. Check UFW status (Ubuntu)
sudo ufw status verbose || echo "UFW not available"

# 3. Check firewalld status (CentOS/RHEL)
sudo firewall-cmd --state || echo "firewalld not available"

# 4. Show listening services
ss -tulpn | grep LISTEN
```

#### 9.2 Port Scanning and Analysis
```bash
# 1. Scan localhost ports
nmap localhost

# 2. Scan specific port range
nmap -p 1-100 localhost

# 3. Show detailed service info
nmap -sV localhost

# 4. Check for common vulnerabilities (be careful!)
nmap --script vuln localhost || echo "Vuln scripts not available"

# 5. Analyze specific service
nc -v localhost 22 < /dev/null
```

**Expected Results:**
- Firewall status should be visible
- Port scans should show open services
- Service versions should be detectable

---

## Exercise 10: Network Configuration Troubleshooting Scenario

### Objective
Apply all learned skills to diagnose and fix network issues.

### Scenario Setup
```bash
# We'll simulate network issues and practice fixing them
# WARNING: This will temporarily break networking!

# 1. Document current working configuration
ip addr show > /tmp/working_config.txt
ip route show > /tmp/working_routes.txt
cat /etc/resolv.conf > /tmp/working_dns.txt

# 2. Create backup script for recovery
cat > /tmp/restore_network.sh << 'EOF'
#!/bin/bash
echo "Restoring network configuration..."
# Add your specific restore commands here
sudo dhclient [your_interface] || sudo systemctl restart NetworkManager
echo "Network restoration attempted"
EOF
chmod +x /tmp/restore_network.sh
```

### Troubleshooting Tasks

#### Scenario 1: DNS Resolution Failure
```bash
# 1. Simulate DNS issue
sudo cp /etc/resolv.conf /tmp/resolv.conf.backup
echo "nameserver 192.0.2.1" | sudo tee /etc/resolv.conf

# 2. Test the issue
ping -c 2 google.com
# Should fail with "Temporary failure in name resolution"

# 3. Diagnose using systematic approach
ping -c 2 8.8.8.8    # Should work (IP connectivity good)
cat /etc/resolv.conf  # Should show bad DNS server

# 4. Fix the issue
sudo cp /tmp/resolv.conf.backup /etc/resolv.conf

# 5. Verify fix
ping -c 2 google.com  # Should work again
```

#### Scenario 2: Routing Issue
```bash
# 1. Simulate routing issue (careful!)
sudo ip route save > /tmp/routes.backup
GATEWAY=$(ip route show default | awk '/default/ {print $3}')
sudo ip route del default

# 2. Test the issue
ping -c 2 8.8.8.8    # Should fail

# 3. Diagnose
ip route show         # No default route
ping -c 2 [gateway_ip] # Should work (local network OK)

# 4. Fix the issue
sudo ip route add default via $GATEWAY

# 5. Verify fix
ping -c 2 8.8.8.8    # Should work
```

### Final Recovery
```bash
# Ensure network is fully restored
/tmp/restore_network.sh

# Verify everything works
ping -c 2 google.com
dig google.com
curl -s http://httpbin.org/ip

# Clean up temporary files
rm -f /tmp/*config.txt /tmp/*routes.txt /tmp/*dns.txt
rm -f /tmp/restore_network.sh /tmp/routes.backup /tmp/resolv.conf.backup
```

---

## Exercise 11: Performance and Optimization

### Objective
Measure and optimize network performance.

### Tasks

#### 11.1 Baseline Measurements
```bash
# 1. Measure basic connectivity metrics
for i in {1..5}; do
    echo "Test $i:"
    ping -c 5 8.8.8.8 | tail -1
    echo ""
done

# 2. Test different MTU sizes
ping -c 3 -s 1472 8.8.8.8  # Should work (1500 MTU)
ping -c 3 -s 1473 8.8.8.8  # Might fragment

# 3. Measure bandwidth to common sites
curl -o /dev/null -s -w "Speed: %{speed_download} bytes/sec\n" \
    http://httpbin.org/stream-bytes/1048576

# 4. Check buffer and queue statistics
ss -i | head -20
```

#### 11.2 Interface Optimization
```bash
# 1. Check current interface settings
ethtool [interface] || echo "ethtool not available"

# 2. Monitor interface errors
watch -n 2 'ip -s link show [interface]'
# Look for errors, drops, overruns (Ctrl+C after observing)

# 3. Check network buffer usage
cat /proc/sys/net/core/rmem_default
cat /proc/sys/net/core/wmem_default
cat /proc/sys/net/ipv4/tcp_rmem
cat /proc/sys/net/ipv4/tcp_wmem
```

**Expected Results:**
- Baseline measurements establish normal performance
- MTU tests show fragmentation behavior
- Interface statistics reveal potential issues

---

## Lab Report Template

### Network Configuration Lab Report

**Date:** ___________  
**Student:** ___________  
**Environment:** ___________

#### Exercise Results Summary

| Exercise | Status | Key Findings | Issues Encountered |
|----------|--------|--------------|-------------------|
| 1. Basic Config | ✓/✗ | | |
| 2. Routing | ✓/✗ | | |
| 3. DNS | ✓/✗ | | |
| 4. Troubleshooting | ✓/✗ | | |
| 5. DHCP | ✓/✗ | | |
| 6. Monitoring | ✓/✗ | | |
| 7. Wireless | ✓/✗ | | |
| 8. Advanced | ✓/✗ | | |
| 9. Security | ✓/✗ | | |
| 10. Scenarios | ✓/✗ | | |
| 11. Performance | ✓/✗ | | |

#### System Information
- **OS Version:** `cat /etc/os-release`
- **Kernel Version:** `uname -r`
- **Network Interfaces:** `ip link show`
- **Default Gateway:** `ip route show default`
- **DNS Servers:** `cat /etc/resolv.conf`

#### Key Commands Learned
List the most important commands you practiced:
1. ___________
2. ___________
3. ___________
4. ___________
5. ___________

#### Configuration Files Modified
List any configuration files you worked with:
- `/etc/resolv.conf` - Purpose: ___________
- `/etc/hosts` - Purpose: ___________
- `/etc/sysctl.conf` - Purpose: ___________
- Other: ___________

#### Troubleshooting Techniques Applied
Describe the systematic approaches you used:
1. **Physical Layer:** ___________
2. **Network Layer:** ___________
3. **Transport Layer:** ___________
4. **Application Layer:** ___________

#### Performance Measurements
Record your baseline measurements:
- **Latency to Gateway:** _____ ms
- **Latency to 8.8.8.8:** _____ ms
- **Download Speed:** _____ MB/s
- **Interface Errors:** _____

#### Questions for Further Study
1. What would happen if you configured two interfaces with the same subnet?
2. How would you troubleshoot asymmetric routing issues?
3. What are the security implications of enabling IP forwarding?
4. How do modern containers handle networking differently?

---

## Additional Challenge Exercises

### Challenge 1: Multi-Interface Configuration
**Scenario:** Configure a system with multiple network interfaces for different purposes.

```bash
# If you have access to VMs with multiple interfaces:
# 1. Configure eth0 for management (192.168.1.0/24)
# 2. Configure eth1 for storage (192.168.10.0/24)
# 3. Configure eth2 for application traffic (192.168.20.0/24)
# 4. Set up routing between networks
# 5. Test connectivity between all networks

# Example commands (adapt to your environment):
sudo ip addr add 192.168.1.100/24 dev eth0
sudo ip addr add 192.168.10.100/24 dev eth1
sudo ip addr add 192.168.20.100/24 dev eth2

# Add specific routes if needed
sudo ip route add 192.168.10.0/24 dev eth1
sudo ip route add 192.168.20.0/24 dev eth2
```

### Challenge 2: Network Security Hardening
**Scenario:** Secure a Linux system's network configuration.

```bash
# 1. Audit current network exposure
sudo nmap -sS localhost
ss -tulpn | grep LISTEN

# 2. Implement basic firewall rules
sudo iptables -F  # Clear existing rules (be careful!)
sudo iptables -P INPUT DROP
sudo iptables -P FORWARD DROP
sudo iptables -P OUTPUT ACCEPT

# 3. Allow essential services only
sudo iptables -A INPUT -i lo -j ACCEPT
sudo iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
sudo iptables -A INPUT -p tcp --dport 22 -j ACCEPT

# 4. Test and document results
sudo nmap -sS localhost
# Document what changed

# 5. Create persistent rules
sudo iptables-save > /tmp/firewall_rules.txt
```

### Challenge 3: Network Performance Tuning
**Scenario:** Optimize network performance for a high-throughput application.

```bash
# 1. Baseline current performance
iperf3 -s &  # If you have another system to test with
# Record baseline speeds

# 2. Tune network buffers
echo 'net.core.rmem_max = 268435456' | sudo tee -a /etc/sysctl.conf
echo 'net.core.wmem_max = 268435456' | sudo tee -a /etc/sysctl.conf
echo 'net.ipv4.tcp_rmem = 4096 87380 268435456' | sudo tee -a /etc/sysctl.conf
echo 'net.ipv4.tcp_wmem = 4096 65536 268435456' | sudo tee -a /etc/sysctl.conf

# 3. Apply changes
sudo sysctl -p

# 4. Test again and compare
# Document performance improvements

# 5. Check interface-specific settings
ethtool -g eth0  # Ring buffer settings
ethtool -k eth0  # Offload settings
```

### Challenge 4: Container Networking
**Scenario:** Understand how containers affect network configuration.

```bash
# If Docker is available:
# 1. Examine default Docker networking
docker network ls
ip addr show docker0

# 2. Create custom network
docker network create --driver bridge custom_net
docker network inspect custom_net

# 3. Compare host vs container networking
ip route show
docker run --rm -it alpine ip route show

# 4. Test connectivity between containers
docker run -d --name test1 --network custom_net alpine sleep 300
docker run -d --name test2 --network custom_net alpine sleep 300
docker exec test1 ping -c 3 test2

# 5. Clean up
docker stop test1 test2
docker rm test1 test2
docker network rm custom_net
```

### Challenge 5: IPv6 Dual-Stack Configuration
**Scenario:** Configure and test IPv6 alongside IPv4.

```bash
# 1. Check current IPv6 status
ip -6 addr show
cat /proc/sys/net/ipv6/conf/all/disable_ipv6

# 2. Enable IPv6 if disabled
echo 0 | sudo tee /proc/sys/net/ipv6/conf/all/disable_ipv6

# 3. Configure IPv6 address (if not auto-configured)
sudo ip -6 addr add 2001:db8::100/64 dev eth0

# 4. Test IPv6 connectivity
ping6 ::1  # IPv6 loopback
ping6 2001:4860:4860::8888  # Google IPv6 DNS

# 5. Compare IPv4 vs IPv6 performance
ping -c 10 google.com
ping6 -c 10 google.com
```

---

## Certification Preparation Questions

### LPIC-1 / CompTIA Linux+ Style Questions

#### Question 1
You need to temporarily assign the IP address 192.168.1.100/24 to interface eth0. Which command accomplishes this?

A) `ifconfig eth0 192.168.1.100 netmask 255.255.255.0`
B) `ip addr add 192.168.1.100/24 dev eth0`
C) `ip link set eth0 192.168.1.100/24`
D) Both A and B

**Answer:** D - Both commands work, though `ip` is preferred

#### Question 2
Which file contains the system's DNS server configuration?

A) `/etc/hosts`
B) `/etc/resolv.conf`
C) `/etc/nsswitch.conf`
D) `/etc/hostname`

**Answer:** B - `/etc/resolv.conf`

#### Question 3
What command displays the kernel routing table using modern tools?

A) `route -n`
B) `netstat -r`
C) `ip route show`
D) All of the above

**Answer:** D - All show routing table, but `ip route show` is preferred

#### Question 4
To enable IP forwarding permanently, you should modify which file?

A) `/proc/sys/net/ipv4/ip_forward`
B) `/etc/sysctl.conf`
C) `/etc/network/interfaces`
D) `/etc/hosts`

**Answer:** B - `/etc/sysctl.conf`

#### Question 5
Which command tests connectivity to a specific port on a remote host?

A) `ping host 80`
B) `telnet host 80`
C) `ping -p 80 host`
D) `route host 80`

**Answer:** B - `telnet host 80`

### Red Hat / CentOS Questions

#### Question 6
In RHEL/CentOS 8+, which service typically manages network configuration?

A) network
B) NetworkManager
C) systemd-networkd
D) networking

**Answer:** B - NetworkManager

#### Question 7
What NetworkManager command shows available WiFi networks?

A) `nmcli dev wifi list`
B) `nmcli connection show`
C) `nmcli device status`
D) `nmcli general status`

**Answer:** A - `nmcli dev wifi list`

### Ubuntu/Debian Questions

#### Question 8
In modern Ubuntu systems, network configuration is typically managed by:

A) `/etc/network/interfaces`
B) Netplan
C) NetworkManager
D) Both B and C

**Answer:** D - Both Netplan and NetworkManager are used

#### Question 9
Which command enables the UFW firewall?

A) `ufw start`
B) `ufw enable`
C) `systemctl enable ufw`
D) `iptables -F`

**Answer:** B - `ufw enable`

### Advanced Questions

#### Question 10
What is the purpose of the `ip netns` command?

A) Configure network interfaces
B) Manage network namespaces
C) Set up network bridges
D) Configure routing tables

**Answer:** B - Manage network namespaces

---

## Real-World Scenarios

### Scenario 1: Remote Server Connectivity Loss
**Problem:** You lose SSH connectivity to a remote server after making network changes.

**Solution Steps:**
1. Use console access if available
2. Check interface status: `ip link show`
3. Verify IP configuration: `ip addr show`
4. Check routing: `ip route show`
5. Restart networking: `systemctl restart NetworkManager`
6. Check firewall: `iptables -L`

### Scenario 2: DNS Resolution Intermittently Failing
**Problem:** Some DNS queries work, others fail randomly.

**Solution Steps:**
1. Test multiple DNS servers: `dig @8.8.8.8 domain.com`
2. Check `/etc/resolv.conf` for multiple nameservers
3. Monitor with: `watch -n 1 'dig google.com +short'`
4. Check network connectivity to DNS servers
5. Consider DNS caching issues

### Scenario 3: Poor Network Performance
**Problem:** Network throughput is much lower than expected.

**Solution Steps:**
1. Baseline test: `iperf3 -c target_server`
2. Check interface errors: `ip -s link show`
3. Test MTU: `ping -s 1472 target` (should work for 1500 MTU)
4. Check duplex settings: `ethtool eth0`
5. Monitor with: `iftop` or `nethogs`
6. Check for bandwidth limiting or QoS

---

## Study Tips for Mastery

### Daily Practice Routine (15-30 minutes)
1. **Week 1-2:** Focus on basic commands (`ip`, `ping`, `ss`)
2. **Week 3-4:** Practice routing and DNS configuration
3. **Week 5-6:** Advanced topics (namespaces, performance tuning)
4. **Week 7-8:** Integration with real-world scenarios

### Command Muscle Memory
Practice these commands until they become automatic:
```bash
ip addr show
ip route show
ss -tulpn
ping -c 3 target
dig domain.com
nmcli device status
systemctl status NetworkManager
```

### Configuration File Locations
Memorize these key files:
- `/etc/resolv.conf` - DNS
- `/etc/hosts` - Local resolution
- `/etc/nsswitch.conf` - Resolution order
- `/etc/sysctl.conf` - Kernel parameters
- `/etc/systemd/network/` - systemd-networkd
- `/etc/NetworkManager/` - NetworkManager
- `/etc/netplan/` - Ubuntu Netplan

### Troubleshooting Methodology
Always follow this systematic approach:
1. **Physical:** Cable, interface up/down
2. **Network:** IP address, subnet, gateway
3. **Transport:** Routing, connectivity tests
4. **Application:** DNS, service-specific tests

---

This comprehensive exercise set provides hands-on experience with all major networking concepts from Chapter 9, preparing you for both real-world system administration and certification exams.