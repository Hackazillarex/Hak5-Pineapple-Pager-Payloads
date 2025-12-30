#!/bin/bash
# Title: Ethernet Mod Nmap Recon Payload
# Author: Hackazillarex
# Description: Gateway + 10 Host Fast Port Recon
# Version: 1.0

ETH_IF="eth1"
LOOT_DIR="/root/loot/ethernet_nmap"
TIMESTAMP=$(date +%F_%H%M%S)
LOOT_FILE="$LOOT_DIR/ethernet_nmap_$TIMESTAMP.txt"
LOG_VIEWER="/root/payloads/user/general/log_viewer/payload.sh"

LOG blue "Starting Ethernet NMAP Scan!"
LOG green "------------------------------"

# Bring up Ethernet interface and get DHCP
ip link set $ETH_IF up
udhcpc -i $ETH_IF -q || { LED FAIL; exit 1; }

# Get gateway IP
GATEWAY=$(ip route show dev $ETH_IF | awk '/default/ {print $3}')
[ -z "$GATEWAY" ] && { LED FAIL; exit 1; }

# Get subnet
NET=$(ip -4 route show dev $ETH_IF | awk '/scope link/ {print $1}')
[ -z "$NET" ] && { LED FAIL; exit 1; }

mkdir -p "$LOOT_DIR"

LOG blue "Resolving public IP"
LOG green "------------------------------"

# Public IP via DNS (fast, no HTTPS)
PUBLIC_IP=$(nslookup myip.opendns.com resolver1.opendns.com 2>/dev/null \
            | awk '/Address: / {print $2}' | tail -n1)
[ -z "$PUBLIC_IP" ] && PUBLIC_IP="unavailable"

# Write header
cat <<EOF > "$LOOT_FILE"
Ethernet Limited Recon Scan
===========================
Timestamp : $(date)
Interface : $ETH_IF
Gateway   : $GATEWAY
Subnet    : $NET
Public IP : $PUBLIC_IP
Hostname  : $(hostname)

--- Live Host Discovery (Gateway + 10 Hosts) ---
EOF

LOG blue "Discovering live hosts"
LOG green "------------------------------"

# Discover hosts, keep gateway + first 10 live IPs
HOSTS=$(nmap -sn -PR -n -e $ETH_IF "$NET" \
        | awk '/Nmap scan report for/ {print $NF}' \
        | grep -v "$GATEWAY" \
        | head -n 10)

TARGETS="$GATEWAY $HOSTS"

echo "$TARGETS" | tr ' ' '\n' >> "$LOOT_FILE"

cat <<EOF >> "$LOOT_FILE"

--- Fast Open Port Scan (Top Ports Only) ---
EOF

LOG blue "Scanning selected hosts for open ports"
LOG green "------------------------------"

# Fast open-port scan on selected hosts only
nmap -n -Pn -F --open $TARGETS \
     -oN "$LOOT_FILE" --append-output

LOG blue "Scan finished & Log Viewer is starting"

# Launch Log Viewer
if [ -f "$LOG_VIEWER" ]; then
    source "$LOG_VIEWER"
else
    LOG red "Log Viewer not found at $LOG_VIEWER"
fi

exit 0
