#!/bin/bash
# Title: Full Bluetooth Scan
# Author: Hackazillarex
# Description: One-shot full scan of Classic and BLE devices on Pineapple Pager
# Version: 1.0

# === CONFIG ===
LOOT_DIR="/root/loot/bluetooth"
SCAN_DURATION=150       # 2.5 minutes
DATE_FMT="+%Y-%m-%d_%H-%M-%S"
HOSTNAME="$(hostname)"

mkdir -p "$LOOT_DIR"

# Sanity checks
for cmd in hciconfig hcitool bluetoothctl; do
    command -v "$cmd" >/dev/null 2>&1 || { echo "[-] $cmd not found"; exit 1; }
done
hciconfig | grep -q hci0 || { echo "[-] No hci0 device found"; exit 1; }

echo "[+] Bluetooth Scan starting on $HOSTNAME"

TS="$(date "$DATE_FMT")"
OUT="$LOOT_DIR/bt_scan_$TS.txt"

{
    echo "=== Bluetooth Pager Full Scan ==="
    echo "Host: $HOSTNAME"
    echo "Date: $(date)"
    echo

    # --- Classic Bluetooth ---
    echo "--- Classic Bluetooth Devices ---"
    CLASSIC=$(hcitool scan 2>/dev/null | tail -n +2)
    if [[ -z "$CLASSIC" ]]; then
        echo "No Classic Bluetooth devices found."
    else
        echo "$CLASSIC"
    fi

    echo
    # --- BLE Devices ---
    echo "--- BLE Devices ---"
    echo "Scanning for $SCAN_DURATION seconds..."
    
    # Start BLE scan in background
    bluetoothctl scan on >/tmp/bt_ble_scan.log 2>/dev/null &
    SCAN_PID=$!

    # Wait for the scan duration
    sleep "$SCAN_DURATION"

    # Stop scanning
    bluetoothctl scan off >/dev/null 2>&1
    kill $SCAN_PID >/dev/null 2>&1

    # Output unique devices
    if [[ -s /tmp/bt_ble_scan.log ]]; then
        grep -E "Device|NEW" /tmp/bt_ble_scan.log | awk '!seen[$0]++'
    else
        echo "No BLE devices found."
    fi
    rm -f /tmp/bt_ble_scan.log

} > "$OUT"

# Cleanup empty logs
if ! grep -q "Device" "$OUT"; then
    rm -f "$OUT"
    echo "[-] No devices found. Log removed."
else
    echo "[+] Scan complete. Results saved to $OUT"
fi
