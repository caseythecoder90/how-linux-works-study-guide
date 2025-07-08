# Chapter 10: Network Applications and Services - Notes

## Chapter Overview
This chapter focuses on the application layer of networking—where actual useful work happens. While Chapter 9 covered network infrastructure (IP addresses, routing, interfaces), this chapter explores the programs that users and administrators interact with: web servers, email servers, SSH, and the tools used to diagnose and secure network services.

## Key Concepts

### The Application Layer
**Definition**: The topmost layer of the network stack where user-space applications communicate over the network.

**Why it matters**: This is where actual services run—web servers, email, file sharing, remote access. Understanding this layer is essential for system administration.

**Key characteristics**:
- Runs entirely in user space (not kernel)
- Uses transport layer protocols (TCP/UDP) for communication
- Implements specific protocols (HTTP, SSH, SMTP, etc.)
- Provides services that end users actually use

**Examples**:
```bash
# Application layer protocols in action
curl http://example.com          # HTTP client
ssh user@server.com             # SSH client
telnet mail.example.com 25     # SMTP connection
```

---

### The Basics of Network Services

**Definition**: Network services are server programs that listen on specific ports and respond to client requests.

**Client-Server Model**:
- **Client**: Initiates connections, requests services
- **Server**: Listens for connections, provides services
- **Port**: Standardized endpoint for specific services

**Common Network Services**:
```bash
# Web services
HTTP (port 80)         # Unencrypted web traffic
HTTPS (port 443)       # Encrypted web traffic

# Remote access
SSH (port 22)          # Secure shell
Telnet (port 23)       # Insecure remote access

# Email
SMTP (port 25)         # Mail transfer
POP3 (port 110)        # Mail retrieval
IMAP (port 143)        # Mail access

# File services
FTP (port 21)          # File transfer
SFTP (port 22)         # Secure file transfer
NFS (port 2049)        # Network file system

# System services
DNS (port 53)          # Domain name resolution
DHCP (ports 67/68)     # Dynamic IP assignment
```

**Example: Manual HTTP Connection**:
```bash
# Connect to web server manually
telnet example.org 80

# Send HTTP request
GET / HTTP/1.1
Host: example.org
[Enter twice]

# Server responds with HTTP headers and HTML content
```

---

### Network Server Operation

**Definition**: Network servers are daemon processes that provide services to network clients.

**Why it matters**: Understanding server operation helps with configuration, troubleshooting, and security.

**Server Process Model**:
1. **Listening Process**: Binds to a port and waits for connections
2. **Worker Process**: Handles individual client connections
3. **Forking**: Parent process creates child processes for each connection

**Example Server Operation**:
```bash
# Check what's listening on ports
netstat -tlnp
# Shows:
# Proto  Local Address    PID/Program name
# tcp    0.0.0.0:22      1234/sshd
# tcp    0.0.0.0:80      5678/apache2

# View server processes
ps aux | grep sshd
# Shows parent listener and child worker processes
```

**Common Network Servers**:
- **httpd/apache2/nginx**: Web servers
- **sshd**: Secure shell daemon
- **postfix/sendmail**: Mail servers
- **smbd/nmbd**: Samba file sharing
- **cupsd**: Print server
- **nfsd**: NFS file server

---

### Secure Shell (SSH)

**Definition**: SSH is the standard for secure remote access to Unix/Linux systems, replacing insecure protocols like telnet.

**Why it matters**: SSH is essential for remote system administration and provides secure encrypted communication.

**SSH Features**:
- **Encryption**: All data encrypted in transit
- **Authentication**: Public key and password authentication
- **Tunneling**: Can tunnel other protocols (X11, port forwarding)
- **File Transfer**: Secure file copying with scp/sftp

**SSH Components**:
```bash
# SSH client
ssh user@hostname
ssh -p 2222 user@hostname        # Custom port
ssh -X user@hostname             # X11 forwarding
ssh -L 8080:localhost:80 user@host # Port forwarding

# SSH file transfer
scp file.txt user@host:/path/    # Copy file to remote
scp user@host:/path/file.txt .   # Copy file from remote
sftp user@hostname               # Interactive file transfer

# SSH key management
ssh-keygen -t rsa -b 4096        # Generate key pair
ssh-copy-id user@hostname        # Copy public key to remote
```

**SSH Server Configuration** (`/etc/ssh/sshd_config`):
```bash
# Key configuration options
Port 22                          # Listening port
PermitRootLogin no              # Disable root login
PasswordAuthentication yes       # Allow password auth
PubkeyAuthentication yes        # Allow key auth
MaxAuthTries 3                  # Limit login attempts
ClientAliveInterval 300         # Keep connections alive

# Restart SSH service after changes
systemctl restart sshd
```

**SSH Security Best Practices**:
```bash
# Change default port
Port 2222

# Disable root login
PermitRootLogin no

# Use key-based authentication
PasswordAuthentication no
PubkeyAuthentication yes

# Limit user access
AllowUsers alice bob
DenyUsers root

# Enable fail2ban protection
fail2ban-client status sshd
```

---

### Network Diagnostic Tools

**Definition**: Tools for troubleshooting network services, connections, and communication.

**Why it matters**: Network problems are common, and these tools are essential for diagnosis and resolution.

#### lsof (List Open Files)
**Purpose**: Shows open files and network connections by processes.

**Common usage**:
```bash
# Show all network connections
lsof -i

# Show connections on specific port
lsof -i :80
lsof -i :22

# Show connections by specific process
lsof -p 1234

# Show connections by program name
lsof -c sshd

# Show TCP connections only
lsof -i tcp

# Show UDP connections only
lsof -i udp

# Show listening ports only
lsof -i -sTCP:LISTEN
```

**Example output**:
```bash
$ lsof -i :22
COMMAND  PID USER   FD   TYPE DEVICE SIZE/OFF NODE NAME
sshd     980 root    3u  IPv4  12345      0t0  TCP *:ssh (LISTEN)
sshd    1234 alice   3u  IPv4  12346      0t0  TCP server:ssh->client:54321 (ESTABLISHED)
```

#### tcpdump (Packet Capture)
**Purpose**: Captures and analyzes network packets at a low level.

**Common usage**:
```bash
# Capture packets on interface
tcpdump -i eth0

# Capture packets on specific port
tcpdump port 80
tcpdump port 22

# Capture packets from/to specific host
tcpdump host example.com
tcpdump src example.com
tcpdump dst example.com

# Capture with more detail
tcpdump -v -i eth0
tcpdump -vv -i eth0               # Very verbose
tcpdump -X port 80               # Show packet contents in hex

# Save captures to file
tcpdump -w capture.pcap port 80
tcpdump -r capture.pcap          # Read from file

# Filter by protocol
tcpdump tcp
tcpdump udp
tcpdump icmp
```

**Example packet capture**:
```bash
$ tcpdump -i eth0 port 22
14:23:15.123456 IP client.54321 > server.ssh: Flags [P.], seq 1:37, ack 1, win 65535
14:23:15.123500 IP server.ssh > client.54321: Flags [.], ack 37, win 65535
```

#### netcat (Network Swiss Army Knife)
**Purpose**: Versatile tool for creating network connections, port scanning, and debugging.

**Common usage**:
```bash
# Connect to a service
nc example.com 80
nc -v example.com 22            # Verbose connection

# Listen on a port (server mode)
nc -l 8080                      # Listen on port 8080
nc -l -p 8080                   # Alternative syntax

# Port scanning
nc -z example.com 20-25         # Scan ports 20-25
nc -zv example.com 80           # Verbose port check

# File transfer
# On receiver:
nc -l 8080 > received_file.txt
# On sender:
nc receiver_ip 8080 < file_to_send.txt

# Chat between systems
# On system 1:
nc -l 8080
# On system 2:
nc system1_ip 8080

# UDP mode
nc -u example.com 53            # UDP connection
nc -ul 8080                     # UDP listener
```

#### nmap (Network Mapper)
**Purpose**: Network discovery and port scanning tool.

**Common usage**:
```bash
# Basic host scan
nmap example.com

# Scan specific ports
nmap -p 22,80,443 example.com
nmap -p 1-1000 example.com      # Port range

# Service detection
nmap -sV example.com            # Detect service versions
nmap -sS example.com            # SYN scan (stealth)
nmap -sU example.com            # UDP scan

# Network discovery
nmap 192.168.1.0/24             # Scan entire subnet
nmap -sn 192.168.1.0/24         # Ping scan only

# OS detection
nmap -O example.com

# Aggressive scan
nmap -A example.com             # Enable OS detection, version detection, script scanning
```

**Example nmap output**:
```bash
$ nmap example.com
PORT     STATE SERVICE
22/tcp   open  ssh
80/tcp   open  http
443/tcp  open  https
```

---

### Network Security Fundamentals

**Definition**: Protecting network services and communications from unauthorized access and attacks.

**Why it matters**: Network services are primary attack vectors; proper security is essential for system protection.

**Common Vulnerabilities**:
1. **Unencrypted protocols**: telnet, FTP, HTTP
2. **Default passwords**: Unchanged default credentials
3. **Unnecessary services**: Services running when not needed
4. **Outdated software**: Unpatched vulnerabilities
5. **Weak authentication**: Poor password policies
6. **Open ports**: Unnecessary exposed services

**Security Best Practices**:
```bash
# 1. Use encrypted protocols
ssh instead of telnet
https instead of http
sftp instead of ftp

# 2. Disable unnecessary services
systemctl disable telnet
systemctl stop ftpd

# 3. Change default ports (security through obscurity)
# /etc/ssh/sshd_config
Port 2222

# 4. Implement access controls
# /etc/hosts.allow
sshd: 192.168.1.0/24

# /etc/hosts.deny
sshd: ALL

# 5. Use fail2ban for intrusion prevention
apt install fail2ban
systemctl enable fail2ban
```

**Firewall Configuration**:
```bash
# Using iptables
iptables -A INPUT -p tcp --dport 22 -j ACCEPT     # Allow SSH
iptables -A INPUT -p tcp --dport 80 -j ACCEPT     # Allow HTTP
iptables -A INPUT -j DROP                         # Drop everything else

# Using ufw (Ubuntu)
ufw allow 22
ufw allow 80
ufw enable

# Using firewalld (RHEL/CentOS)
firewall-cmd --permanent --add-service=ssh
firewall-cmd --permanent --add-service=http
firewall-cmd --reload
```

---

### fail2ban - Intrusion Prevention

**Definition**: Service that monitors log files for suspicious activity and automatically blocks IP addresses.

**Why it matters**: Prevents brute force attacks and automated exploitation attempts.

**Configuration**:
```bash
# Install fail2ban
apt install fail2ban

# Configuration files
/etc/fail2ban/jail.conf          # Default configuration
/etc/fail2ban/jail.local         # Local overrides

# Example jail.local
[DEFAULT]
bantime = 3600                   # Ban for 1 hour
findtime = 600                   # Within 10 minutes
maxretry = 3                     # 3 failures

[sshd]
enabled = true
port = ssh
filter = sshd
logpath = /var/log/auth.log
maxretry = 3

# Manage fail2ban
systemctl start fail2ban
systemctl enable fail2ban

# Monitor fail2ban
fail2ban-client status
fail2ban-client status sshd
fail2ban-client unban 192.168.1.100
```

---

### Legacy Network Services

**Definition**: Older network service management systems still found on some systems.

#### inetd/xinetd
**Purpose**: "Super-server" that manages multiple network services from a single daemon.

**Why to know**: Still found on older systems, largely replaced by systemd.

**inetd configuration** (`/etc/inetd.conf`):
```bash
# service_name socket_type proto flags user server_path args
ftp     stream  tcp     nowait  root    /usr/sbin/ftpd      ftpd
telnet  stream  tcp     nowait  root    /usr/sbin/telnetd   telnetd
```

**xinetd configuration** (`/etc/xinetd.d/service`):
```bash
service ftp
{
    disable         = no
    socket_type     = stream
    protocol        = tcp
    wait            = no
    user            = root
    server          = /usr/sbin/ftpd
}
```

---

### Network Sockets Programming

**Definition**: Programming interfaces that applications use to communicate over networks.

**Why it matters**: Understanding sockets helps with network troubleshooting and development.

**Socket Types**:
1. **TCP Sockets**: Reliable, connection-oriented
2. **UDP Sockets**: Unreliable, connectionless
3. **Unix Domain Sockets**: Local inter-process communication

**Socket Programming Concepts**:
```c
// Basic TCP socket operations (C example)
socket()     // Create socket
bind()       // Bind to address/port
listen()     // Listen for connections (server)
accept()     // Accept connection (server)
connect()    // Connect to server (client)
send()       // Send data
recv()       // Receive data
close()      // Close socket
```

**Socket Information**:
```bash
# View socket statistics
ss -tlnp                        # TCP listening sockets
ss -ulnp                        # UDP listening sockets
ss -a                           # All sockets

# Network statistics
netstat -tlnp                   # TCP listening (older tool)
netstat -i                      # Interface statistics
netstat -r                      # Routing table
```

---

### Unix Domain Sockets

**Definition**: Special socket files used for inter-process communication on the same system.

**Why it matters**: Many system services use Unix sockets for local communication.

**Characteristics**:
- Appear as files in filesystem
- Faster than network sockets for local communication
- Used by systemd, Docker, databases, etc.

**Examples**:
```bash
# Find Unix domain sockets
find /tmp /var/run -type s      # Socket files
lsof -U                         # Unix domain socket connections

# Common Unix socket locations
/var/run/docker.sock            # Docker daemon
/tmp/.X11-unix/X0              # X Window System
/var/lib/mysql/mysql.sock      # MySQL database
```

---

## Summary

### Key Takeaways
1. **Application layer is where useful work happens**: Web servers, email, file sharing, remote access
2. **Client-server model is fundamental**: Clients request services, servers provide them
3. **SSH is essential for secure remote access**: Replaces insecure protocols like telnet
4. **Diagnostic tools are crucial**: lsof, tcpdump, netcat, and nmap for troubleshooting
5. **Security requires multiple layers**: Encryption, authentication, access control, monitoring
6. **Network services run as daemons**: Understanding process models helps with management

### Essential Command Patterns
```bash
# Service interaction
telnet host port                # Manual service testing
curl -v http://example.com      # HTTP debugging
ssh user@host                   # Secure remote access

# Diagnostics
lsof -i :port                   # Who's using this port?
tcpdump port 80                 # What's happening on this port?
nc -zv host port               # Is this port open?
nmap host                       # What services are running?

# Security
fail2ban-client status          # Check intrusion prevention
iptables -L                     # Check firewall rules
ss -tlnp                        # What's listening?
```

### Best Practices
1. **Always use encrypted protocols** when possible (SSH vs telnet, HTTPS vs HTTP)
2. **Monitor your services** with appropriate logging and alerting
3. **Keep software updated** to patch security vulnerabilities
4. **Use fail2ban** or similar tools to prevent brute force attacks
5. **Regularly scan your systems** to identify unnecessary open ports
6. **Implement proper access controls** and authentication mechanisms

---

## Personal Notes
- Network security is an ongoing process, not a one-time configuration
- Understanding packet flow helps tremendously with troubleshooting
- Many network problems are actually service configuration issues
- Always test network changes in safe environments first
- Documentation of network configurations is essential for maintenance