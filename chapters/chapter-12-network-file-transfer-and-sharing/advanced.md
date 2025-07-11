# Chapter 12: Advanced Concepts and Important Additions

This document covers advanced topics and important concepts that the book may not fully address or could explain better for modern engineering practices.

## 1. Cloud Storage Integration (Modern Necessity)

### Why This Matters
The book covers traditional file sharing but modern engineers need to understand hybrid cloud strategies and cloud-native storage solutions.

### rclone - The Universal Cloud Tool
```bash
# Configure multiple cloud providers
rclone config

# Advanced sync with filtering
rclone sync /local/data remote:bucket/data \
  --filter-from /etc/rclone-filters.txt \
  --transfers 32 \
  --checkers 16 \
  --bwlimit 50M

# Encrypted cloud storage
rclone config create mycloud-crypt crypt \
  remote mycloud:encrypted \
  password my-secret-password

# Mount cloud storage with caching
rclone mount mycloud:bucket /mnt/cloud \
  --cache-dir /tmp/rclone-cache \
  --vfs-cache-mode writes \
  --daemon
```

### AWS S3 Integration Example
```bash
#!/bin/bash
# Hybrid backup strategy: local rsync + cloud sync

# Local incremental backup
rsync -av --link-dest=/backup/latest /home/data/ /backup/$(date +%Y%m%d)/

# Sync to cloud (exclude temporary files)
rclone sync /backup/ aws-s3:company-backups/servers/$(hostname)/ \
  --exclude "*.tmp" \
  --exclude ".cache/**" \
  --transfers 8 \
  --checkers 8

# Verify cloud backup
rclone check /backup/latest/ aws-s3:company-backups/servers/$(hostname)/latest/
```

### Google Drive API Integration
```python
#!/usr/bin/env python3
# Advanced Google Drive integration for automated backups

from googleapiclient.discovery import build
from google.oauth2.credentials import Credentials
import os
import mimetypes

class DriveBackup:
    def __init__(self, credentials_path):
        self.service = build('drive', 'v3', credentials=Credentials.from_authorized_user_file(credentials_path))
    
    def backup_directory(self, local_path, drive_folder_id):
        """Backup local directory to Google Drive with deduplication"""
        for root, dirs, files in os.walk(local_path):
            for file in files:
                local_file = os.path.join(root, file)
                self.upload_with_dedup(local_file, drive_folder_id)
    
    def upload_with_dedup(self, local_file, parent_id):
        """Upload file only if it doesn't exist or has changed"""
        file_metadata = {
            'name': os.path.basename(local_file),
            'parents': [parent_id]
        }
        
        # Check if file exists and compare checksums
        existing = self.find_file(file_metadata['name'], parent_id)
        if existing and self.file_unchanged(local_file, existing):
            print(f"Skipping unchanged file: {local_file}")
            return
        
        # Upload new/changed file
        media = MediaFileUpload(local_file, resumable=True)
        self.service.files().create(body=file_metadata, media_body=media).execute()
        print(f"Uploaded: {local_file}")
```

## 2. Performance Optimization Beyond Basics

### Advanced rsync Tuning
```bash
# CPU and I/O optimization
rsync -av \
  --compress-level=1 \          # Light compression for fast CPUs
  --whole-file \                # Skip delta algorithm for fast networks
  --inplace \                   # Modify files in-place
  --sparse \                    # Handle sparse files efficiently
  --preallocate \               # Preallocate file space
  --fuzzy \                     # Find similar files for partial transfers
  --partial-dir=.rsync-partial \
  --delay-updates \             # Atomic updates
  --human-readable \
  --progress \
  source/ destination/

# Network optimization for WAN
rsync -av \
  --compress-level=6 \          # Higher compression for slow networks
  --compress-choice=zstd \      # Modern compression algorithm
  --bwlimit=80% \              # Leave bandwidth for other traffic
  --timeout=300 \               # Handle network interruptions
  --contimeout=60 \            # Connection timeout
  source/ destination/
```

### NFS Performance Tuning Deep Dive
```bash
# Client-side advanced tuning
mount -t nfs4 server:/export /mnt/nfs \
  -o vers=4.2 \                 # Latest NFS version
  -o rsize=1048576 \            # 1MB read size
  -o wsize=1048576 \            # 1MB write size
  -o timeo=600 \                # 60 second timeout
  -o retrans=2 \                # 2 retransmissions
  -o hard \                     # Hard mount (don't give up)
  -o intr \                     # Allow interruption
  -o fsc \                      # Enable local caching
  -o local_lock=all \           # Local file locking
  -o _netdev                    # Network device

# Server-side kernel tuning
cat >> /etc/sysctl.conf << 'EOF'
# NFS server optimization
net.core.rmem_max = 134217728
net.core.wmem_max = 134217728
net.ipv4.tcp_rmem = 4096 87380 134217728
net.ipv4.tcp_wmem = 4096 65536 134217728
net.core.netdev_max_backlog = 5000
sunrpc.tcp_slot_table_entries = 128
EOF
```

### SSHFS Performance Optimization
```bash
# High-performance SSHFS mounting
sshfs user@server:/path /mnt/sshfs \
  -o cache=yes \
  -o cache_timeout=115 \
  -o cache_X_timeout=115 \
  -o cache_dir_timeout=115 \
  -o cache_link_timeout=115 \
  -o cache_clean_interval=60 \
  -o cache_min_clean_interval=5 \
  -o big_writes \
  -o large_read \
  -o max_read=65536 \
  -o compression=yes \
  -o Ciphers=aes128-ctr \       # Fast cipher
  -o ServerAliveInterval=15 \
  -o ServerAliveCountMax=3 \
  -o ConnectTimeout=10
```

## 3. Security Hardening (Critical for Production)

### Samba Security Hardening
```ini
# /etc/samba/smb.conf - Security hardened
[global]
    # Protocol security
    client min protocol = SMB3
    server min protocol = SMB3
    smb encrypt = required
    
    # Authentication hardening
    security = user
    passdb backend = tdbsam
    map to guest = never
    restrict anonymous = 2
    
    # Network security
    bind interfaces only = yes
    interfaces = lo eth0
    hosts allow = 192.168.1. 10.0.
    hosts deny = ALL
    
    # Logging and auditing
    log level = 2 auth_audit:3 auth_json_audit:3
    log file = /var/log/samba/log.%m
    max log size = 10000
    
    # Additional hardening
    disable netbios = yes
    smb ports = 445
    lanman auth = no
    ntlm auth = no
    raw NTLMv2 auth = no
    client use spnego = required
    
    # File system security
    hide dot files = yes
    hide special files = yes
    hide unreadable = yes
    hide unwriteable files = yes
```

### NFS Security with Kerberos
```bash
# /etc/exports with Kerberos security
/srv/nfs/secure *.company.com(rw,sync,sec=krb5p,no_subtree_check)

# Kerberos configuration for NFS
cat > /etc/krb5.conf << 'EOF'
[libdefaults]
    default_realm = COMPANY.COM
    dns_lookup_realm = true
    dns_lookup_kdc = true
    
[realms]
    COMPANY.COM = {
        kdc = kdc.company.com
        admin_server = kdc.company.com
    }
    
[domain_realm]
    .company.com = COMPANY.COM
    company.com = COMPANY.COM
EOF

# NFS with Kerberos setup
systemctl enable nfs-secure-server
systemctl start nfs-secure-server
```

### SSH Key Management for SSHFS
```bash
#!/bin/bash
# Automated SSH key rotation for SSHFS

KEY_DIR="/etc/sshfs-keys"
ROTATION_DAYS=90

rotate_sshfs_keys() {
    local service_name=$1
    local remote_host=$2
    local remote_user=$3
    
    # Generate new key pair
    ssh-keygen -t ed25519 -f "$KEY_DIR/$service_name-new" -N "" -C "sshfs-$service_name-$(date +%Y%m%d)"
    
    # Deploy new public key
    ssh-copy-id -i "$KEY_DIR/$service_name-new.pub" "$remote_user@$remote_host"
    
    # Test new key
    if ssh -i "$KEY_DIR/$service_name-new" "$remote_user@$remote_host" "echo 'Key test successful'"; then
        # Replace old key
        mv "$KEY_DIR/$service_name-new" "$KEY_DIR/$service_name"
        mv "$KEY_DIR/$service_name-new.pub" "$KEY_DIR/$service_name.pub"
        
        # Update mount configurations
        sed -i "s|IdentityFile=.*$service_name|IdentityFile=$KEY_DIR/$service_name|g" /etc/fstab
        
        echo "Key rotation successful for $service_name"
    else
        echo "Key rotation failed for $service_name"
        rm "$KEY_DIR/$service_name-new"*
        return 1
    fi
}
```

## 4. Monitoring and Alerting (Production Necessity)

### Comprehensive Monitoring Script
```bash
#!/bin/bash
# Advanced file sharing monitoring with alerting

PROMETHEUS_PUSHGATEWAY="http://monitoring.company.com:9091"
SLACK_WEBHOOK="https://hooks.slack.com/services/YOUR/WEBHOOK/URL"

send_metric() {
    local metric_name=$1
    local value=$2
    local labels=$3
    
    curl -X POST "$PROMETHEUS_PUSHGATEWAY/metrics/job/file_sharing/instance/$(hostname)" \
         --data-binary "$metric_name{$labels} $value"
}

send_alert() {
    local message=$1
    local severity=$2
    
    curl -X POST "$SLACK_WEBHOOK" \
         -H 'Content-type: application/json' \
         --data "{\"text\":\":warning: $severity Alert on $(hostname): $message\"}"
}

check_samba_performance() {
    local connections=$(smbstatus -b | grep -c "^[0-9]")
    local locks=$(smbstatus -L | grep -c "^[0-9]")
    
    send_metric "samba_connections_total" "$connections" "service=\"samba\""
    send_metric "samba_locks_total" "$locks" "service=\"samba\""
    
    if [[ $connections -gt 100 ]]; then
        send_alert "High Samba connections: $connections" "WARNING"
    fi
}

check_nfs_performance() {
    local nfs_stats=$(cat /proc/net/rpc/nfsd)
    local rpc_calls=$(echo "$nfs_stats" | awk '/^rc/ {print $2}')
    
    send_metric "nfs_rpc_calls_total" "$rpc_calls" "service=\"nfs\""
}

monitor_transfer_speeds() {
    local interface="eth0"
    local rx_bytes_before=$(cat /sys/class/net/$interface/statistics/rx_bytes)
    local tx_bytes_before=$(cat /sys/class/net/$interface/statistics/tx_bytes)
    
    sleep 60
    
    local rx_bytes_after=$(cat /sys/class/net/$interface/statistics/rx_bytes)
    local tx_bytes_after=$(cat /sys/class/net/$interface/statistics/tx_bytes)
    
    local rx_rate=$(( (rx_bytes_after - rx_bytes_before) / 60 ))
    local tx_rate=$(( (tx_bytes_after - tx_bytes_before) / 60 ))
    
    send_metric "network_rx_bytes_per_second" "$rx_rate" "interface=\"$interface\""
    send_metric "network_tx_bytes_per_second" "$tx_rate" "interface=\"$interface\""
}
```

### Grafana Dashboard Configuration
```json
{
  "dashboard": {
    "title": "File Sharing Services",
    "panels": [
      {
        "title": "Samba Connections",
        "type": "graph",
        "targets": [
          {
            "expr": "samba_connections_total",
            "legendFormat": "Active Connections"
          }
        ]
      },
      {
        "title": "NFS RPC Calls",
        "type": "graph", 
        "targets": [
          {
            "expr": "rate(nfs_rpc_calls_total[5m])",
            "legendFormat": "RPC Calls/sec"
          }
        ]
      },
      {
        "title": "Network Transfer Rates",
        "type": "graph",
        "targets": [
          {
            "expr": "network_rx_bytes_per_second * 8",
            "legendFormat": "Download (bps)"
          },
          {
            "expr": "network_tx_bytes_per_second * 8", 
            "legendFormat": "Upload (bps)"
          }
        ]
      }
    ]
  }
}
```

## 5. Container Integration (Modern DevOps)

### Docker Volume with NFS
```yaml
# docker-compose.yml with NFS volumes
version: '3.8'
services:
  app:
    image: myapp:latest
    volumes:
      - type: volume
        source: nfs-data
        target: /app/data
        volume:
          nocopy: true

volumes:
  nfs-data:
    driver: local
    driver_opts:
      type: nfs
      o: addr=nfs-server.company.com,vers=4,soft,timeo=180,bg,tcp,rw
      device: ":/srv/nfs/app-data"
```

### Kubernetes Persistent Volumes
```yaml
# NFS PersistentVolume
apiVersion: v1
kind: PersistentVolume
metadata:
  name: nfs-pv
spec:
  capacity:
    storage: 100Gi
  accessModes:
    - ReadWriteMany
  nfs:
    server: nfs-server.company.com
    path: "/srv/nfs/k8s-data"
  persistentVolumeReclaimPolicy: Retain

---
# SSHFS via FUSE in Kubernetes
apiVersion: apps/v1
kind: Deployment
metadata:
  name: sshfs-pod
spec:
  replicas: 1
  selector:
    matchLabels:
      app: sshfs-app
  template:
    metadata:
      labels:
        app: sshfs-app
    spec:
      containers:
      - name: app
        image: myapp:latest
        securityContext:
          privileged: true  # Required for FUSE
        volumeMounts:
        - name: ssh-keys
          mountPath: /root/.ssh
          readOnly: true
      volumes:
      - name: ssh-keys
        secret:
          secretName: ssh-keys
          defaultMode: 0600
```

## 6. Disaster Recovery and Business Continuity

### Multi-Tier Backup Strategy
```bash
#!/bin/bash
# Comprehensive backup strategy implementation

# Tier 1: Local snapshot backups (hourly)
create_snapshot() {
    local source=$1
    local snapshot_dir="/snapshots/$(date +%Y%m%d-%H%M)"
    
    # LVM snapshot for consistent backup
    lvcreate -L1G -s -n backup-snap /dev/vg0/data
    mount /dev/vg0/backup-snap /mnt/snapshot
    
    # rsync from snapshot
    rsync -av --link-dest=/snapshots/latest /mnt/snapshot/ "$snapshot_dir/"
    ln -sfn "$snapshot_dir" /snapshots/latest
    
    # Cleanup
    umount /mnt/snapshot
    lvremove -f /dev/vg0/backup-snap
}

# Tier 2: Remote replication (daily)
replicate_to_remote() {
    rsync -avz --delete --bwlimit=50M \
        /snapshots/latest/ \
        backup-server:/remote-backups/$(hostname)/
}

# Tier 3: Cloud archival (weekly)
archive_to_cloud() {
    # Create encrypted archive
    tar czf - /snapshots/latest | \
    gpg --cipher-algo AES256 --compress-algo 1 --symmetric --output /tmp/backup-$(date +%Y%m%d).tar.gz.gpg
    
    # Upload to cloud storage
    rclone copy /tmp/backup-$(date +%Y%m%d).tar.gz.gpg aws-s3:company-archives/
    
    # Cleanup local encrypted file
    rm /tmp/backup-$(date +%Y%m%d).tar.gz.gpg
}

# Recovery testing
test_recovery() {
    local test_file="/tmp/recovery-test-$(date +%s).txt"
    echo "Recovery test $(date)" > "$test_file"
    
    # Test local recovery
    rsync -av "$test_file" /snapshots/latest/
    
    # Test remote recovery
    rsync -av backup-server:/remote-backups/$(hostname)/ /tmp/recovery-test/
    
    if [[ -f "/tmp/recovery-test/$(basename $test_file)" ]]; then
        echo "Recovery test PASSED"
        rm -rf /tmp/recovery-test "$test_file"
        return 0
    else
        echo "Recovery test FAILED"
        return 1
    fi
}
```

## 7. Compliance and Auditing

### GDPR Compliance for File Sharing
```bash
#!/bin/bash
# GDPR compliance auditing for file shares

audit_file_access() {
    local share_path=$1
    local audit_log="/var/log/gdpr-audit.log"
    
    # Audit Samba access
    tail -f /var/log/samba/log.* | while read line; do
        if echo "$line" | grep -q "opened.*file"; then
            user=$(echo "$line" | awk '{print $6}')
            file=$(echo "$line" | awk '{print $NF}')
            timestamp=$(date '+%Y-%m-%d %H:%M:%S')
            echo "$timestamp - User $user accessed file $file" >> "$audit_log"
        fi
    done &
    
    # Audit NFS access (requires auditd)
    auditctl -w "$share_path" -p rwxa -k gdpr_file_access
}

generate_gdpr_report() {
    local user_id=$1
    local start_date=$2
    local end_date=$3
    
    cat << EOF > "/tmp/gdpr-report-$user_id.html"
<!DOCTYPE html>
<html>
<head><title>GDPR Data Access Report for $user_id</title></head>
<body>
<h1>Personal Data Access Report</h1>
<p>Period: $start_date to $end_date</p>
<h2>File Access History</h2>
<ul>
EOF
    
    grep "$user_id" /var/log/gdpr-audit.log | \
    awk -v start="$start_date" -v end="$end_date" \
    '$1 >= start && $1 <= end {print "<li>" $0 "</li>"}' >> "/tmp/gdpr-report-$user_id.html"
    
    echo "</ul></body></html>" >> "/tmp/gdpr-report-$user_id.html"
}

implement_right_to_be_forgotten() {
    local user_id=$1
    
    # Find all files owned by user
    find /srv/samba /srv/nfs -user "$user_id" -exec rm -f {} \;
    
    # Remove from Samba database
    smbpasswd -x "$user_id"
    
    # Remove user from system
    userdel "$user_id"
    
    # Log the deletion
    echo "$(date): GDPR deletion completed for user $user_id" >> /var/log/gdpr-deletions.log
}
```

## 8. High Availability and Load Balancing

### DRBD + Pacemaker for HA File Sharing
```bash
# DRBD configuration for replicated storage
cat > /etc/drbd.d/file-shares.res << 'EOF'
resource file-shares {
  device /dev/drbd0;
  disk /dev/sdb1;
  meta-disk internal;
  
  on fileserver1 {
    address 192.168.1.10:7788;
  }
  
  on fileserver2 {
    address 192.168.1.11:7788;
  }
}
EOF

# Pacemaker cluster configuration
pcs cluster setup --name file-cluster fileserver1 fileserver2
pcs cluster start --all
pcs cluster enable --all

# Add resources
pcs resource create drbd_fs ocf:linbit:drbd drbd_resource=file-shares
pcs resource create fs_mount Filesystem device=/dev/drbd0 directory=/srv/shared fstype=ext4
pcs resource create samba systemd:smbd
pcs resource create nfs systemd:nfs-kernel-server

# Create constraints
pcs constraint colocation add fs_mount with drbd_fs INFINITY with-rsc-role=Master
pcs constraint order promote drbd_fs then start fs_mount
pcs constraint colocation add samba with fs_mount INFINITY
pcs constraint colocation add nfs with fs_mount INFINITY
```

### Load Balancing with HAProxy
```
# HAProxy configuration for Samba load balancing
global
    daemon
    
defaults
    mode tcp
    timeout connect 5000ms
    timeout client 50000ms
    timeout server 50000ms

frontend samba_frontend
    bind *:445
    default_backend samba_servers

backend samba_servers
    balance roundrobin
    server samba1 192.168.1.10:445 check
    server samba2 192.168.1.11:445 check backup
    
frontend nfs_frontend
    bind *:2049
    default_backend nfs_servers
    
backend nfs_servers
    balance source
    server nfs1 192.168.1.10:2049 check
    server nfs2 192.168.1.11:2049 check backup
```

## 9. Modern Authentication Integration

### OAuth2 Integration for File Sharing
```python
#!/usr/bin/env python3
# OAuth2 authentication wrapper for file sharing access

import requests
from flask import Flask, request, redirect, session
import os

app = Flask(__name__)
app.secret_key = os.environ['SESSION_SECRET']

OAUTH_CONFIG = {
    'client_id': os.environ['OAUTH_CLIENT_ID'],
    'client_secret': os.environ['OAUTH_CLIENT_SECRET'],
    'auth_url': 'https://auth.company.com/oauth/authorize',
    'token_url': 'https://auth.company.com/oauth/token',
    'userinfo_url': 'https://auth.company.com/oauth/userinfo'
}

@app.route('/auth')
def oauth_auth():
    auth_url = f"{OAUTH_CONFIG['auth_url']}?client_id={OAUTH_CONFIG['client_id']}&response_type=code&scope=read_files&redirect_uri=http://fileserver.company.com/callback"
    return redirect(auth_url)

@app.route('/callback')
def oauth_callback():
    code = request.args.get('code')
    
    # Exchange code for token
    token_response = requests.post(OAUTH_CONFIG['token_url'], data={
        'client_id': OAUTH_CONFIG['client_id'],
        'client_secret': OAUTH_CONFIG['client_secret'],
        'code': code,
        'grant_type': 'authorization_code'
    })
    
    if token_response.status_code == 200:
        token_data = token_response.json()
        access_token = token_data['access_token']
        
        # Get user info
        user_response = requests.get(OAUTH_CONFIG['userinfo_url'], 
                                   headers={'Authorization': f'Bearer {access_token}'})
        
        if user_response.status_code == 200:
            user_info = user_response.json()
            username = user_info['username']
            
            # Create/update Samba user
            create_samba_user(username, access_token)
            
            session['authenticated'] = True
            session['username'] = username
            return redirect('/files')
    
    return 'Authentication failed', 401

def create_samba_user(username, access_token):
    """Create temporary Samba user with token-based password"""
    import subprocess
    import hashlib
    
    # Generate secure password from token
    password = hashlib.sha256(access_token.encode()).hexdigest()[:16]
    
    # Create system user if doesn't exist
    try:
        subprocess.run(['useradd', '-m', username], check=True)
    except subprocess.CalledProcessError:
        pass  # User already exists
    
    # Set Samba password
    subprocess.run(['smbpasswd', '-a', username], input=f"{password}\n{password}\n", 
                  text=True, check=True)
```

## Summary of Important Additions

These advanced concepts significantly enhance the basic file sharing knowledge from the book:

1. **Cloud Integration**: Essential for modern hybrid environments
2. **Performance Optimization**: Production-grade tuning techniques
3. **Security Hardening**: Enterprise security requirements
4. **Monitoring & Alerting**: Proactive infrastructure management
5. **Container Integration**: Modern deployment patterns
6. **Disaster Recovery**: Business continuity planning
7. **Compliance**: Legal and regulatory requirements
8. **High Availability**: Zero-downtime architectures
9. **Modern Authentication**: OAuth2, SAML integration

These topics transform basic file sharing knowledge into enterprise-ready skills that are immediately applicable in professional environments.