#!/usr/bin/env python3
"""
flash_esp32c5.py - ESP32-C5 Flashing & Diagnostic Tool for pi-3d-printer-link
Supports Windows, Linux (Raspberry Pi), and macOS.
"""

import sys
import os
import argparse
import subprocess
import serial.tools.list_ports

def list_available_ports():
    ports = list(serial.tools.list_ports.comports())
    return [p.device for p in ports]

def find_esp_ports():
    candidates = []
    for port in serial.tools.list_ports.comports():
        desc = (port.description or "").lower()
        hwid = (port.hwid or "").lower()
        if any(keyword in desc or keyword in hwid for keyword in ["espressif", "ch340", "cp210", "usb jtag", "xiao", "seeed"]):
            candidates.append(port.device)
    return candidates

def check_chip(port, baud=460800):
    print(f"[*] Probing ESP32 on port {port} (baud {baud})...")
    cmd = [sys.executable, "-m", "esptool", "--port", port, "--baud", str(baud), "chip_id"]
    try:
        res = subprocess.run(cmd, capture_output=True, text=True, timeout=15)
        print(res.stdout)
        if res.returncode != 0:
            print(res.stderr, file=sys.stderr)
            return False
        return True
    except subprocess.TimeoutExpired:
        print(f"[!] Timeout connecting to {port}. Make sure device is plugged in and not busy.", file=sys.stderr)
        return False
    except Exception as e:
        print(f"[!] Error: {e}", file=sys.stderr)
        return False

def flash_firmware(port, bin_path, offset="0x0", baud=460800):
    if not os.path.isfile(bin_path):
        print(f"[!] Firmware binary not found: {bin_path}", file=sys.stderr)
        return False
    print(f"[*] Flashing {bin_path} to {port} at offset {offset}...")
    cmd = [
        sys.executable, "-m", "esptool",
        "--chip", "esp32c5",
        "--port", port,
        "--baud", str(baud),
        "write_flash",
        "--flash_mode", "dio",
        "--flash_size", "detect",
        offset, bin_path
    ]
    res = subprocess.run(cmd)
    return res.returncode == 0

def main():
    parser = argparse.ArgumentParser(description="ESP32-C5 flasher and diagnostic tool for pi-3d-printer-link")
    parser.add_argument("--port", "-p", help="Serial port (e.g., COM11, /dev/ttyACM0)", default=None)
    parser.add_argument("--baud", "-b", type=int, default=460800, help="Baud rate (default: 460800)")
    parser.add_argument("--probe", action="store_true", help="Probe chip details only")
    parser.add_argument("--flash", help="Path to firmware binary to flash")
    parser.add_argument("--offset", default="0x0", help="Flash offset (default: 0x0)")

    args = parser.parse_args()

    target_port = args.port
    if not target_port:
        candidates = find_esp_ports()
        all_ports = list_available_ports()
        if "COM11" in all_ports:
            target_port = "COM11"
        elif candidates:
            target_port = candidates[0]
        elif all_ports:
            target_port = all_ports[0]
        else:
            print("[!] No serial ports detected! Please check your USB connection.", file=sys.stderr)
            sys.exit(1)

    print(f"[*] Selected port: {target_port}")

    if args.flash:
        success = flash_firmware(target_port, args.flash, args.offset, args.baud)
        sys.exit(0 if success else 1)
    else:
        success = check_chip(target_port, args.baud)
        sys.exit(0 if success else 1)

if __name__ == "__main__":
    main()
