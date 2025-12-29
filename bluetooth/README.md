# Hak5-Pineapple-Pager-Payloads

Full Bluetooth Scan

Author: Hackazillarex

Created: 12-26-25

Description

Performs a one-shot scan for Classic Bluetooth and Bluetooth Low Energy (BLE) devices using the Pineapple Pager.
Results are automatically saved to a timestamped loot file. At the end of the script, it calls the log viewer payload. (You must have the log viewer payload from Hak5 in your pager for that part to work).

Loot

Scan results are stored in:
/root/loot/bluetooth/

Files are named:
bt_scan_YYYY-MM-DD_HH-MM-SS.txt

If no devices are found, no loot file is kept.

------


