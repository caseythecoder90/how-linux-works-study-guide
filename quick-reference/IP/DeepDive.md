# IP Addressing and Subnetting - Complete Deep Dive Guide

## Table of Contents
1. [IPv4 Fundamentals](#ipv4-fundamentals)
2. [Binary and Decimal Conversion](#binary-and-decimal-conversion)
3. [Subnet Masks Deep Dive](#subnet-masks-deep-dive)
4. [CIDR Notation Mastery](#cidr-notation-mastery)
5. [Subnetting Calculations](#subnetting-calculations)
6. [IPv6 Complete Guide](#ipv6-complete-guide)
7. [Practical Examples](#practical-examples)
8. [Memory Techniques](#memory-techniques)

---

## IPv4 Fundamentals

### What is an IPv4 Address?
An IPv4 address is a 32-bit number that uniquely identifies a device on a network. It's written as four decimal numbers (octets) separated by dots.

**Structure**: `192.168.1.100`
- Each octet represents 8 bits
- Each octet ranges from 0 to 255 (2^8 = 256 possible values)
- Total possible addresses: 2^32 = 4,294,967,296

### Binary Representation
Every IPv4 address is actually a 32-bit binary number:

```
192.168.1.100 in binary:
192 = 11000000
168 = 10101000
1   = 00000001
100 = 01100100

Full binary: 11000000.10101000.00000001.01100100
```

### Address Classes (Historical but Important to Understand)

| Class | Range | Default Mask | Network Bits | Host Bits | Max Networks | Max Hosts |
|-------|-------|--------------|--------------|-----------|--------------|-----------|
| A | 1-126 | /8 (255.0.0.0) | 8 | 24 | 126 | 16,777,214 |
| B | 128-191 | /16 (255.255.0.0) | 16 | 16 | 16,384 | 65,534 |
| C | 192-223 | /24 (255.255.255.0) | 24 | 8 | 2,097,152 | 254 |
| D | 224-239 | N/A (Multicast) | N/A | N/A | N/A | N/A |
| E | 240-255 | N/A (Reserved) | N/A | N/A | N/A | N/A |

**Special Addresses:**
- **127.x.x.x**: Loopback (localhost)
- **0.0.0.0**: This network
- **255.255.255.255**: Broadcast

---

## Binary and Decimal Conversion

### Why Binary Matters
Understanding binary is crucial for subnetting because:
- Subnet masks work at the bit level
- Network boundaries are determined by binary calculations
- CIDR notation directly relates to binary bits

### Quick Conversion Reference

#### Powers of 2 (Essential to Memorize)
```
2^0 = 1       2^4 = 16      2^8 = 256
2^1 = 2       2^5 = 32      2^16 = 65,536
2^2 = 4       2^6 = 64      2^24 = 16,777,216
2^3 = 8       2^7 = 128     2^32 = 4,294,967,296
```

#### Binary to Decimal Conversion
Each bit position has a value:
```
Position: 8  7  6  5  4  3  2  1
Value:   128 64 32 16  8  4  2  1
```

**Example: Convert 11000000 to decimal**
```
1×128 + 1×64 + 0×32 + 0×16 + 0×8 + 0×4 + 0×2 + 0×1 = 192
```

#### Decimal to Binary Conversion
**Method**: Subtract largest possible powers of 2

**Example: Convert 192 to binary**
```
192 - 128 = 64 (use 128, bit 8 = 1)
64 - 64 = 0    (use 64, bit 7 = 1)
Remaining bits = 0

Result: 11000000
```

### Practice Problems
Convert these decimal numbers to binary:
1. 255 → ________
2. 128 → ________
3. 172 → ________
4. 10 → ________

**Answers:**
1. 255 → 11111111
2. 128 → 10000000
3. 172 → 10101100
4. 10 → 00001010

---

## Subnet Masks Deep Dive

### What Subnet Masks Really Do
A subnet mask separates the network portion from the host portion of an IP address using binary AND operations.

### Common Subnet Masks and Their Meanings

#### /8 Subnet Mask (255.0.0.0)
```
Binary: 11111111.00000000.00000000.00000000
- Network bits: 8
- Host bits: 24
- Possible hosts: 2^24 - 2 = 16,777,214
- Network range example: 10.0.0.0 to 10.255.255.255
```

#### /16 Subnet Mask (255.255.0.0)
```
Binary: 11111111.11111111.00000000.00000000
- Network bits: 16
- Host bits: 16
- Possible hosts: 2^16 - 2 = 65,534
- Network range example: 172.16.0.0 to 172.16.255.255
```

#### /24 Subnet Mask (255.255.255.0)
```
Binary: 11111111.11111111.11111111.00000000
- Network bits: 24
- Host bits: 8
- Possible hosts: 2^8 - 2 = 254
- Network range example: 192.168.1.0 to 192.168.1.255
```

### Variable Length Subnet Masks (VLSM)

#### /25 Subnet (255.255.255.128)
```
Binary: 11111111.11111111.11111111.10000000
- Splits a /24 network into 2 subnets
- Each subnet has 126 hosts (2^7 - 2)

Example with 192.168.1.0/24:
- Subnet 1: 192.168.1.0/25 (192.168.1.0 - 192.168.1.127)
- Subnet 2: 192.168.1.128/25 (192.168.1.128 - 192.168.1.255)
```

#### /26 Subnet (255.255.255.192)
```
Binary: 11111111.11111111.11111111.11000000
- Splits a /24 network into 4 subnets
- Each subnet has 62 hosts (2^6 - 2)

Example with 192.168.1.0/24:
- Subnet 1: 192.168.1.0/26   (192.168.1.0 - 192.168.1.63)
- Subnet 2: 192.168.1.64/26  (192.168.1.64 - 192.168.1.127)
- Subnet 3: 192.168.1.128/26 (192.168.1.128 - 192.168.1.191)
- Subnet 4: 192.168.1.192/26 (192.168.1.192 - 192.168.1.255)
```

#### /27 Subnet (255.255.255.224)
```
Binary: 11111111.11111111.11111111.11100000
- Splits a /24 network into 8 subnets
- Each subnet has 30 hosts (2^5 - 2)

Increment: 256 - 224 = 32

Subnets:
- 192.168.1.0/27    (192.168.1.0 - 192.168.1.31)
- 192.168.1.32/27   (192.168.1.32 - 192.168.1.63)
- 192.168.1.64/27   (192.168.1.64 - 192.168.1.95)
- 192.168.1.96/27   (192.168.1.96 - 192.168.1.127)
- 192.168.1.128/27  (192.168.1.128 - 192.168.1.159)
- 192.168.1.160/27  (192.168.1.160 - 192.168.1.191)
- 192.168.1.192/27  (192.168.1.192 - 192.168.1.223)
- 192.168.1.224/27  (192.168.1.224 - 192.168.1.255)
```

### Complete CIDR Reference Table

| CIDR | Subnet Mask | Wildcard | Hosts | Subnets from /24 |
|------|-------------|----------|-------|------------------|
| /8 | 255.0.0.0 | 0.255.255.255 | 16,777,214 | 1/65536 |
| /9 | 255.128.0.0 | 0.127.255.255 | 8,388,606 | 1/32768 |
| /10 | 255.192.0.0 | 0.63.255.255 | 4,194,302 | 1/16384 |
| /11 | 255.224.0.0 | 0.31.255.255 | 2,097,150 | 1/8192 |
| /12 | 255.240.0.0 | 0.15.255.255 | 1,048,574 | 1/4096 |
| /13 | 255.248.0.0 | 0.7.255.255 | 524,286 | 1/2048 |
| /14 | 255.252.0.0 | 0.3.255.255 | 262,142 | 1/1024 |
| /15 | 255.254.0.0 | 0.1.255.255 | 131,070 | 1/512 |
| /16 | 255.255.0.0 | 0.0.255.255 | 65,534 | 1/256 |
| /17 | 255.255.128.0 | 0.0.127.255 | 32,766 | 1/128 |
| /18 | 255.255.192.0 | 0.0.63.255 | 16,382 | 1/64 |
| /19 | 255.255.224.0 | 0.0.31.255 | 8,190 | 1/32 |
| /20 | 255.255.240.0 | 0.0.15.255 | 4,094 | 1/16 |
| /21 | 255.255.248.0 | 0.0.7.255 | 2,046 | 1/8 |
| /22 | 255.255.252.0 | 0.0.3.255 | 1,022 | 1/4 |
| /23 | 255.255.254.0 | 0.0.1.255 | 510 | 1/2 |
| /24 | 255.255.255.0 | 0.0.0.255 | 254 | 1 |
| /25 | 255.255.255.128 | 0.0.0.127 | 126 | 2 |
| /26 | 255.255.255.192 | 0.0.0.63 | 62 | 4 |
| /27 | 255.255.255.224 | 0.0.0.31 | 30 | 8 |
| /28 | 255.255.255.240 | 0.0.0.15 | 14 | 16 |
| /29 | 255.255.255.248 | 0.0.0.7 | 6 | 32 |
| /30 | 255.255.255.252 | 0.0.0.3 | 2 | 64 |
| /31 | 255.255.255.254 | 0.0.0.1 | 2* | 128 |
| /32 | 255.255.255.255 | 0.0.0.0 | 1* | 256 |

**/31 and /32 are special cases:**
- /31: Point-to-point links (no network/broadcast addresses)
- /32: Host routes (single IP address)

---

## CIDR Notation Mastery

### Understanding CIDR
CIDR (Classless Inter-Domain Routing) notation combines an IP address with its subnet mask length.

**Format**: `IP_address/prefix_length`
**Example**: `192.168.1.0/24`

### Quick CIDR Calculations

#### Method 1: Powers of 2
**To find number of hosts:**
1. Calculate host bits: 32 - CIDR prefix
2. Calculate hosts: 2^(host bits) - 2

**Example: 192.168.1.0/26**
- Host bits: 32 - 26 = 6
- Hosts: 2^6 - 2 = 64 - 2 = 62

#### Method 2: Subnet Increment
**To find subnet boundaries:**
1. Find the last octet of subnet mask
2. Subtract from 256 to get increment
3. Count by increments

**Example: /27 (255.255.255.224)**
- Last octet: 224
- Increment: 256 - 224 = 32
- Subnets: 0, 32, 64, 96, 128, 160, 192, 224

### Subnetting a /24 Network

**Scenario**: You have 192.168.1.0/24 and need 4 subnets with at least 50 hosts each.

**Solution**:
1. **Determine required subnet bits**: Need 4 subnets = 2^2, so need 2 bits
2. **New CIDR**: /24 + 2 = /26
3. **Verify host count**: 32 - 26 = 6 host bits = 2^6 - 2 = 62 hosts ✓

**Resulting subnets**:
- 192.168.1.0/26   (192.168.1.0 - 192.168.1.63)
- 192.168.1.64/26  (192.168.1.64 - 192.168.1.127)
- 192.168.1.128/26 (192.168.1.128 - 192.168.1.191)
- 192.168.1.192/26 (192.168.1.192 - 192.168.1.255)

---

## IPv6 Complete Guide

### IPv6 Fundamentals
IPv6 uses 128-bit addresses written in hexadecimal, providing 340 undecillion possible addresses.

**Format**: `2001:0db8:85a3:0000:0000:8a2e:0370:7334`

### IPv6 Address Structure

#### Hexadecimal Basics
IPv6 uses base-16 (hexadecimal) numbers:
```
0, 1, 2, 3, 4, 5, 6, 7, 8, 9, A, B, C, D, E, F
```

Each hex digit represents 4 bits:
```
0 = 0000    8 = 1000
1 = 0001    9 = 1001
2 = 0010    A = 1010
3 = 0011    B = 1011
4 = 0100    C = 1100
5 = 0101    D = 1101
6 = 0110    E = 1110
7 = 0111    F = 1111
```

#### IPv6 Address Components
```
2001:0db8:85a3:0000:0000:8a2e:0370:7334
|--------Network Prefix--------|--Interface ID--|

Typically:
- First 64 bits: Network prefix (subnet)
- Last 64 bits: Interface identifier (host)
```

### IPv6 Address Types and Ranges

#### Global Unicast Addresses (Internet-routable)
```
Range: 2000::/3 (2000:: to 3FFF:FFFF:FFFF:FFFF:FFFF:FFFF:FFFF:FFFF)

Structure:
+----------+--------+--------+----------+
| Global   |Subnet  |Subnet  |Interface |
| Routing  |Prefix  |ID      |ID        |
| Prefix   |        |        |          |
+----------+--------+--------+----------+
   48 bits   16 bits  0-16 bits  64 bits
```

**Example**: `2001:db8:1234:5678::1/64`
- `2001:db8:1234:5678`: Network portion
- `::1`: Host portion (::1 = interface ID of 1)

#### Link-Local Addresses (Local network only)
```
Range: FE80::/10 (FE80:: to FEBF:FFFF:FFFF:FFFF:FFFF:FFFF:FFFF:FFFF)
Commonly: FE80::/64

Structure:
FE80:0000:0000:0000:interface_identifier
```

**Examples**:
- `fe80::1`
- `fe80::a00:27ff:fe4e:66a1`
- `fe80::1%eth0` (with zone identifier)

#### Unique Local Addresses (Private, like RFC 1918)
```
Range: FC00::/7 (FC00:: to FDFF:FFFF:FFFF:FFFF:FFFF:FFFF:FFFF:FFFF)
Commonly: FD00::/8

Structure:
FD + 40-bit Global ID + 16-bit Subnet ID + 64-bit Interface ID
```

**Example**: `fd12:3456:789a:1::1/64`

#### Multicast Addresses
```
Range: FF00::/8

Structure:
FF + Flags(4 bits) + Scope(4 bits) + 112-bit Group ID

Common examples:
- FF02::1 (All nodes on local segment)
- FF02::2 (All routers on local segment)
- FF02::5 (All OSPF routers)
```

#### Special Addresses
```
::1/128        - Loopback (equivalent to 127.0.0.1)
::/128         - Unspecified address (equivalent to 0.0.0.0)
::/0           - Default route (equivalent to 0.0.0.0/0)
::FFFF:0:0/96  - IPv4-mapped IPv6 (::FFFF:192.168.1.1)
```

### IPv6 Address Compression Rules

#### Zero Compression
IPv6 allows compression of consecutive zero fields:

**Original**: `2001:0db8:0000:0000:0000:0000:0000:0001`
**Compressed**: `2001:db8::1`

**Rules**:
1. Leading zeros in each field can be omitted
2. Consecutive zero fields can be replaced with `::`
3. `::` can only be used once per address
4. `::` must represent at least one 16-bit field of zeros

#### Examples of Compression
```
2001:0db8:85a3:0000:0000:8a2e:0370:7334
↓ Remove leading zeros
2001:db8:85a3:0:0:8a2e:370:7334
↓ Compress consecutive zeros
2001:db8:85a3::8a2e:370:7334

FE80:0000:0000:0000:0000:0000:0000:0001
↓ Compress
FE80::1

2001:0db8:0000:0000:0000:0000:0000:0000
↓ Compress
2001:db8::
```

### IPv6 Subnetting

#### Standard IPv6 Subnetting
Most IPv6 subnets use /64, providing 18 quintillion host addresses per subnet.

**Example**: `2001:db8::/32` allocated to organization
```
Available for subnetting: 32 bits (bits 33-64)
Possible subnets: 2^32 = 4,294,967,296 /64 subnets

Subnet examples:
2001:db8:0:0::/64    (2001:db8::/64)
2001:db8:0:1::/64    (2001:db8:0:1::/64)
2001:db8:0:2::/64    (2001:db8:0:2::/64)
...
2001:db8:ffff:ffff::/64
```

#### Hierarchical Subnetting
```
ISP allocation: 2001:db8::/32

Customer 1: 2001:db8:0::/48 (65,536 /64 subnets)
Customer 2: 2001:db8:1::/48 (65,536 /64 subnets)
...
Customer 65536: 2001:db8:ffff::/48

Customer 1 can further subnet:
Site 1: 2001:db8:0:0::/56 (256 /64 subnets)
Site 2: 2001:db8:0:100::/56 (256 /64 subnets)
...
```

### IPv6 CIDR Examples

#### Common IPv6 Prefix Lengths
```
/32  - ISP allocation (4 billion /64 subnets)
/48  - Large enterprise (65,536 /64 subnets)
/56  - Small enterprise (256 /64 subnets)
/64  - Single subnet (standard)
/128 - Single host (host route)
```

#### Calculating IPv6 Subnets
**Example**: How many /64 subnets in 2001:db8::/48?

**Solution**:
- Available bits for subnetting: 64 - 48 = 16 bits
- Number of /64 subnets: 2^16 = 65,536

### IPv6 Address Assignment Methods

#### Stateless Address Autoconfiguration (SLAAC)
Hosts automatically configure their own addresses:
```
1. Generate link-local address (FE80::)
2. Perform Duplicate Address Detection (DAD)
3. Receive Router Advertisement with prefix
4. Generate global address: Prefix + Interface ID
```

#### DHCPv6
Centralized address assignment:
```
- Stateful: DHCPv6 assigns complete address
- Stateless: DHCPv6 provides DNS, domain, etc.
```

#### Manual Configuration
```
# Add IPv6 address
ip -6 addr add 2001:db8::1/64 dev eth0

# Add IPv6 route
ip -6 route add 2001:db8:1::/64 via 2001:db8::1
```

---

## Practical Examples

### Example 1: Corporate Network Design

**Requirement**: Design network for company with 4 departments:
- IT: 50 devices
- Sales: 30 devices
- Marketing: 20 devices
- Finance: 15 devices
- Growth capacity: 25% for each department

**Given network**: 192.168.0.0/24

**Solution**:
1. **Calculate requirements with growth**:
    - IT: 50 × 1.25 = 63 devices
    - Sales: 30 × 1.25 = 38 devices
    - Marketing: 20 × 1.25 = 25 devices
    - Finance: 15 × 1.25 = 19 devices

2. **Choose subnet size**: /26 provides 62 hosts, /25 provides 126 hosts
    - Use /26 for Finance and Marketing
    - Use /25 for Sales and IT

3. **Subnet allocation**:
   ```
   IT:        192.168.0.0/25   (192.168.0.0 - 192.168.0.127)    126 hosts
   Sales:     192.168.0.128/26 (192.168.0.128 - 192.168.0.191)  62 hosts
   Marketing: 192.168.0.192/26 (192.168.0.192 - 192.168.0.223)  62 hosts
   Finance:   192.168.0.224/27 (192.168.0.224 - 192.168.0.255)  30 hosts
   ```

### Example 2: IPv6 Enterprise Design

**Scenario**: ISP allocates 2001:db8:1000::/40 to your organization

**Design**:
```
Available for subnetting: 64 - 40 = 24 bits
Total /64 subnets available: 2^24 = 16,777,216

Regional allocation (/44 - 1,048,576 /64 subnets each):
Americas:  2001:db8:1000::/44
Europe:    2001:db8:1100::/44
Asia:      2001:db8:1200::/44

Site allocation within Americas (/48 - 65,536 /64 subnets each):
New York:  2001:db8:1000::/48
Chicago:   2001:db8:1001::/48
LA:        2001:db8:1002::/48

Department allocation within New York (/56 - 256 /64 subnets each):
IT:        2001:db8:1000:0::/56
Sales:     2001:db8:1000:100::/56
Finance:   2001:db8:1000:200::/56

Subnet allocation within IT department:
Servers:   2001:db8:1000:0:0::/64
Desktops:  2001:db8:1000:0:1::/64
Printers:  2001:db8:1000:0:2::/64
WiFi:      2001:db8:1000:0:10::/64
```

---

## Memory Techniques

### IPv4 Quick Reference Tricks

#### Powers of 2 Memorization
```
"1 2 4 8, 16 32 64 128" (rhythm: ta-ta-ta-ta, ta-ta-ta-ta)
"256, 512, 1024, 2048" (continue the pattern)
```

#### Subnet Mask Patterns
```
128 = 10000000 (1 bit)
192 = 11000000 (2 bits)  
224 = 11100000 (3 bits)
240 = 11110000 (4 bits)
248 = 11111000 (5 bits)
252 = 11111100 (6 bits)
254 = 11111110 (7 bits)
255 = 11111111 (8 bits)

Memory trick: Each adds one more '1' bit from the left
```

#### CIDR Host Calculation Shortcut
```
/24 = 254 hosts (256 - 2)
/25 = 126 hosts (128 - 2)
/26 = 62 hosts  (64 - 2)
/27 = 30 hosts  (32 - 2)
/28 = 14 hosts  (16 - 2)
/29 = 6 hosts   (8 - 2)
/30 = 2 hosts   (4 - 2)

Pattern: 2^(32-CIDR) - 2
```

### IPv6 Memory Techniques

#### Address Type Recognition
```
2xxx or 3xxx = Global Unicast (Internet)
FE8x = Link-Local
FDxx = Unique Local (Private)
FFxx = Multicast
::1 = Loopback
```

#### Common Prefixes
```
2001:db8::/32 = Documentation prefix (like 192.0.2.0/24 for IPv4)
2000::/3 = Global unicast range
FE80::/10 = Link-local range
FF00::/8 = Multicast range
```

#### Hex Conversion Memory Aid
```
A=10, B=11, C=12, D=13, E=14, F=15
"All Boys Can Do Everything Fine" = A B C D E F
```

---

## Practice Exercises

### IPv4 Subnetting Practice

#### Exercise 1: Basic Subnetting
Given: 172.16.0.0/16
Create 4 subnets with equal size. What are the subnet addresses?

**Solution**:
- Need 2 bits for 4 subnets (2^2 = 4)
- New mask: /16 + 2 = /18
- Increment: 256 - 192 = 64 (in third octet)
- Subnets:
    - 172.16.0.0/18 (172.16.0.0 - 172.16.63.255)
    - 172.16.64.0/18 (172.16.64.0 - 172.16.127.255)
    - 172.16.128.0/18 (172.16.128.0 - 172.16.191.255)
    - 172.16.192.0/18 (172.16.192.0 - 172.16.255.255)

#### Exercise 2: VLSM (Variable Length Subnet Masking)
Given: 10.0.0.0/24
Create subnets for:
- Network A: 100 hosts
- Network B: 50 hosts
- Network C: 25 hosts
- Network D: 10 hosts

**Solution**:
1. **Order by size** (largest first):
    - A: 100 hosts → need /25 (126 hosts)
    - B: 50 hosts → need /26 (62 hosts)
    - C: 25 hosts → need /27 (30 hosts)
    - D: 10 hosts → need /28 (14 hosts)

2. **Allocate sequentially**:
    - A: 10.0.0.0/25 (10.0.0.0 - 10.0.0.127)
    - B: 10.0.0.128/26 (10.0.0.128 - 10.0.0.191)
    - C: 10.0.0.192/27 (10.0.0.192 - 10.0.0.223)
    - D: 10.0.0.224/28 (10.0.0.224 - 10.0.0.239)

### IPv6 Practice

#### Exercise 3: IPv6 Address Analysis
Analyze: `2001:db8:85a3::8a2e:370:7334/64`

**Solution**:
- **Address type**: Global unicast (starts with 2xxx)
- **Network portion