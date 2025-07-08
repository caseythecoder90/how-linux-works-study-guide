# Chapter 10: Network Applications and Services Lab Exercises

## Prerequisites
- Linux system with network access
- Basic networking knowledge from Chapter 9
- Administrative privileges for some exercises
- Text editor and basic command line skills

## Lab Objectives
By the end of this lab, you will:
1. Master network service interaction using command-line tools
2. Configure and secure SSH services
3. Use network diagnostic tools effectively
4. Understand network security fundamentals
5. Troubleshoot common network service issues

---

## Part 1: Basic Network Service Interaction (25 minutes)

### Exercise 1.1: Manual HTTP Communication
1. Connect to a web server manually using telnet:
   ```bash
   telnet example.org 80
   ```

2. Once connected, type the following HTTP request:
   ```
   GET / HTTP/1.1
   Host: example.org
   
   ```
   (Press Enter twice after the Host line)

3. Observe the HTTP response headers and HTML content.

4. Try the same with curl to see the difference:
   ```bash
   curl -v http://example.org
   curl --trace-ascii trace.txt http://example.org
   cat trace.txt
   ```

### Exercise 1.2: Exploring Different Protocols
1. Test different network services:
   ```bash
   # Test SSH (should see SSH version banner)
   telnet example.com 22
   
   # Test SMTP (if available)
   telnet mail.example.com 25
   
   # Test DNS with dig
   dig example.com
   dig @8.8.8.8 example.com
   ```

2. Use netcat for protocol testing:
   ```bash
   # Test web server
   echo -e "GET / HTTP/1.1\r\nHost: example.com\r\n\r\n" | nc example.com 80
   
   # Test if ports are open
   nc -zv example.com 80
   nc -zv example.com 22
   nc -zv example.com 443
   ```

### Exercise 1.3: Port and Service Discovery
1. Check what services are running locally:
   ```bash
   # Modern approach
   ss -tlnp
   ss -ulnp
   
   # Traditional approach
   netstat -tlnp
   netstat -ulnp
   ```

2. Use lsof to see network connections:
   ```bash
   # All network connections
   lsof -i
   
   # Specific port
   lsof -i :22
   
   # Listening ports only
   lsof -i -sTCP:LISTEN
   ```

**Questions:**
- What's the difference between the HTTP headers and body?
- Why might some telnet connections to ports fail immediately?

---

## Part 2: SSH Configuration and Security (35 minutes)

### Exercise 2.1: SSH Key Management
1. Generate a new SSH key pair:
   ```bash
   ssh-keygen -t ed25519 -C "your_email@example.com"
   # Or for RSA:
   ssh-keygen -t rsa -b 4096 -C "your_email@example.com"
   ```

2. Examine the generated keys:
   ```bash
   ls -la ~/.ssh/
   cat ~/.ssh/id_ed25519.pub
   ```

3. If you have access to another system, copy your public key:
   ```bash
   ssh-copy-id user@remote_host
   # Or manually:
   cat ~/.ssh/id_ed25519.pub | ssh user@remote_host "mkdir -p ~/.ssh && cat >> ~/.ssh/authorized_keys"
   ```

### Exercise 2.2: SSH Client Configuration
1. Create a custom SSH client configuration:
   ```bash
   nano ~/.ssh/config
   ```

2. Add a host configuration:
   ```
   Host myserver
       HostName actual-server.example.com
       User myusername
       Port 2222
       IdentityFile ~/.ssh/special_key
       ForwardX11 yes
   
   Host *.example.com
       User commonusername
       Port 22
   ```

3. Test the configuration:
   ```bash
   ssh myserver  # Should use the settings from config
   ```

### Exercise 2.3: SSH Server Hardening
1. Backup the original SSH configuration:
   ```bash
   sudo cp /etc/ssh/sshd_config /etc/ssh/sshd_config.backup
   ```

2. Edit the SSH server configuration:
   ```bash
   sudo nano /etc/ssh/sshd_config
   ```

3. Implement security hardening:
   ```
   # Change default port (optional)
   Port 2222
   
   # Disable root login
   PermitRootLogin no
   
   # Limit authentication attempts
   MaxAuthTries 3
   MaxSessions 5
   
   # Disable password authentication (after key setup)
   PasswordAuthentication no
   PubkeyAuthentication yes
   
   # Limit users (if desired)
   AllowUsers alice bob
   
   # Disable empty passwords
   PermitEmptyPasswords no
   
   # Set timeouts
   ClientAliveInterval 300
   ClientAliveCountMax 2
   ```

4. Test the configuration before applying:
   ```bash
   sudo sshd -t
   ```

5. If no errors, restart SSH service:
   ```bash
   sudo systemctl restart sshd
   sudo systemctl status sshd
   ```

**Warning**: Make sure you have another way to access the system before disabling password authentication!

### Exercise 2.4: SSH Port Forwarding
1. Test local port forwarding:
   ```bash
   # Forward local port 8080 to remote port 80
   ssh -L 8080:localhost:80 user@remote_host
   
   # Test in another terminal
   curl http://localhost:8080
   ```

2. Test dynamic port forwarding (SOCKS proxy):
   ```bash
   ssh -D 1080 user@remote_host
   
   # Configure browser to use localhost:1080 as SOCKS proxy
   ```

**Questions:**
- Why is it important to test SSH configuration before restarting the service?
- What are the security implications of port forwarding?

---

## Part 3: Network Diagnostic Tools (40 minutes)

### Exercise 3.1: Using lsof for Network Troubleshooting
1. Start a simple web server for testing:
   ```bash
   # Python 3
   python3 -m http.server 8080
   # Or Python 2
   python -m SimpleHTTPServer 8080
   ```

2. In another terminal, use lsof to investigate:
   ```bash
   # Find what's using port 8080
   lsof -i :8080
   
   # Find all files opened by python
   lsof -c python
   
   # Find network connections by process ID
   lsof -p $(pgrep python)
   ```

3. Make connections to the server and observe:
   ```bash
   # In terminal 1: keep running curl in loop
   while true; do curl http://localhost:8080; sleep 2; done
   
   # In terminal 2: watch connections
   watch 'lsof -i :8080'
   ```

### Exercise 3.2: Packet Capture with tcpdump
1. Capture HTTP traffic:
   ```bash
   # Capture on loopback interface
   sudo tcpdump -i lo port 8080
   
   # With verbose output
   sudo tcpdump -v -i lo port 8080
   
   # Show packet contents
   sudo tcpdump -X -i lo port 8080
   ```

2. Generate traffic and observe packets:
   ```bash
   # In another terminal
   curl http://localhost:8080
   ```

3. Capture and save for analysis:
   ```bash
   # Save to file
   sudo tcpdump -w http_capture.pcap -i lo port 8080
   
   # Generate some traffic, then stop capture
   curl http://localhost:8080
   
   # Read saved capture
   tcpdump -r http_capture.pcap
   tcpdump -X -r http_capture.pcap
   ```

4. Advanced filtering:
   ```bash
   # Capture only TCP SYN packets
   sudo tcpdump -i any 'tcp[tcpflags] & tcp-syn != 0'
   
   # Capture traffic to/from specific host
   sudo tcpdump host google.com
   
   # Capture DNS traffic
   sudo tcpdump port 53
   ```

### Exercise 3.3: Network Scanning with nmap
1. Scan your local machine:
   ```bash
   nmap localhost
   nmap 127.0.0.1
   ```

2. Detailed service detection:
   ```bash
   nmap -sV localhost
   nmap -A localhost  # Aggressive scan
   ```

3. Scan specific ports:
   ```bash
   nmap -p 22,80,443 localhost
   nmap -p 1-1000 localhost
   ```

4. UDP scanning:
   ```bash
   sudo nmap -sU localhost
   sudo nmap -sU -p 53,67,68,161 localhost
   ```

5. Network discovery (if on a LAN):
   ```bash
   # Find your network range first
   ip route show
   
   # Scan the local network (adjust range as needed)
   nmap -sn 192.168.1.0/24
   ```

### Exercise 3.4: Advanced netcat Usage
1. Create a simple chat system:
   ```bash
   # On system 1 (or terminal 1):
   nc -l 8080
   
   # On system 2 (or terminal 2):
   nc localhost 8080
   
   # Type messages in either terminal
   ```

2. File transfer with netcat:
   ```bash
   # Create a test file
   echo "This is a test file for netcat transfer" > testfile.txt
   
   # Receiver side:
   nc -l 9090 > received_file.txt
   
   # Sender side (in another terminal):
   nc localhost 9090 < testfile.txt
   
   # Verify transfer
   diff testfile.txt received_file.txt
   ```

3. Port scanning with netcat:
   ```bash
   # Test if ports are open
   nc -zv localhost 22
   nc -zv localhost 80
   nc -zv localhost 1-100  # Scan range
   ```

4. HTTP server simulation:
   ```bash
   # Create simple HTTP response
   echo -e "HTTP/1.1 200 OK\r\nContent-Length: 13\r\n\r\nHello, World!" > response.txt
   
   # Serve the response
   while true; do nc -l 8080 < response.txt; done
   
   # Test in another terminal
   curl http://localhost:8080
   ```

**Questions:**
- How does tcpdump differ from application-level debugging?
- When would you use UDP scanning versus TCP scanning?

---

## Part 4: Network Security Implementation (30 minutes)

### Exercise 4.1: Installing and Configuring fail2ban
1. Install fail2ban:
   ```bash
   # Ubuntu/Debian
   sudo apt update && sudo apt install fail2ban
   
   # CentOS/RHEL
   sudo yum install epel-release
   sudo yum install fail2ban
   ```

2. Create local configuration:
   ```bash
   sudo cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local
   sudo nano /etc/fail2ban/jail.local
   ```

3. Configure SSH protection:
   ```bash
   # Add or modify in jail.local
   [DEFAULT]
   bantime = 3600      # Ban for 1 hour
   findtime = 600      # Within 10 minutes
   maxretry = 3        # 3 failures
   
   [sshd]
   enabled = true
   port = ssh
   filter = sshd
   logpath = /var/log/auth.log
   maxretry = 3
   ```

4. Start and enable fail2ban:
   ```bash
   sudo systemctl start fail2ban
   sudo systemctl enable fail2ban
   sudo systemctl status fail2ban
   ```

5. Monitor fail2ban:
   ```bash
   # Check status
   sudo fail2ban-client status
   sudo fail2ban-client status sshd
   
   # Monitor logs
   sudo tail -f /var/log/fail2ban.log
   ```

### Exercise 4.2: Basic Firewall Configuration
1. Check current iptables rules:
   ```bash
   sudo iptables -L -n -v
   ```

2. Create basic firewall rules:
   ```bash
   # Allow loopback
   sudo iptables -A INPUT -i lo -j ACCEPT
   
   # Allow established connections
   sudo iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
   
   # Allow SSH
   sudo iptables -A INPUT -p tcp --dport 22 -j ACCEPT
   
   # Allow HTTP and HTTPS
   sudo iptables -A INPUT -p tcp --dport 80 -j ACCEPT
   sudo iptables -A INPUT -p tcp --dport 443 -j ACCEPT
   
   # Drop everything else
   sudo iptables -A INPUT -j DROP
   ```

3. Test the firewall:
   ```bash
   # These should work
   nc -zv localhost 22
   nc -zv localhost 80
   
   # This should fail (if the port isn't explicitly allowed)
   nc -zv localhost 8080
   ```

4. Save the rules (method varies by distribution):
   ```bash
   # Ubuntu/Debian
   sudo iptables-save > /etc/iptables/rules.v4
   
   # CentOS/RHEL
   sudo service iptables save
   ```

### Exercise 4.3: Host-based Access Control
1. Configure TCP wrappers:
   ```bash
   # Allow SSH from local network only
   echo "sshd: 192.168.1.0/24" | sudo tee -a /etc/hosts.allow
   
   # Deny SSH from everywhere else
   echo "sshd: ALL" | sudo tee -a /etc/hosts.deny
   ```

2. Test access control (if you have multiple systems):
   ```bash
   # Should work from allowed network
   ssh user@localhost
   
   # Should fail from denied networks
   ```

**Questions:**
- How does fail2ban complement firewall rules?
- What are the advantages and disadvantages of host-based access control?

---

## Part 5: Real-world Network Service Management (35 minutes)

### Exercise 5.1: Setting Up a Simple Web Server
1. Install a web server:
   ```bash
   # Apache
   sudo apt install apache2  # Ubuntu/Debian
   sudo yum install httpd    # CentOS/RHEL
   
   # Or Nginx
   sudo apt install nginx    # Ubuntu/Debian
   ```

2. Start and enable the service:
   ```bash
   # Apache
   sudo systemctl start apache2  # Ubuntu/Debian
   sudo systemctl start httpd    # CentOS/RHEL
   sudo systemctl enable apache2
   
   # Nginx
   sudo systemctl start nginx
   sudo systemctl enable nginx
   ```

3. Test the web server:
   ```bash
   curl http://localhost
   curl -I http://localhost  # Headers only
   ```

4. Check what's listening:
   ```bash
   lsof -i :80
   ss -tlnp | grep :80
   ```

5. Create a custom web page:
   ```bash
   # Apache
   echo "<h1>Hello from $(hostname)</h1>" | sudo tee /var/www/html/index.html
   
   # Nginx
   echo "<h1>Hello from $(hostname)</h1>" | sudo tee /var/www/html/index.html
   
   # Test
   curl http://localhost
   ```

### Exercise 5.2: Log Analysis and Monitoring
1. Monitor web server access logs:
   ```bash
   # Apache
   sudo tail -f /var/log/apache2/access.log
   
   # Nginx
   sudo tail -f /var/log/nginx/access.log
   ```

2. Generate traffic and observe logs:
   ```bash
   # In another terminal, generate requests
   for i in {1..10}; do
       curl http://localhost
       curl http://localhost/nonexistent
       sleep 1
   done
   ```

3. Analyze log patterns:
   ```bash
   # Count different response codes
   sudo grep " 200 " /var/log/apache2/access.log | wc -l
   sudo grep " 404 " /var/log/apache2/access.log | wc -l
   
   # Most frequently accessed pages
   sudo awk '{print $7}' /var/log/apache2/access.log | sort | uniq -c | sort -nr
   
   # IP address frequency
   sudo awk '{print $1}' /var/log/apache2/access.log | sort | uniq -c | sort -nr
   ```

### Exercise 5.3: Comprehensive Network Service Troubleshooting
1. Create a troubleshooting scenario:
   ```bash
   # Stop the web server
   sudo systemctl stop apache2  # or nginx
   ```

2. Use systematic troubleshooting:
   ```bash
   # Step 1: Is the service running?
   systemctl status apache2
   ps aux | grep apache
   
   # Step 2: Is it listening on the port?
   ss -tlnp | grep :80
   lsof -i :80
   
   # Step 3: Can we connect locally?
   nc -zv localhost 80
   telnet localhost 80
   
   # Step 4: Check logs for errors
   journalctl -u apache2 -f
   sudo tail /var/log/apache2/error.log
   ```

3. Fix the issue and verify:
   ```bash
   sudo systemctl start apache2
   curl http://localhost
   ```

### Exercise 5.4: Network Service Security Audit
1. Perform a security audit of your system:
   ```bash
   # Check listening services
   ss -tlnp
   
   # Scan for open ports
   nmap localhost
   
   # Check for unnecessary services
   systemctl list-unit-files --type=service --state=enabled
   ```

2. Document findings:
   ```bash
   # Create an audit report
   cat > security_audit.txt << EOF
   Security Audit Report - $(date)