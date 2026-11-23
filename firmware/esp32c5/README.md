# ESP32-C5 Firmware & USB Flashing Guide

This directory contains flashing utilities and documentation for turning the **Seeed Studio XIAO ESP32-C5** into a high-speed Wi-Fi adapter or dedicated Access Point for the Raspberry Pi.

---

## 1. Hardware Overview

- **Board**: Seeed Studio XIAO ESP32-C5
- **Chip**: ESP32-C5HR8 (v1.0)
- **Features**: Dual-band Wi-Fi 6 (2.4 GHz & 5 GHz), Bluetooth 5 LE, 8MB PSRAM, USB 2.0 Serial/JTAG.
- **Connection**: Direct USB-C to any USB port on Raspberry Pi 5.

---

## 2. Using `flash_esp32c5.py`

A cross-platform Python tool is provided to probe and flash the ESP32-C5 directly from Windows, Linux, or macOS.

### Requirements

```bash
pip install esptool pyserial
```

### Probing the Connected ESP32-C5

To verify the board is recognized and healthy:

**On Windows (e.g. COM11):**
```powershell
python firmware/esp32c5/flash_esp32c5.py --port COM11 --probe
```

**On Raspberry Pi (Linux):**
```bash
python3 firmware/esp32c5/flash_esp32c5.py --port /dev/ttyACM0 --probe
```

*Example Output:*
```text
[*] Selected port: COM11
[*] Probing ESP32 on port COM11 (baud 460800)...
Connected to ESP32-C5 on COM11:
Chip type:          ESP32-C5HR8 (revision v1.0)
Features:           Wi-Fi 6 (dual-band), BT 5 (LE), Single Core + LP Core, 240MHz
MAC:                38:44:be:ff:fe:a3:f8:7c
```

---

## 3. Flashing ESP-Hosted Firmware

[ESP-Hosted-NG](https://github.com/espressif/esp-hosted) enables the ESP32-C5 to communicate with the Raspberry Pi as a standard Linux network interface (`wlan1` or `esp0`) over USB.

### Flashing a Compiled Binary:

```bash
python firmware/esp32c5/flash_esp32c5.py --port COM11 --flash path/to/esp_hosted_esp32c5.bin
```

Alternatively, from the Raspberry Pi running `pi-link`:
```bash
sudo pi-link flash-esp
```
