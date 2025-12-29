#!/bin/bash
# Title: Full Bluetooth Scan
# Author: Hackazillarex
# Description: One-shot full scan of Classic and BLE devices on Pineapple Pager
# Version: 1.1

# === CONFIG ===
LOOT_DIR="/root/loot/bluetooth"
SCAN_DURATION=90       # 1.5 minutes
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

    TMP_BLE="/tmp/bt_ble_scan.log"
    >"$TMP_BLE"  # empty file

    # Start BLE scan in background
    bluetoothctl scan on >/dev/null 2>&1 &
    SCAN_PID=$!

    START=$(date +%s)
    while (( $(date +%s) - START < SCAN_DURATION )); do
        bluetoothctl devices 2>/dev/null | awk '{print "Device "$2" "$3}' >> "$TMP_BLE"
        sleep 5
    done

    # Stop scanning
    bluetoothctl scan off >/dev/null 2>&1
    kill $SCAN_PID >/dev/null 2>&1

    # Output unique devices
    if [[ -s "$TMP_BLE" ]]; then
        awk '!seen[$0]++' "$TMP_BLE"
    else
        echo "No BLE devices found."
    fi
    rm -f "$TMP_BLE"

} > "$OUT"

# Cleanup empty logs
if ! grep -q "Device" "$OUT"; then
    rm -f "$OUT"
    echo "[-] No devices found. Log removed."
else
    echo "[+] Scan complete. Results saved to $OUT"
fi
