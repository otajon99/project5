# NTP Server and Client Installation Guide

## Table of Contents
1. [Overview](#overview)
2. [Prerequisites](#prerequisites)
3. [Install NTP Server](#install-ntp-server)
4. [Configure NTP Server](#configure-ntp-server)
5. [Install NTP Client](#install-ntp-client)
6. [Configure NTP Client](#configure-ntp-client)
7. [Firewall Configuration](#firewall-configuration)
8. [Verify Synchronization](#verify-synchronization)
9. [Advanced Configuration](#advanced-configuration)
10. [Troubleshooting](#troubleshooting)
11. [Security Considerations](#security-considerations)
12. [Monitoring NTP](#monitoring-ntp)

---

## Overview

### What is NTP?
- **Network Time Protocol (NTP)** is a networking protocol for clock synchronization
- Ensures accurate time across all systems in a network
- Uses hierarchical time sources (stratum levels)
- Critical for logs, authentication, certificates, and distributed systems

### Time Hierarchy
```
Stratum 0  - Atomic clocks, GPS clocks
Stratum 1  - Primary time servers (directly connected to Stratum 0)
Stratum 2+ - Secondary time servers (sync to higher stratum)
```

### Distribution Options
- **Chrony** (Recommended for most modern Linux)
- **ntpd** (Traditional NTP daemon)
- **systemd-timesyncd** (Basic systemd service)

---

## Prerequisites

### System Requirements
- Linux server (CentOS/RHEL, Ubuntu/Debian, Rocky Linux, etc.)
- Root or sudo privileges
- Internet connectivity (for public NTP servers)
- Network connectivity between server and clients

### Determine OS Version
```bash
# For RHEL/CentOS/Rocky
cat /etc/redhat-release
cat /etc/os-release

# For Ubuntu/Debian
lsb_release -a
cat /etc/os-release
```

### Check Current Time Settings
```bash
# Check current time and timezone
timedatectl status

# Check if NTP is already running
systemctl status chronyd
systemctl status ntpd
systemctl status systemd-timesyncd

# Check existing time servers
chronyc sources
ntpq -p
```

---

## Install NTP Server

### Option 1: Install Chrony (Recommended for Modern Systems)

#### For RHEL/CentOS/Rocky Linux 8/9
```bash
# Install chrony
sudo dnf update -y
sudo dnf install -y chrony

# Enable and start chrony
sudo systemctl enable --now chronyd
```

#### For Ubuntu/Debian
```bash
# Update package index
sudo apt update

# Install chrony
sudo apt install -y chrony

# Enable and start chrony
sudo systemctl enable --now chrony
```

#### For Arch Linux
```bash
# Install chrony
sudo pacman -S chrony

# Enable and start chrony
sudo systemctl enable --now chronyd
```

### Option 2: Install Traditional NTPD

#### For RHEL/CentOS/Rocky Linux
```bash
# Install ntp
sudo dnf install -y ntp

# Stop chrony if running
sudo systemctl stop chronyd
sudo systemctl disable chronyd

# Enable and start ntpd
sudo systemctl enable --now ntpd
```

#### For Ubuntu/Debian
```bash
# Install ntp
sudo apt install -y ntp

# Stop systemd-timesyncd if running
sudo systemctl stop systemd-timesyncd
sudo systemctl disable systemd-timesyncd

# Enable and start ntp
sudo systemctl enable --now ntp
```

---

## Configure NTP Server

### Option 1: Configure Chrony Server

#### Edit chrony.conf
```bash
# Backup original configuration
sudo cp /etc/chrony.conf /etc/chrony.conf.backup

# Edit configuration
sudo nano /etc/chrony.conf
```

#### Sample chrony.conf Configuration
```ini
# /etc/chrony.conf

# Use public servers from the pool.ntp.org project
# Comment out default pools and add specific servers for better control
#pool 2.pool.ntp.org iburst
server 0.pool.ntp.org iburst
server 1.pool.ntp.org iburst
server 2.pool.ntp.org iburst
server 3.pool.ntp.org iburst

# Use driftfile to store frequency offset
driftfile /var/lib/chrony/drift

# Allow the system clock to be stepped in the first three updates
makestep 1.0 3

# Enable kernel synchronization of the real-time clock (RTC)
rtcsync

# Enable hardware timestamping on all interfaces that support it
hwtimestamp *

# Increase the minimum number of selectable sources required to adjust the system clock
minsources 2

# Allow NTP client access from local network
allow 192.168.0.0/16
allow 10.0.0.0/8
allow 172.16.0.0/12

# Serve time even if not synchronized to a time source
local stratum 10

# Specify directory for log files
logdir /var/log/chrony

# Select which information is logged
log measurements statistics tracking

# Enable client access logging
clientloglimit 1000000

# Specify statistics directory
statsdir /var/log/chrony
```

#### Restart chrony
```bash
# Apply configuration changes
sudo systemctl restart chronyd

# Check status
sudo systemctl status chronyd
```

### Option 2: Configure NTPD Server

#### Edit ntp.conf
```bash
# Backup original configuration
sudo cp /etc/ntp.conf /etc/ntp.conf.backup

# Edit configuration
sudo nano /etc/ntp.conf
```

#### Sample ntp.conf Configuration
```ini
# /etc/ntp.conf

# Specify servers to synchronize with
server 0.pool.ntp.org iburst
server 1.pool.ntp.org iburst
server 2.pool.ntp.org iburst
server 3.pool.ntp.org iburst

# Use public servers from the pool.ntp.org project
#server 0.rhel.pool.ntp.org iburst
#server 1.rhel.pool.ntp.org iburst
#server 2.rhel.pool.ntp.org iburst

# Broadcast to local network
broadcast 192.168.1.255

# Configure access control
restrict default nomodify notrap nopeer noquery
restrict 127.0.0.1
restrict ::1

# Allow clients on your local network
restrict 192.168.0.0 mask 255.255.0.0 nomodify notrap
restrict 10.0.0.0 mask 255.0.0.0 nomodify notrap

# Location of drift file
driftfile /var/lib/ntp/drift

# Enable logging
logfile /var/log/ntp.log

# Enable kernel mode PLL
disable kernel

# Stats directories
statsdir /var/log/ntp/

# Enable stats
stats loopstats peerstats clockstats
```

#### Restart ntpd
```bash
# Apply configuration changes
sudo systemctl restart ntpd

# Check status
sudo systemctl status ntpd
```

---

## Install NTP Client

### Option 1: Install Chrony Client

#### For RHEL/CentOS/Rocky Linux
```bash
# Install chrony
sudo dnf install -y chrony

# Enable and start chrony
sudo systemctl enable --now chronyd
```

#### For Ubuntu/Debian
```bash
# Install chrony
sudo apt install -y chrony

# Enable and start chrony
sudo systemctl enable --now chronyd
```

### Option 2: Install NTPD Client

#### For RHEL/CentOS/Rocky Linux
```bash
# Install ntp
sudo dnf install -y ntp

# Enable and start ntp
sudo systemctl enable --now ntpd
```

#### For Ubuntu/Debian
```bash
# Install ntp
sudo apt install -y ntp

# Stop systemd-timesyncd
sudo systemctl stop systemd-timesyncd
sudo systemctl disable systemd-timesyncd

# Enable and start ntp
sudo systemctl enable --now ntp
```

### Option 3: Use systemd-timesyncd (Basic Client)

#### Enable systemd-timesyncd
```bash
# Stop other NTP services
sudo systemctl stop chronyd ntpd
sudo systemctl disable chronyd ntpd

# Enable systemd-timesyncd
sudo timedatectl set-ntp true

# Check status
sudo systemctl status systemd-timesyncd
```

---

## Configure NTP Client

### Option 1: Configure Chrony Client

#### Edit chrony.conf for Client
```bash
# Edit chrony configuration
sudo nano /etc/chrony.conf
```

#### Client chrony.conf Configuration
```ini
# /etc/chrony.conf - Client Configuration

# Use your internal NTP server instead of public servers
# Comment out or remove public server entries
#server 0.pool.ntp.org iburst
#server 1.pool.ntp.org iburst

# Add your internal NTP server
server your-ntp-server.domain.com iburst
server 192.168.1.10 iburst

# Use driftfile to store frequency offset
driftfile /var/lib/chrony/drift

# Allow the system clock to be stepped in the first three updates
makestep 1.0 3

# Enable kernel synchronization of the real-time clock (RTC)
rtcsync

# Enable hardware timestamping on all interfaces that support it
hwtimestamp *

# Don't serve time to other clients (remove allow statements)
# allow 192.168.0.0/16

# Don't act as local time source
# local stratum 10

# Specify directory for log files
logdir /var/log/chrony

# Select which information is logged
log measurements statistics tracking
```

#### Restart client
```bash
# Apply configuration changes
sudo systemctl restart chronyd

# Check status
sudo systemctl status chronyd
```

### Option 2: Configure NTPD Client

#### Edit ntp.conf for Client
```bash
# Edit ntp configuration
sudo nano /etc/ntp.conf
```

#### Client ntp.conf Configuration
```ini
# /etc/ntp.conf - Client Configuration

# Use your internal NTP server
#server 0.pool.ntp.org iburst
server your-ntp-server.domain.com iburst
server 192.168.1.10 iburst

# Configure access control
restrict default nomodify notrap nopeer noquery
restrict 127.0.0.1
restrict ::1

# Don't serve time to clients (no broadcast, no multicast)
#broadcast 192.168.1.255

# Location of drift file
driftfile /var/lib/ntp/drift

# Enable logging
logfile /var/log/ntp.log
```

#### Restart client
```bash
# Apply configuration changes
sudo systemctl restart ntpd

# Check status
sudo systemctl status ntpd
```

### Option 3: Configure systemd-timesyncd

#### Edit timesyncd.conf
```bash
# Create or edit configuration
sudo nano /etc/systemd/timesyncd.conf
```

#### timesyncd.conf Configuration
```ini
# /etc/systemd/timesyncd.conf

[Time]
# NTP servers
NTP=your-ntp-server.domain.com 192.168.1.10

# Fallback NTP servers
FallbackNTP=0.pool.ntp.org 1.pool.ntp.org 2.pool.ntp.org

# Distance to root time server
RootDistanceMaxSec=5

# Poll interval minimum and maximum
PollIntervalMinSec=32
PollIntervalMaxSec=2048
```

#### Restart timesyncd
```bash
# Apply configuration changes
sudo systemctl restart systemd-timesyncd

# Check status
sudo systemctl status systemd-timesyncd
```

---

## Firewall Configuration

### Configure Firewall for NTP Server

#### For firewalld (RHEL/CentOS/Rocky)
```bash
# Allow NTP service
sudo firewall-cmd --permanent --add-service=ntp
sudo firewall-cmd --reload

# Or specify ports manually
sudo firewall-cmd --permanent --add-port=123/udp
sudo firewall-cmd --reload

# Check allowed services
sudo firewall-cmd --list-all
```

#### For UFW (Ubuntu/Debian)
```bash
# Allow NTP service
sudo ufw allow ntp

# Or specify port manually
sudo ufw allow 123/udp

# Check firewall status
sudo ufw status
```

#### For iptables
```bash
# Allow NTP traffic
sudo iptables -A INPUT -p udp --dport 123 -j ACCEPT
sudo iptables -A OUTPUT -p udp --sport 123 -j ACCEPT

# Save rules
sudo iptables-save > /etc/iptables/rules.v4
```

### Configure Firewall for NTP Client

#### Allow outgoing NTP traffic
```bash
# For firewalld
sudo firewall-cmd --permanent --add-port=123/udp
sudo firewall-cmd --reload

# For UFW
sudo ufw allow out 123/udp

# For iptables
sudo iptables -A OUTPUT -p udp --dport 123 -j ACCEPT
```

---

## Verify Synchronization

### For Chrony

#### Check Chrony Status
```bash
# Check time synchronization status
chronyc tracking

# View time sources
chronyc sources

# View source statistics
chronyc sourcestats

# Check detailed information
chronyc sources -v

# Manual time update
sudo chronyc -a makestep

# Check if time is synchronized
chronyc -a 'burst 4/4'
chronyc -a offline
chronyc -a online
```

#### Chrony Output Examples
```bash
# chronyc tracking output
Reference ID    : C0A8010A (192.168.1.10)
Stratum         : 3
Ref time (UTC)  : Tue Nov 21 14:30:45.123456 2024
System time     : 0.000002539 seconds fast of NTP time
Last offset     : +0.000003456 seconds
RMS offset      : 0.000002123 seconds
Frequency       : 1.234 ppm slow
Residual freq   : +0.001 ppm
Skew            : 0.123 ppm
Root delay      : 0.045678 seconds
Root dispersion : 0.012345 seconds
Update interval : 64.2 seconds
Leap status     : Normal
```

### For NTPD

#### Check NTPD Status
```bash
# Check NTP associations
ntpq -p

# Check detailed associations
ntpq -pn

# Check NTP status
ntpstat

# Check synchronization status
ntpq -c rv

# Check peer statistics
ntpq -c "readvar"
```

#### NTPD Output Examples
```bash
# ntpq -p output
     remote           refid      st t when poll reach   delay   offset  jitter
==============================================================================
*ntp1.example.co .POOL.          16 p    -   64    0    0.000    0.000   0.000
+ntp2.example.co .POOL.          16 p    -   64    0    0.000    0.000   0.000
```

### For systemd-timesyncd

#### Check timesyncd Status
```bash
# Check time synchronization status
timedatectl status

# Show detailed status
systemd-resolve --status

# Check logs
journalctl -u systemd-timesyncd -f
```

#### timedatectl Output Examples
```bash
# timedatectl status output
               Local time: Tue 2024-11-21 14:30:45 UTC
           Universal time: Tue 2024-11-21 14:30:45 UTC
                 RTC time: Tue 2024-11-21 14:30:45
                Time zone: UTC (UTC, +0000)
System clock synchronized: yes
              NTP service: active
          RTC in local TZ: no
```

### Manual Time Verification

#### Compare with Server Time
```bash
# Query remote NTP server
sntp your-ntp-server.domain.com

# Use ntpdate for testing
sudo ntpdate -q your-ntp-server.domain.com

# Use ntpdate for manual sync (temporary)
sudo ntpdate -s your-ntp-server.domain.com
```

---

## Advanced Configuration

### Configure Multiple Time Sources

#### Configure Multiple Servers
```ini
# chrony.conf with multiple sources
server 0.pool.ntp.org iburst maxsources 3
server 1.pool.ntp.org iburst maxsources 3
server 2.pool.ntp.org iburst maxsources 3
server your-internal-server-1 iburst
server your-internal-server-2 iburst

# Minimum sources for synchronization
minsources 2
```

#### Configure Authentication Keys
```bash
# Generate authentication key (chrony)
sudo chronyc << EOF
generatekey 1 MD5
EOF

# Configure key in chrony.conf
echo "keyfile /etc/chrony.keys" >> /etc/chrony.conf

# Create keys file
sudo nano /etc/chrony.keys
```

```ini
# /etc/chrony.keys
# Format: keyID type key
1 MD5 YourSecretKeyHere
```

### Configure GPS Time Source

#### Install GPS Time Server
```bash
# Install GPSd
sudo dnf install -y gpsd gpsd-clients

# For Ubuntu/Debian
sudo apt install -y gpsd gpsd-clients

# Configure GPSd
sudo nano /etc/gpsd.conf
```

```ini
# gpsd.conf
USBAUTO=true
DEVICES=""
GPSD_OPTIONS="-n"
```

#### Configure GPS with Chrony
```ini
# Add to chrony.conf
refclock SHM 0 offset 0.5 delay 0.2 refid GPS
```

### Configure Hardware Clock

#### Sync Hardware Clock
```bash
# Sync hardware clock to system time
sudo hwclock --systohc

# Sync system time from hardware clock
sudo hwclock --hctosys

# Check hardware clock time
sudo hwclock --show
```

---

## Troubleshooting

### Common Issues and Solutions

#### 1. Service Won't Start
```bash
# Check service status
sudo systemctl status chronyd
sudo systemctl status ntpd

# Check logs
sudo journalctl -u chronyd -f
sudo journalctl -u ntpd -f

# Check configuration syntax
chronyd -t
ntpd -g
```

#### 2. Time Not Synchronizing
```bash
# Check if firewall is blocking
sudo ss -ulnp | grep :123

# Test connectivity
nc -u your-ntp-server.domain.com 123

# Check network connectivity
ping your-ntp-server.domain.com

# Manually sync
sudo chronyc -a makestep
sudo ntpdate -s your-ntp-server.domain.com
```

#### 3. Time Drift Issues
```bash
# Check frequency
chronyc tracking

# Force resync
sudo chronyc -a burst 4/4

# Check system load
uptime
```

#### 4. Permission Issues
```bash
# Check file permissions
ls -la /etc/chrony.conf
ls -la /var/lib/chrony/

# Fix permissions
sudo chown chrony:chrony /var/lib/chrony/drift
sudo chmod 644 /etc/chrony.conf
```

#### 5. High Time Offset
```bash
# Check offset
chronyc tracking

# Force step if offset is large
sudo chronyc -a makestep 10 3

# Check system resources
free -h
df -h
```

### Debugging Commands

#### Chrony Debugging
```bash
# Detailed source information
chronyc sources -v

# Manual queries
chronyc activity
chronyc selectdata

# Check authentication
chronyc authdata

# Log levels
sudo nano /etc/chrony.conf
# Add: log rawmeasurements
```

#### NTPD Debugging
```bash
# Detailed associations
ntpq -c as

# Check configuration
ntpq -c sysinfo

# Peer variables
ntpq -c rv

# Check for authentication
ntpdc -c listpeers
```

---

## Security Considerations

### Access Control

#### Restrict NTP Access
```ini
# For chrony.conf
allow 192.168.0.0/16
allow 10.0.0.0/8
# Don't allow other networks (implicit deny)

# For ntp.conf
restrict default kod limited nomodify notrap nopeer noquery
restrict 127.0.0.1
restrict ::1
restrict 192.168.0.0 mask 255.255.0.0 nomodify notrap
```

#### Enable Authentication
```bash
# Generate symmetric keys
sudo chronyc << EOF
generatekey 1 MD5
EOF

# Configure key usage
echo "1" | sudo tee /etc/chrony/keys
echo "commandkey 1" >> /etc/chrony.conf
```

### Rate Limiting

#### Prevent Abuse
```ini
# chrony.conf rate limiting
ratelimit 10 3
ratelimit burst 16
local stratum 10
```

### Network Security

#### Use VPN for Remote Clients
```bash
# Ensure NTP traffic is encrypted
# Use WireGuard or OpenVPN for remote site connections
# Configure NTP server with VPN IP addresses
```

---

## Monitoring NTP

### Basic Monitoring Scripts

#### Create monitoring script
```bash
#!/bin/bash
# /usr/local/bin/ntp-monitor.sh

# Check NTP synchronization
check_ntp_sync() {
    if chronyc tracking | grep -q "System time.*fast\|System time.*slow"; then
        echo "WARNING: Time not synchronized"
        return 1
    else
        echo "OK: Time synchronized"
        return 0
    fi
}

# Check NTP service status
check_ntp_service() {
    if systemctl is-active --quiet chronyd; then
        echo "OK: Chrony service is running"
        return 0
    else
        echo "CRITICAL: Chrony service is not running"
        return 2
    fi
}

# Main monitoring
check_ntp_service
check_ntp_sync

# Get offset
OFFSET=$(chronyc tracking | grep "Last offset" | awk '{print $4}')
echo "Current offset: $OFFSET seconds"
```

#### Make executable and test
```bash
chmod +x /usr/local/bin/ntp-monitor.sh
sudo /usr/local/bin/ntp-monitor.sh
```

### Nagios/Icinga Monitoring

#### Create NTP check plugin
```bash
#!/bin/bash
# /usr/local/lib/nagios/check_ntp.sh

OK=0
WARNING=1
CRITICAL=2

# Get NTP status
if ! chronyc tracking > /dev/null 2>&1; then
    echo "CRITICAL: Cannot connect to chrony"
    exit $CRITICAL
fi

# Get offset
OFFSET=$(chronyc tracking | grep "Last offset" | awk '{print $4}')
STRATUM=$(chronyc tracking | grep "Stratum" | awk '{print $3}')

# Check stratum
if [ "$STRATUM" -gt 15 ]; then
    echo "CRITICAL: Stratum $STRATUM - no time source"
    exit $CRITICAL
fi

# Check offset (in seconds)
if [ $(echo "$OFFSET < -1.0" | bc -l) -eq 1 ] || [ $(echo "$OFFSET > 1.0" | bc -l) -eq 1 ]; then
    echo "CRITICAL: Time offset $OFFSET seconds"
    exit $CRITICAL
elif [ $(echo "$OFFSET < -0.1" | bc -l) -eq 1 ] || [ $(echo "$OFFSET > 0.1" | bc -l) -eq 1 ]; then
    echo "WARNING: Time offset $OFFSET seconds"
    exit $WARNING
else
    echo "OK: Time offset $OFFSET seconds, Stratum $STRATUM"
    exit $OK
fi
```

### Log Monitoring

#### Configure log rotation
```bash
# Create logrotate configuration
sudo nano /etc/logrotate.d/chrony
```

```
/var/log/chrony/*.log {
    daily
    missingok
    rotate 30
    compress
    delaycompress
    notifempty
    create 640 chrony chrony
    postrotate
        /usr/bin/killall -USR1 chronyd
    endscript
}
```

---

## Quick Reference Commands

### Server Commands
```bash
# Install and enable chrony server
sudo dnf install -y chrony
sudo systemctl enable --now chronyd

# Configure as server
sudo nano /etc/chrony.conf
# Add: allow 192.168.0.0/16

# Restart service
sudo systemctl restart chronyd

# Check status
sudo systemctl status chronyd
chronyc tracking
chronyc sources
```

### Client Commands
```bash
# Install chrony client
sudo dnf install -y chrony
sudo systemctl enable --now chronyd

# Configure to use server
sudo nano /etc/chrony.conf
# Add: server ntp-server.example.com iburst

# Restart service
sudo systemctl restart chronyd

# Verify synchronization
chronyc tracking
chronyc sources
```

### Firewall Commands
```bash
# Open NTP port (firewalld)
sudo firewall-cmd --permanent --add-service=ntp
sudo firewall-cmd --reload

# Open NTP port (UFW)
sudo ufw allow ntp

# Open NTP port (iptables)
sudo iptables -A INPUT -p udp --dport 123 -j ACCEPT
```

### Troubleshooting Commands
```bash
# Check service status
sudo systemctl status chronyd
sudo journalctl -u chronyd -f

# Test connectivity
nc -u ntp-server.example.com 123
ping ntp-server.example.com

# Manual sync
sudo chronyc -a makestep

# Check offset
chronyc tracking
```

---

## Best Practices

1. **Use local NTP servers** for better accuracy and reliability
2. **Configure at least 3 time sources** for redundancy
3. **Use authentication** for security in enterprise environments
4. **Monitor time synchronization** regularly
5. **Document configuration** changes
6. **Test failover** scenarios
7. **Keep NTP software updated**
8. **Use hardware clocks** where possible
9. **Configure logging** for troubleshooting
10. **Backup configurations** regularly

---

**🎉 Congratulations!** You now have a fully functional NTP server and client setup with comprehensive configuration, monitoring, and troubleshooting capabilities!