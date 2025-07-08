# Chapter 10: Network Applications and Services - Flashcards

## Basic Concepts

### Card 1
**Q:** What is the application layer in network communication?
**A:** The topmost layer of the network stack where user-space applications communicate, implementing protocols like HTTP, SSH, FTP, etc.

### Card 2
**Q:** What's the difference between a network client and a network server?
**A:** Client initiates connections and requests services; server listens for connections and provides services.

### Card 3
**Q:** What command allows you to manually connect to a web server on port 80?
**A:** `telnet example.org 80`

### Card 4
**Q:** What is the standard port for HTTP? HTTPS? SSH?
**A:** HTTP: 80, HTTPS: 443, SSH: 22

### Card 5
**Q:** How do most network servers handle multiple simultaneous connections?
**A:** They use fork() to create child processes - parent listens on port, children handle individual connections.

## SSH (Secure Shell)

### Card 6
**Q:** What are the main advantages of SSH over telnet?
**A:** SSH encrypts all data (including passwords), supports key authentication, and can tunnel other protocols.

### Card 7
**Q:** What command copies your SSH public key to a remote server?
**A:** `ssh-copy-id user@hostname`

### Card 8
**Q:** How do you generate a new SSH key pair?
**A:** `ssh-keygen -t rsa -b 4096` (or similar with different types/sizes)

### Card 9
**Q:** What's the difference between scp and sftp?
**A:** scp works like cp for copying files over SSH; sftp provides an interactive file transfer session like old FTP.

### Card 10
**Q:** How do you enable X11 forwarding with SSH?
**A:** `ssh -X user@hostname`

### Card 11
**Q:** What file contains the SSH server configuration?
**A:** `/etc/ssh/sshd_config`

### Card 12
**Q:** How do you change the SSH server port from the default?
**A:** Edit `/etc/ssh/sshd_config` and change `Port 22` to desired port, then restart sshd.

## Diagnostic Tools

### Card 13
**Q:** What does the lsof command do?
**A:** Lists open files, including network connections and listening ports by processes.

### Card 14
**Q:** How do you see all processes listening on network ports?
**A:** `lsof -i` or `lsof -i -sTCP:LISTEN` for just listening TCP ports.

### Card 15
**Q:** What command shows which process is using port 80?
**A:** `lsof -i :80`

### Card 16
**Q:** What does tcpdump do?
**A:** Captures and analyzes network packets at the packet level for debugging network communication.

### Card 17
**Q:** How do you capture packets on port 22 with tcpdump?
**A:** `tcpdump port 22`

### Card 18
**Q:** What does netcat (nc) do?
**A:** Creates network connections for testing, port scanning, file transfer, and general network debugging.

### Card 19
**Q:** How do you use netcat to listen on port 8080?
**A:** `nc -l 8080`

### Card 20
**Q:** What command tests if port 80 is open on a remote host using netcat?
**A:** `nc -zv hostname 80`

### Card 21
**Q:** What does nmap do?
**A:** Scans networks and hosts to discover open ports and running services.

### Card 22
**Q:** How do you scan ports 1-1000 on a host with nmap?
**A:** `nmap -p 1-1000 hostname`

## Network Services

### Card 23
**Q:** Name five common network server daemons.
**A:** httpd/apache2/nginx (web), sshd (SSH), postfix (mail), smbd (Samba), cupsd (print)

### Card 24
**Q:** What is the purpose of fail2ban?
**A:** Monitors log files for suspicious activity and automatically blocks IP addresses to prevent brute force attacks.

### Card 25
**Q:** How do you check the status of fail2ban?
**A:** `fail2ban-client status`

### Card 26
**Q:** What was inetd/xinetd used for?
**A:** A "super-server" that managed multiple network services from a single daemon, largely replaced by systemd.

### Card 27
**Q:** What does RPC stand for and what is rpcbind?
**A:** Remote Procedure Call; rpcbind is a service that maps RPC program numbers to port numbers.

## Network Security

### Card 28
**Q:** Why should you avoid telnet, rlogin, and FTP?
**A:** They transmit passwords and data in cleartext, making them vulnerable to eavesdropping.

### Card 29
**Q:** What are three key security measures for SSH?
**A:** Change default port, disable root login, use key-based authentication instead of passwords.

### Card 30
**Q:** How do you disable password authentication for SSH?
**A:** Set `PasswordAuthentication no` in `/etc/ssh/sshd_config` and restart sshd.

### Card 31
**Q:** What is the purpose of changing SSH from port 22 to another port?
**A:** Security through obscurity - reduces automated attacks on the default SSH port.

### Card 32
**Q:** What are hosts.allow and hosts.deny used for?
**A:** TCP wrappers access control - allow/deny network access based on IP addresses or hostnames.

## Network Connections and Sockets

### Card 33
**Q:** What's the difference between TCP and UDP?
**A:** TCP is connection-oriented and reliable; UDP is connectionless and unreliable but faster.

### Card 34
**Q:** What is a socket in networking?
**A:** A programming interface that processes use to communicate over networks.

### Card 35
**Q:** What are Unix domain sockets?
**A:** Special socket files used for inter-process communication on the same system (faster than network sockets).

### Card 36
**Q:** What command shows current network connections and listening ports?
**A:** `ss -tlnp` (modern) or `netstat -tlnp` (traditional)

### Card 37
**Q:** How do you see only UDP listening sockets?
**A:** `ss -ulnp`

## HTTP and Web Services

### Card 38
**Q:** What HTTP request line do you send to get a web page manually?
**A:** `GET / HTTP/1.1` followed by `Host: hostname`

### Card 39
**Q:** What curl option shows detailed communication traces?
**A:** `curl --trace-ascii trace_file http://example.com`

### Card 40
**Q:** What does the blank line in HTTP signify?
**A:** The end of headers - everything after is the document body/content.

## File Transfer

### Card 41
**Q:** How do you copy a file TO a remote server using scp?
**A:** `scp localfile user@host:/remote/path`

### Card 42
**Q:** How do you copy a file FROM a remote server using scp?
**A:** `scp user@host:/remote/file /local/path`

### Card 43
**Q:** What's the advantage of rsync over scp?
**A:** rsync is more efficient for large transfers, can resume, and has more options for synchronization.

## Advanced Topics

### Card 44
**Q:** What is port forwarding in SSH?
**A:** Tunneling network connections through SSH, e.g., `ssh -L 8080:localhost:80 user@host`

### Card 45
**Q:** How do you force IPv4 or IPv6 with network commands?
**A:** Use -4 for IPv4 or -6 for IPv6 (works with ping, ssh, netcat, etc.)

### Card 46
**Q:** What's the difference between ss and netstat?
**A:** ss is the modern replacement for netstat, faster and more feature-rich.

### Card 47
**Q:** What does the -v option typically do in network tools?
**A:** Enables verbose output, showing more detailed information about the operation.

### Card 48
**Q:** How do you save tcpdump output to a file for later analysis?
**A:** `tcpdump -w filename.pcap` to save, `tcpdump -r filename.pcap` to read.

### Card 49
**Q:** What's a common reason network servers create multiple processes?
**A:** To handle multiple simultaneous client connections - parent listens, children serve clients.

### Card 50
**Q:** Why might you see different nmap results when scanning from different locations?
**A:** Firewalls and network access controls may block certain ports from external networks but allow local access.