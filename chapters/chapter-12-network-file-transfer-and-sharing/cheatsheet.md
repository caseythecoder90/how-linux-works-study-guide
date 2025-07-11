# Chapter 12: Network File Transfer and Sharing Flashcards

## rsync Fundamentals

### Card 1
**Q:** What is the key advantage of rsync over scp for file transfers?
**A:** rsync only transfers the differences between source and destination files, dramatically reducing bandwidth usage and transfer time for incremental updates.

### Card 2
**Q:** What's the difference between `rsync /source /dest` and `rsync /source/ /dest`?
**A:** Without trailing slash: copies the directory itself. With trailing slash: copies only the contents of the directory.

### Card 3
**Q:** What does the `-a` option in rsync do?
**A:** Archive mode - preserves permissions, timestamps, symbolic links, group/user ownership, and recursively copies directories.

### Card 4
**Q:** How do you perform a dry run with rsync to see what would be transferred?
**A:** `rsync -avn source destination` (the `-n` flag means "dry run")

### Card 5
**Q:** What rsync option deletes files in destination that don't exist in source?
**A:** `--delete` (DANGEROUS - always test with dry run first)

---

## rsync Advanced Options

### Card 6
**Q:** How do you limit rsync bandwidth to 1000 KB/s?
**A:** `rsync -av --bwlimit=1000 source destination`

### Card 7
**Q:** What rsync option enables compression for slow networks?
**A:** `-z` or `--compress`

### Card 8
**Q:** How do you exclude .git directories and .tmp files with rsync?
**A:** `rsync -av --exclude='.git/' --exclude='*.tmp' source destination`

### Card 9
**Q:** What rsync option shows progress for each file being transferred?
**A:** `--progress`

### Card 10
**Q:** How do you resume an interrupted rsync transfer?
**A:** `rsync -av --partial source destination` (keeps partially transferred files)

---

## Samba Configuration

### Card 11
**Q:** What is the main Samba configuration file?
**A:** `/etc/samba/smb.conf`

### Card 12
**Q:** What command tests Samba configuration syntax?
**A:** `testparm`

### Card 13
**Q:** How do you add a user to Samba (assuming they're already a system user)?
**A:** `smbpasswd -a username`

### Card 14
**Q:** What are the two main Samba daemons?
**A:** `smbd` (file sharing) and `nmbd` (NetBIOS name service)

### Card 15
**Q:** In Samba config, what does `valid users = @finance` mean?
**A:** Only members of the 'finance' group can access this share.

---

## Samba Advanced Concepts

### Card 16
**Q:** What's the difference between `create mask` and `directory mask` in Samba?
**A:** `create mask` sets permissions for new files, `directory mask` sets permissions for new directories.

### Card 17
**Q:** What Samba option hides files starting with a dot from Windows clients?
**A:** `hide dot files = yes`

### Card 18
**Q:** How do you mount a Samba share from the command line?
**A:** `mount -t cifs //server/share /mnt/point -o username=user,password=pass`

### Card 19
**Q:** Where should you store Samba credentials for secure mounting?
**A:** In a credentials file (e.g., `~/.smbcreds`) with mode 600, containing username, password, and domain.

### Card 20
**Q:** What command lists available shares on a Samba server?
**A:** `smbclient -L //server -U username`

---

## NFS Configuration

### Card 21
**Q:** What is the main NFS server configuration file?
**A:** `/etc/exports`

### Card 22
**Q:** What does `root_squash` do in NFS exports?
**A:** Maps root user requests to the anonymous user (nobody) for security.

### Card 23
**Q:** How do you reload NFS exports after changing /etc/exports?
**A:** `exportfs -ra`

### Card 24
**Q:** What command shows available NFS exports from a server?
**A:** `showmount -e server`

### Card 25
**Q:** What's the difference between NFSv3 and NFSv4?
**A:** NFSv4 is stateful, has better security features, supports better performance, and includes built-in locking.

---

## NFS Advanced Concepts

### Card 26
**Q:** What does `no_subtree_check` do in NFS exports?
**A:** Disables subtree checking, which improves performance but slightly reduces security. Generally recommended.

### Card 27
**Q:** How do you mount an NFS share with NFSv4 specifically?
**A:** `mount -t nfs -o vers=4 server:/share /mnt`

### Card 28
**Q:** What NFS export option makes a share read-only?
**A:** `ro` (read-only), opposite is `rw` (read-write)

### Card 29
**Q:** In NFSv4, what does `fsid=0` signify?
**A:** It marks the root of the NFSv4 pseudo-filesystem export tree.

### Card 30
**Q:** How do you improve NFS performance for large files?
**A:** Use larger read/write buffer sizes: `mount -o rsize=32768,wsize=32768`

---

## SSHFS

### Card 31
**Q:** What does SSHFS stand for and what does it do?
**A:** SSH Filesystem - mounts remote directories over SSH using FUSE (Filesystem in Userspace).

### Card 32
**Q:** What are the main advantages of SSHFS?
**A:** Uses existing SSH infrastructure, strong encryption, no server-side configuration needed, works through firewalls.

### Card 33
**Q:** How do you mount a remote directory with SSHFS?
**A:** `sshfs user@server:/remote/path /local/mountpoint`

### Card 34
**Q:** How do you unmount an SSHFS filesystem?
**A:** `fusermount -u /local/mountpoint`

### Card 35
**Q:** What SSHFS option allows automatic reconnection on connection loss?
**A:** `-o reconnect`

---

## SSHFS Advanced Options

### Card 36
**Q:** What SSHFS options improve performance?
**A:** `-o cache=yes,compression=yes,large_read`

### Card 37
**Q:** How do you allow other users to access an SSHFS mount?
**A:** `-o allow_other`

### Card 38
**Q:** How do you debug SSHFS connection issues?
**A:** `-o debug,sshfs_debug`

### Card 39
**Q:** How do you make SSHFS mounts persistent across reboots?
**A:** Add entry to `/etc/fstab` with type `fuse.sshfs` and `_netdev` option.

### Card 40
**Q:** What mount option should you use for SSHFS in /etc/fstab to wait for network?
**A:** `_netdev` (mount after network is available)

---

## Protocol Selection and Security

### Card 41
**Q:** When should you choose NFS over Samba?
**A:** Unix/Linux-only environment, high performance needs, trusted network, need POSIX compliance.

### Card 42
**Q:** When should you choose Samba over NFS?
**A:** Mixed Windows/Linux environment, need Windows ACL support, user-friendly browsing, Active Directory integration.

### Card 43
**Q:** When should you choose SSHFS over other protocols?
**A:** Security is paramount, need firewall traversal, occasional access, no server-side configuration possible.

### Card 44
**Q:** Which protocol provides the strongest security by default?
**A:** SSHFS (uses SSH encryption and authentication)

### Card 45
**Q:** What is the recommended security practice for NFS in untrusted networks?
**A:** Use NFSv4 with Kerberos authentication, or use SSH tunneling, or choose a different protocol.

---

## Performance and Troubleshooting

### Card 46
**Q:** Which has better performance for large files: high bandwidth with high latency, or low bandwidth with low latency?
**A:** High bandwidth with high latency is better for large files; low bandwidth with low latency is better for many small files.

### Card 47
**Q:** What's the performance hierarchy of file sharing protocols from fastest to slowest?
**A:** 1. Local filesystem, 2. NFS over LAN, 3. SSHFS over LAN, 4. Samba over LAN, 5. Any protocol over WAN

### Card 48
**Q:** How do you check if Samba services are running?
**A:** `systemctl status smbd nmbd`

### Card 49
**Q:** Where are Samba log files typically located?
**A:** `/var/log/samba/` (log.smbd, log.nmbd, and per-client logs)

### Card 50
**Q:** What command shows currently mounted filesystems including network mounts?
**A:** `mount` or `cat /proc/mounts`

---

## File Transfer Commands

### Card 51
**Q:** How do you copy a file securely over SSH?
**A:** `scp localfile.txt user@remotehost:/path/to/destination/`

### Card 52
**Q:** What scp option preserves file timestamps and permissions?
**A:** `-p` (preserve)

### Card 53
**Q:** How do you copy directories recursively with scp?
**A:** `scp -r local_directory/ user@remotehost:/remote/path/`

### Card 54
**Q:** What's the main limitation of scp compared to rsync?
**A:** scp always transfers the entire file, making it inefficient for large files that change frequently.

### Card 55
**Q:** How do you enable compression with scp?
**A:** `-C` (compression)

---

## Cloud Storage Integration

### Card 56
**Q:** What tool is commonly used for cloud storage synchronization across multiple providers?
**A:** rclone

### Card 57
**Q:** Name three FUSE filesystems for cloud storage.
**A:** s3fs (Amazon S3), gcsfuse (Google Cloud), blobfuse (Azure Blob Storage)

### Card 58
**Q:** What backup strategy rule is recommended for critical data?
**A:** 3-2-1 rule: 3 copies, 2 different media types, 1 offsite

### Card 59
**Q:** How do you mount cloud storage with rclone?
**A:** `rclone mount remote:bucket /mnt/cloud`

### Card 60
**Q:** What rclone command synchronizes local files to cloud storage?
**A:** `rclone sync /local/path remote:bucket/path`

---

## Review Notes
- **Difficulty level**: Medium to Hard
- **Last reviewed**: [Date]
- **Next review**: [Date]
- **Topics needing more practice**:
    - rsync advanced options and exclusion patterns
    - Samba security configuration and troubleshooting
    - NFS performance tuning
    - SSHFS persistent mounting
    - Protocol selection decision making