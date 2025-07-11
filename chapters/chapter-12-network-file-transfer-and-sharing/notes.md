# Chapter 12: Network File Transfer and Sharing - Notes

## Chapter Overview
This chapter covers the essential tools and protocols for transferring files across networks and sharing filesystems between Linux and other systems. Understanding these technologies is crucial for system administration, backup strategies, and collaborative work environments.

## 12.1 Quick Copy

### Basic File Transfer Methods
**scp (Secure Copy)** - Part of SSH suite, provides encrypted file transfer
```bash
# Copy file to remote host
scp localfile.txt user@remotehost:/path/to/destination/

# Copy from remote host
scp user@remotehost:/path/to/file.txt ./local_destination/

# Copy directories recursively
scp -r local_directory/ user@remotehost:/remote/path/

# Copy with port specification
scp -P 2222 file.txt user@remotehost:/path/
```

**Important**: scp always transfers the entire file, making it inefficient for large files that change frequently.

### Advanced scp Options
- `-r` - Recursive copy for directories
- `-p` - Preserve file timestamps and permissions
- `-P port` - Specify SSH port
- `-i keyfile` - Use specific SSH key
- `-C` - Enable compression

**Security Note**: scp provides encryption in transit but requires proper SSH key management for secure automation.

---

## 12.2 rsync - The Swiss Army Knife of File Synchronization

### Understanding rsync Philosophy
**Definition**: rsync synchronizes files by transferring only the differences between source and destination

**Why it matters**: Dramatically reduces bandwidth usage and transfer time for incremental backups and synchronization

### 12.2.1 Getting Started with rsync

#### Basic Syntax
```bash
rsync [options] source destination
```

#### Local synchronization
```bash
# Basic local sync
rsync -av /source/directory/ /destination/directory/

# Dry run (show what would be transferred)
rsync -avn /source/ /destination/
```

#### Remote synchronization
```bash
# Push to remote host
rsync -av /local/path/ user@remotehost:/remote/path/

# Pull from remote host
rsync -av user@remotehost:/remote/path/ /local/path/

# Using SSH on custom port
rsync -av -e "ssh -p 2222" /local/ user@host:/remote/
```

### 12.2.2 Making Exact Copies of a Directory Structure

#### The -a (archive) option
**Purpose**: Preserves almost everything about files
- `-r` (recursive)
- `-l` (preserve symlinks)
- `-p` (preserve permissions)
- `-t` (preserve timestamps)
- `-g` (preserve group)
- `-o` (preserve owner, requires root)
- `-D` (preserve device files)

```bash
# Archive mode with verbose output
rsync -av /source/ /destination/

# Archive mode with progress and human-readable output
rsync -avh --progress /source/ /destination/
```

### 12.2.3 Using the Trailing Slash

**Critical Concept**: The trailing slash determines what gets copied

```bash
# Copies the directory itself
rsync -av /source /destination/
# Result: /destination/source/

# Copies the contents of the directory
rsync -av /source/ /destination/
# Result: /destination/ contains source's contents
```

**Memory Aid**: "Slash = contents only, no slash = directory itself"

### 12.2.4 Excluding Files and Directories

#### Pattern-based exclusion
```bash
# Exclude specific patterns
rsync -av --exclude='*.tmp' --exclude='cache/' /source/ /dest/

# Exclude from file
rsync -av --exclude-from='exclude.txt' /source/ /dest/

# Include/exclude combinations
rsync -av --include='*.txt' --exclude='*' /source/ /dest/
```

#### Example exclude file
```
# exclude.txt
*.log
*.tmp
.git/
node_modules/
__pycache__/
```

### 12.2.5 Checking Transfers, Adding Safeguards, and Verbose Mode

#### Safety options
```bash
# Dry run - see what would happen
rsync -avn /source/ /dest/

# Delete files not in source (DANGEROUS)
rsync -av --delete /source/ /dest/

# Safer delete with dry run first
rsync -avn --delete /source/ /dest/
rsync -av --delete /source/ /dest/

# Maximum verbosity
rsync -avvv /source/ /dest/
```

#### Progress monitoring
```bash
# Show progress for each file
rsync -av --progress /source/ /dest/

# Show overall statistics
rsync -av --stats /source/ /dest/
```

### 12.2.6 Compressing Data

```bash
# Enable compression (good for slow networks)
rsync -avz /source/ user@remote:/dest/

# Adjust compression level (1-9, 6 is default)
rsync -av --compress-level=1 /source/ /dest/

# Skip compression for certain file types
rsync -avz --skip-compress=jpg,png,mp4 /source/ /dest/
```

### 12.2.7 Limiting Bandwidth

```bash
# Limit to 1000 KB/s
rsync -av --bwlimit=1000 /source/ /dest/

# Useful for background transfers
rsync -av --bwlimit=500 /large_backup/ /dest/
```

### 12.2.8 Transferring Files to Your Computer

```bash
# Pull files from remote server
rsync -av user@server:/home/user/docs/ ~/local_docs/

# Pull with compression and progress
rsync -avz --progress user@server:/var/www/ ~/website_backup/
```

### 12.2.9 Further rsync Topics

#### Advanced Options (Often Missed in Basic Tutorials)
```bash
# Partial transfers (resume interrupted transfers)
rsync -av --partial /source/ /dest/

# Keep partially transferred files
rsync -av --partial-dir=.rsync-partial /source/ /dest/

# Update only (don't replace newer files)
rsync -av -u /source/ /dest/

# Backup changed files
rsync -av --backup --backup-dir=backup-$(date +%Y%m%d) /source/ /dest/

# Hard links for space-efficient backups
rsync -av --link-dest=../previous_backup /source/ /current_backup/
```

#### rsync daemon mode
```bash
# Start rsync daemon
rsync --daemon

# Connect to rsync daemon
rsync -av rsync://server/module/path/ /local/path/
```

---

## 12.3 Introduction to File Sharing

### 12.3.1 File Sharing Usage and Performance

**Key Considerations**:
- **Latency**: Network round-trip time affects small file operations
- **Bandwidth**: Large file transfers limited by network capacity
- **Concurrent Access**: Multiple users accessing shared files
- **Caching**: Local caching can dramatically improve performance

**Performance Hierarchy** (fastest to slowest):
1. Local filesystem
2. NFS over high-speed LAN
3. SSHFS over LAN
4. Samba/CIFS over LAN
5. Any protocol over WAN

### 12.3.2 File Sharing Security

**Security Models**:
- **Authentication**: Who can access?
- **Authorization**: What can they access?
- **Encryption**: Is data protected in transit?
- **Auditing**: Can you track access?

**Protocol Security Comparison**:
- **NFS**: Traditionally weak security, NFSv4 with Kerberos improves this
- **Samba**: Good authentication, optional encryption
- **SSHFS**: Strong encryption and authentication via SSH

---

## 12.4 Sharing Files with Samba

### Understanding Samba
**Definition**: Samba implements SMB/CIFS protocol, enabling Linux systems to share files with Windows systems

**Key Components**:
- `smbd` - File sharing daemon
- `nmbd` - NetBIOS name service daemon
- `winbindd` - Windows domain integration daemon

### 12.4.1 Server Configuration

#### Main configuration file: /etc/samba/smb.conf
```ini
[global]
    workgroup = WORKGROUP
    server string = Samba Server %v
    netbios name = LINUXSERVER
    security = user
    map to guest = bad user
    dns proxy = no

# Share definition
[shared]
    comment = Shared Folder
    path = /srv/samba/shared
    browseable = yes
    writable = yes
    guest ok = no
    valid users = @sambausers
```

#### Essential global options
- `workgroup` - Windows workgroup name
- `security` - Authentication method (user, share, domain)
- `encrypt passwords` - Use encrypted passwords (default yes)
- `server role` - Define server role (standalone, member server, etc.)

### 12.4.2 Server Access Control

#### User-based access control
```ini
[finance]
    comment = Finance Department Files
    path = /srv/samba/finance
    valid users = alice, bob, @finance
    write list = alice, @managers
    read only = no
    create mask = 0664
    directory mask = 0775
```

#### Host-based access control
```ini
[secure]
    comment = Secure Share
    path = /srv/samba/secure
    hosts allow = 192.168.1. 10.0.0.5
    hosts deny = ALL
```

### 12.4.3 Passwords

#### Managing Samba users
```bash
# Add Samba user (must be system user first)
useradd sambauser
smbpasswd -a sambauser

# Change Samba password
smbpasswd sambauser

# Disable Samba user
smbpasswd -d sambauser

# List Samba users
pdbedit -L -v
```

**Important**: Samba maintains separate password database from system passwords

### 12.4.4 Manual Server Startup

```bash
# Start Samba services
systemctl start smbd nmbd

# Enable automatic startup
systemctl enable smbd nmbd

# Check status
systemctl status smbd nmbd

# Manual daemon startup (for debugging)
smbd -F -S
nmbd -F -S
```

### 12.4.5 Diagnostics and Logfiles

#### Testing configuration
```bash
# Test smb.conf syntax
testparm

# Test with specific config file
testparm /etc/samba/smb.conf

# Show default settings
testparm -v
```

#### Log files
- `/var/log/samba/log.smbd` - smbd daemon logs
- `/var/log/samba/log.nmbd` - nmbd daemon logs
- `/var/log/samba/log.clientname` - Per-client logs

#### Debugging options
```ini
[global]
    log level = 3
    log file = /var/log/samba/log.%m
    max log size = 1000
```

### 12.4.6 File Share Configuration

#### Advanced share options
```ini
[development]
    comment = Development Files
    path = /srv/samba/dev
    browseable = yes
    writable = yes
    create mask = 0664
    directory mask = 0775
    force group = developers
    force user = devowner
    veto files = /*.exe/*.com/*.bat/
    hide dot files = yes
```

**Important Options**:
- `create mask` - Permissions for new files
- `directory mask` - Permissions for new directories
- `force user/group` - Override file ownership
- `veto files` - Prevent access to certain files
- `hide dot files` - Hide hidden files from Windows

### 12.4.7 Home Directories

```ini
[homes]
    comment = Home Directories
    browseable = no
    writable = yes
    valid users = %S
    create mask = 0700
    directory mask = 0700
    root preexec = /usr/local/bin/make_homedir.sh %S
```

**Special Variables**:
- `%S` - Current share name
- `%u` - Current username
- `%g` - Primary group of %u
- `%h` - Home directory of %u

### 12.4.8 Printer Sharing

```ini
[printers]
    comment = All Printers
    path = /var/spool/samba
    browseable = no
    guest ok = yes
    writable = no
    printable = yes
    print command = lpr -P %p %s
    lpq command = lpq -P %p
    lprm command = lprm -P %p %j
```

### 12.4.9 The Samba Client

#### Command-line client tools
```bash
# List shares on server
smbclient -L //server -U username

# Connect to share
smbclient //server/share -U username

# Mount share
mount -t cifs //server/share /mnt/point -o username=user,password=pass

# Mount with credentials file
mount -t cifs //server/share /mnt/point -o credentials=/home/user/.smbcreds

# Unmount
umount /mnt/point
```

#### Credentials file format
```
# ~/.smbcreds (mode 600)
username=myuser
password=mypassword
domain=MYDOMAIN
```

#### Persistent mounting in /etc/fstab
```
//server/share /mnt/share cifs credentials=/home/user/.smbcreds,uid=1000,gid=1000,iocharset=utf8 0 0
```

---

## 12.5 SSHFS

### Understanding SSHFS
**Definition**: SSHFS (SSH Filesystem) allows mounting remote directories over SSH using FUSE

**Advantages**:
- Uses existing SSH infrastructure
- Strong encryption and authentication
- No additional server-side configuration needed
- Works through firewalls and NAT

**Disadvantages**:
- Higher latency than NFS
- Limited performance for large file operations
- Requires SSH access

### Basic SSHFS Usage

```bash
# Mount remote directory
sshfs user@server:/remote/path /local/mountpoint

# Mount with specific SSH options
sshfs -o Port=2222,IdentityFile=/home/user/.ssh/id_rsa user@server:/path /mnt

# Unmount
fusermount -u /local/mountpoint
```

### Advanced SSHFS Options

```bash
# Performance optimization
sshfs -o cache=yes,compression=yes,large_read user@server:/path /mnt

# Allow other users to access
sshfs -o allow_other user@server:/path /mnt

# Reconnect on connection loss
sshfs -o reconnect user@server:/path /mnt

# Debug connection issues
sshfs -o debug,sshfs_debug user@server:/path /mnt
```

### Persistent SSHFS Mounts

#### In /etc/fstab
```
user@server:/remote/path /local/path fuse.sshfs defaults,_netdev,users,allow_other,IdentityFile=/home/user/.ssh/id_rsa 0 0
```

#### Systemd mount unit
```ini
# /etc/systemd/system/mnt-remote.mount
[Unit]
Description=SSHFS mount for remote server
After=network.target

[Mount]
What=user@server:/remote/path
Where=/mnt/remote
Type=fuse.sshfs
Options=_netdev,users,allow_other,IdentityFile=/home/user/.ssh/id_rsa

[Install]
WantedBy=multi-user.target
```

---

## 12.6 NFS (Network File System)

### Understanding NFS
**Definition**: NFS allows sharing of filesystems between Unix/Linux systems

**Versions**:
- **NFSv3**: Traditional, stateless, widely supported
- **NFSv4**: Modern, stateful, better security and performance

### NFS Server Configuration

#### Main configuration file: /etc/exports
```
# Format: directory client(options)
/srv/nfs/public *(ro,sync,no_subtree_check)
/srv/nfs/private 192.168.1.0/24(rw,sync,no_root_squash)
/home 10.0.0.0/8(rw,sync,root_squash,no_subtree_check)
```

#### Common export options
- `ro/rw` - Read-only or read-write
- `sync/async` - Synchronous or asynchronous writes
- `root_squash/no_root_squash` - Map root to nobody or preserve root
- `all_squash` - Map all users to nobody
- `no_subtree_check` - Disable subtree checking (recommended)
- `secure` - Require requests from ports < 1024

#### Managing exports
```bash
# Reload exports
exportfs -ra

# List current exports
exportfs -v

# Export specific directory
exportfs -o rw,sync,no_root_squash 192.168.1.100:/srv/nfs/share

# Remove export
exportfs -u 192.168.1.100:/srv/nfs/share
```

### NFS Client Usage

```bash
# Show available exports
showmount -e nfs-server

# Mount NFS share
mount -t nfs nfs-server:/srv/nfs/share /mnt/nfs

# Mount with specific version
mount -t nfs -o vers=4 server:/share /mnt

# Unmount
umount /mnt/nfs
```

### Advanced NFS Configuration

#### NFSv4-specific configuration
```
# /etc/exports for NFSv4
/srv/nfs/root *(rw,sync,fsid=0,crossmnt,no_subtree_check)
/srv/nfs/root/public *(ro,sync,no_subtree_check)
/srv/nfs/root/private 192.168.1.0/24(rw,sync,no_subtree_check)
```

#### Performance tuning
```bash
# Client-side tuning
mount -t nfs -o vers=4,rsize=32768,wsize=32768,hard,intr server:/share /mnt

# Server-side tuning (adjust thread count)
echo 16 > /proc/fs/nfsd/threads
```

---

## 12.7 Cloud Storage

### Integration Strategies
**Common approaches**:
- **Cloud-native tools**: aws-cli, gsutil, azure-cli
- **FUSE filesystems**: s3fs, gcsfuse, blobfuse
- **Synchronization tools**: rclone, CloudMounter
- **Backup solutions**: Duplicity, restic, borgbackup

### Example: rclone for cloud sync
```bash
# Configure cloud provider
rclone config

# List files
rclone ls remote:bucket/path

# Sync local to cloud
rclone sync /local/path remote:bucket/path

# Mount cloud storage
rclone mount remote:bucket /mnt/cloud
```

---

## 12.8 The State of Network File Sharing

### Protocol Selection Guidelines

**Choose NFS when**:
- Unix/Linux-only environment
- High performance requirements
- Trusted network environment
- Need POSIX compliance

**Choose Samba when**:
- Mixed Windows/Linux environment
- Need Windows ACL support
- User-friendly browsing required
- Active Directory integration needed

**Choose SSHFS when**:
- Security is paramount
- Firewall traversal needed
- Occasional access pattern
- No server-side configuration possible

**Choose cloud storage when**:
- Geographic distribution needed
- Backup and archival primary use
- Integration with cloud services
- Cost-effective for infrequent access

---

## Additional Concepts (Often Missed)

### Bandwidth and Latency Optimization
**Concept**: Understanding the difference between bandwidth and latency impact
- **High bandwidth, high latency**: Good for large file transfers, poor for many small files
- **Low bandwidth, low latency**: Better for interactive use with small files

### File Locking and Concurrency
**Important**: Different protocols handle concurrent access differently
- **NFS**: Supports file locking but can be problematic
- **Samba**: Good Windows-style opportunistic locking
- **SSHFS**: No server-side locking support

### Backup Strategy Integration
**Practical Application**: How file sharing fits into backup strategies
- Use rsync for efficient incremental backups
- Combine with snapshot-capable filesystems (LVM, ZFS, Btrfs)
- Implement 3-2-1 backup rule (3 copies, 2 different media, 1 offsite)

### Security Best Practices
**Critical for Production**:
- Regular security updates for all file sharing software
- Network segmentation for file servers
- Monitoring and logging of access patterns
- Principle of least privilege for share permissions
- Regular audit of user access and permissions

---

## Summary

### Key Takeaways
1. **rsync is the gold standard** for efficient file synchronization and backup
2. **Protocol choice depends on environment**: NFS for Unix, Samba for mixed, SSHFS for security
3. **Security and performance are often trade-offs** - understand your requirements
4. **Proper testing is crucial** - always test in lab environment before production
5. **Monitoring and maintenance** are ongoing requirements for file sharing systems

### Essential Commands to Remember
```bash
# rsync basics
rsync -avz --progress source/ destination/

# Samba testing
testparm
smbclient -L //server -U username

# NFS management
exportfs -ra
showmount -e server

# SSHFS mounting
sshfs user@server:/path /mnt
fusermount -u /mnt
```

---

## Personal Notes
Space for your own insights, questions, and observations while studying.