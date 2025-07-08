# Chapter 10: Network Applications and Services - Quick Reference

## Common Network Ports

### Standard Services
```bash
20/21   FTP (File Transfer Protocol)
22      SSH (Secure Shell)
23      Telnet
25      SMTP (Simple Mail Transfer Protocol)
53      DNS (Domain Name System)
67/68   DHCP (Dynamic Host Configuration Protocol)
80      HTTP (Hypertext Transfer Protocol)
110     POP3 (Post Office Protocol v3)
143     IMAP (Internet Message Access Protocol)
443     HTTPS (HTTP Secure)
993     IMAPS (IMAP Secure)
995     POP3S (POP3 Secure)
```

### System Services
```bash
111     RPC Portmapper
139/445 SMB/CIFS (Windows File Sharing)
514     Syslog
631     IPP (Internet Printing Protocol)
2049    NFS (Network File System)
3389    RDP (Remote Desktop Protocol)
5432    PostgreSQL
3306    MySQL
6000+   X11 (X Window System)
```

## SSH (Secure Shell)

### SSH Client Commands
```bash
# Basic connection
ssh user@hostname
ssh user@hostname -p 2222        # Custom port
ssh -v user@hostname             # Verbose (debugging)

# X11 forwarding
ssh -X user@hostname             # Enable X11 forwarding
ssh -Y user@hostname             # Trusted X11 forwarding

# Port forwarding
ssh -L 8080:localhost:80 user@host    # Local port forwarding
ssh -R 8080:localhost:80 user@host    # Remote port forwarding
ssh -D 1080 user@host                 # SOCKS proxy

# Key management
ssh-keygen -t rsa -b 4096        # Generate RSA key pair
ssh-keygen -t ed25519            # Generate Ed25519 key (recommended)
ssh-copy-id user@hostname        # Copy public key to remote host
ssh-add ~/.ssh/id_rsa            # Add key to SSH agent
```

### SSH File Transfer
```bash
# SCP (Secure Copy)
scp file.txt user@host:/path/         # Copy file to remote
scp user@host:/path/file.txt .        # Copy file from remote
scp -r directory/ user@host:/path/    # Copy directory recursively
scp -P 2222 file.txt user@host:/path/ # Custom port

# SFTP (SSH File Transfer Protocol)
sftp user@hostname               # Interactive session
sftp -P 2222 user@hostname       # Custom port

# SFTP commands within session
get remote_file                  # Download file
put local_file                   # Upload file
ls                              # List remote directory
lls                             # List local directory
cd /path                        # Change remote directory
lcd /path                       # Change local directory
```

### SSH Configuration
```bash
# Client config: ~/.ssh/config
Host myserver
    HostName server.example.com
    User myuser
    Port 2222
    IdentityFile ~/.ssh/special_key

# Server config: /etc/ssh/sshd_config
Port 22                         # Listening port
PermitRootLogin no             # Disable root login
PasswordAuthentication no       # Disable password auth
PubkeyAuthentication yes       # Enable key auth
MaxAuthTries 3                 # Limit login attempts
ClientAliveInterval 300        # Keep connections alive

# Restart SSH service
systemctl restart sshd
```

## Network Diagnostic Tools

### lsof (List Open Files)
```bash
# Network connections
lsof -i                         # All network connections
lsof -i :80                     # Connections on port 80
lsof -i tcp                     # TCP connections only
lsof -i udp                     # UDP connections only
lsof -i -sTCP:LISTEN           # Listening TCP ports only

# Process-specific
lsof -p 1234                    # Files opened by process ID
lsof -c sshd                    # Files opened by program name
lsof -u alice                   # Files opened by user

# File-specific
lsof /var/log/syslog           # Who has this file open
lsof +D /var/log               # All files in directory
```

### tcpdump (Packet Capture)
```bash
# Basic capture
tcpdump -i eth0                 # Capture on interface
tcpdump -i any                  # Capture on all interfaces
tcpdump -n                      # Don't resolve hostnames
tcpdump -v                      # Verbose output
tcpdump -X                      # Show packet contents in hex

# Port-based filtering
tcpdump port 80                 # HTTP traffic
tcpdump port 22                 # SSH traffic
tcpdump portrange 20-21         # FTP traffic

# Host-based filtering
tcpdump host example.com        # Traffic to/from host
tcpdump src example.com         # Traffic from host
tcpdump dst example.com         # Traffic to host
tcpdump net 192.168.1.0/24     # Traffic to/from network

# Protocol filtering
tcpdump tcp                     # TCP traffic only
tcpdump udp                     # UDP traffic only
tcpdump icmp                    # ICMP traffic only

# Save/load captures
tcpdump -w capture.pcap port 80 # Save to file
tcpdump -r capture.pcap         # Read from file

# Complex filters
tcpdump 'tcp port 80 and src host 192.168.1.1'
tcpdump 'udp and dst port 53'
```

### netcat (Network Swiss Army Knife)
```bash
# Client mode
nc hostname 80                  # Connect to port 80
nc -v hostname 22              # Verbose connection test
nc -w 5 hostname 80            # 5-second timeout

# Server mode
nc -l 8080                     # Listen on port 8080
nc -l -p 8080                  # Alternative syntax
nc -k -l 8080                  # Keep listening after disconnect

# Port scanning
nc -z hostname 80              # Test if port is open
nc -zv hostname 20-25          # Scan port range
nc -zu hostname 53             # UDP port test

# File transfer
# Receiver:
nc -l 8080 > received_file
# Sender:
nc receiver_ip 8080 < file_to_send

# UDP mode
nc -u hostname 53              # UDP connection
nc -ul 8080                    # UDP listener

# HTTP request with netcat
printf "GET / HTTP/1.1\r\nHost: example.com\r\n\r\n" | nc example.com 80
```

### nmap (Network Mapper)
```bash
# Basic scans
nmap hostname                   # Basic port scan
nmap 192.168.1.0/24            # Scan entire subnet
nmap -sn 192.168.1.0/24        # Ping scan (no port scan)

# Port specifications
nmap -p 80,443 hostname        # Specific ports
nmap -p 1-1000 hostname        # Port range
nmap -p- hostname              # All ports (1-65535)
nmap --top-ports 100 hostname  # Top 100 most common ports

# Scan types
nmap -sS hostname              # SYN stealth scan
nmap -sT hostname              # TCP connect scan
nmap -sU hostname              # UDP scan
nmap -sA hostname              # ACK scan

# Service detection
nmap -sV hostname              # Version detection
nmap -O hostname               # OS detection
nmap -A hostname               # Aggressive scan (OS, version, scripts)

# Performance
nmap -T4 hostname              # Faster timing
nmap -T1 hostname              # Slower, stealthier timing
nmap --max-rate 100 hostname   # Limit packet rate

# IPv6 support
nmap -6 hostname               # IPv6 scan
```

## Network Connection Information

### ss (Socket Statistics)
```bash
# Basic usage
ss -t                          # TCP sockets
ss -u                          # UDP sockets
ss -l                          # Listening sockets only
ss -a                          # All sockets

# Detailed information
ss -n                          # Don't resolve hostnames
ss -p                          # Show process information
ss -e                          # Show extended information

# Common combinations
ss -tlnp                       # TCP listening with processes
ss -ulnp                       # UDP listening with processes
ss -tanp                       # All TCP with processes

# Filtering
ss dst :80                     # Connections to port 80
ss src 192.168.1.1            # Connections from IP
ss state established           # Established connections only
```

### netstat (Network Statistics) - Legacy
```bash
# Similar to ss but older
netstat -tlnp                  # TCP listening with processes
netstat -ulnp                  # UDP listening with processes
netstat -i                     # Interface statistics
netstat -r                     # Routing table
netstat -s                     # Protocol statistics
```

## Manual Protocol Testing

### HTTP Testing
```bash
# Manual HTTP request with telnet
telnet example.com 80
GET / HTTP/1.1
Host: example.com
[Enter twice]

# Using curl for debugging
curl -v http://example.com      # Verbose output
curl -I http://example.com      # Headers only
curl --trace-ascii trace.txt http://example.com
curl -H "User-Agent: MyApp" http://example.com
```

### SMTP Testing
```bash
# Test mail server
telnet mail.example.com 25
HELO client.example.com
MAIL FROM: <sender@example.com>
RCPT TO: <recipient@example.com>
DATA
Subject: Test message

This is a test.
.
QUIT
```

### DNS Testing
```bash
# Host command
host example.com               # Basic lookup
host -t MX example.com         # Mail exchange records
host -t NS example.com         # Name server records
host 8.8.8.8                   # Reverse lookup

# Dig command (more detailed)
dig example.com                # Basic lookup
dig @8.8.8.8 example.com      # Use specific DNS server
dig example.com MX             # Mail exchange records
dig +trace example.com         # Trace DNS resolution
```

## Security Tools

### fail2ban
```bash
# Status and management
fail2ban-client status         # Show all jails
fail2ban-client status sshd    # Show specific jail
fail2ban-client reload         # Reload configuration

# Manual ban/unban
fail2ban-client set sshd banip 192.168.1.100
fail2ban-client set sshd unbanip 192.168.1.100

# Configuration files
/etc/fail2ban/jail.conf        # Default configuration
/etc/fail2ban/jail.local       # Local overrides
```

### Basic Firewall (iptables)
```bash
# View current rules
iptables -L                    # List all rules
iptables -L -n                 # List without name resolution
iptables -L -v                 # Verbose output with packet counts

# Allow specific services
iptables -A INPUT -p tcp --dport 22 -j ACCEPT    # SSH
iptables -A INPUT -p tcp --dport 80 -j ACCEPT    # HTTP
iptables -A INPUT -p tcp --dport 443 -j ACCEPT   # HTTPS

# Block everything else
iptables -A INPUT -j DROP

# Save rules (varies by distribution)
iptables-save > /etc/iptables/rules.v4
```

## Common Network Services

### Web Server Testing
```bash
# Test if web server is running
curl -I http://localhost       # Check headers
nc -zv localhost 80           # Test port connectivity
lsof -i :80                   # See what's using port 80
```

### Mail Server Testing
```bash
# Test SMTP
nc -v mail.example.com 25
telnet mail.example.com 25

# Test POP3
nc -v mail.example.com 110
telnet mail.example.com 110

# Test IMAP
nc -v mail.example.com 143
telnet mail.example.com 143
```

## Quick Troubleshooting Workflow

### 1. Is the service running?
```bash
systemctl status servicename
ps aux | grep servicename
```

### 2. Is it listening on the expected port?
```bash
ss -tlnp | grep :80
lsof -i :80
```

### 3. Can you connect locally?
```bash
nc -zv localhost 80
telnet localhost 80
```

### 4. Can you connect remotely?
```bash
nc -zv remotehost 80
nmap -p 80 remotehost
```

### 5. Check firewall
```bash
iptables -L
ufw status
firewall-cmd --list-all
```

### 6. Check logs
```bash
tail -f /var/log/syslog
journalctl -f -u servicename
```

## Configuration Files

### Important Network Service Configs
```bash
/etc/ssh/sshd_config          # SSH server
/etc/ssh/ssh_config           # SSH client defaults
/etc/hosts                    # Local hostname resolution
/etc/services                 # Port number assignments
/etc/hosts.allow              # TCP wrappers allow
/etc/hosts.deny               # TCP wrappers deny
/etc/fail2ban/jail.local      # fail2ban configuration
```

### Log Files
```bash
/var/log/auth.log             # Authentication attempts
/var/log/syslog               # General system log
/var/log/secure               # Security-related events (RHEL)
/var/log/messages             # General messages (RHEL)
```

## Performance and Monitoring

### Connection Monitoring
```bash
# Watch active connections
watch 'ss -tuln'
watch 'netstat -tuln'

# Monitor specific service
watch 'lsof -i :80'

# Connection statistics
ss -s                         # Socket summary
netstat -s                    # Protocol statistics
```

### Bandwidth Monitoring
```bash
# Simple bandwidth monitoring
iftop                         # Interface traffic
nethogs                       # Per-process network usage
vnstat                        # Network statistics daemon
```