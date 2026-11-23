# pi-3d-printer-link

> A flexible, high-speed bridge linking a **Bambu Lab P1S** 3D printer to a **Raspberry Pi 5** (or any Pi SBC) over campus enterprise Wi-Fi (**UCSD-PROTECTED**) using **Tailscale** and LAN-only mode.

---

## The Problem

1. **2.4 GHz Only**: The Bambu Lab P1S only supports 2.4 GHz Wi-Fi and standard WPA2-PSK; it cannot connect to 5 GHz-only or 802.1X Enterprise networks (like `UCSD-PROTECTED`).
2. **Client Isolation**: Campus Wi-Fi blocks inter-client communication (AP isolation), preventing laptops from sending prints or streaming camera feeds directly to local devices.
3. **Guest Wi-Fi Limitations**: Guest networks are throttled, unstable, and require periodic captive-portal logins.

---

## The Solution: Architecture

```
                 [UCSD-PROTECTED] (5GHz WPA-Enterprise 802.1X)
                         │
                         ▼
        ┌────────────────────────────────────────────────────────┐
        │             Raspberry Pi 5 (Raspberry Pi OS)           │
        │                                                        │
        │  [wlan0] Onboard Wi-Fi (Client to UCSD-PROTECTED)      │
        │                                                        │
        │  [Tailscale Daemon]                                    │
        │     - Subnet Router advertising 192.168.4.0/24         │
        │     - IP Forwarding enabled (sysctl + NAT)             │
        │                                                        │
        │  [USB] Seeed Studio XIAO ESP32-C5 (or USB Wi-Fi)       │
        │     - 2.4GHz Wi-Fi Access Point (SSID: Bambu-Pi-Link)  │
        │     - DHCP Gateway: 192.168.4.1                        │
        └────────────────────────┬───────────────────────────────┘
                                 │ 2.4GHz WPA2-PSK
                                 ▼
                     ┌───────────────────────┐
                     │ Bambu Lab P1S Printer │
                     │ IP: 192.168.4.10      │
                     │ LAN-Only Mode         │
                     │ Ports: 8883, 990, 6000│
                     └───────────────────────┘
                                 ▲
                                 │ Tailscale WireGuard Tunnel
                                 │ (Virtual L3 Subnet Routing)
                                 ▼
                     ┌───────────────────────┐
                     │ User Laptop           │
                     │ (Any network/campus)  │
                     │ Tailscale Client      │
                     │ Bambu Studio (LAN)    │
                     └───────────────────────┘
```

---

## Quick Start on Raspberry Pi

### 1. Clone & Install

Log into your Raspberry Pi (via SSH, monitor, or USB tether):

```bash
git clone https://github.com/bjsek/pi-3d-printer-link.git
cd pi-3d-printer-link
sudo ./install.sh
```

### 2. Run Guided Setup

```bash
sudo pi-link setup
```

The setup wizard will:
1. Detect available interfaces (e.g. onboard `wlan0` and USB `wlan1`).
2. Prompt for your **UCSD-PROTECTED** credentials (Active Directory username & password) and connect `wlan0`.
3. Create a dedicated 2.4 GHz Access Point (`Bambu-Pi-Link`, password `bambulab123`) on `wlan1`.
4. Enable kernel IPv4 packet forwarding and NAT masquerade.
5. Install and launch **Tailscale**, advertising the printer subnet (`192.168.4.0/24`).

### 3. Approve Subnet Route in Tailscale

1. Visit [login.tailscale.com/admin/machines](https://login.tailscale.com/admin/machines).
2. Locate your Raspberry Pi in the machine list.
3. Click the **...** menu -> **Edit route settings...**.
4. Check and approve **`192.168.4.0/24`**.

---

## Bambu Lab P1S Configuration

1. On the P1S screen, go to **Settings** -> **WLAN**.
2. Connect to the Pi's Wi-Fi network:
   - **SSID**: `Bambu-Pi-Link`
   - **Password**: `bambulab123` (or your chosen password).
3. Switch to **LAN Only Mode**:
   - Navigate to **Settings** -> **LAN Only Mode**.
   - Enable LAN Only Mode.
   - Note down the **IP Address** (e.g. `192.168.4.10`) and the **Access Code** (8-digit PIN).

---

## Bambu Studio Setup (on your Laptop)

1. Make sure **Tailscale** is running and connected on your laptop.
2. Open **Bambu Studio**.
3. Under the **Device** tab:
   - Click the **+** (Add Device) icon or manually connect via IP.
   - Enter the printer's IP address: `192.168.4.10`
   - Enter the 8-digit **Access Code**.
4. You can now send print jobs (FTPS port 990), monitor telemetry and send G-code commands (MQTT port 8883), and view the live chamber camera (port 6000) directly over your encrypted Tailscale link!

---

## Command Reference

| Command | Description |
| :--- | :--- |
| `sudo pi-link setup` | Interactive wizard to configure network, hotspot, and Tailscale |
| `sudo pi-link status` | Live status dashboard (Uplink, Hotspot, Tailscale, P1S ports) |
| `sudo pi-link test-printer` | Probe P1S ports (8883 MQTT, 990 FTPS, 6000 Camera) |
| `sudo pi-link flash-esp` | Flash / probe Seeed Studio XIAO ESP32-C5 over USB |
| `sudo pi-link uninstall` | Teardown and delete `pi-link` network profiles and firewall rules |

---

## Hardware Flexibility

`pi-link` is designed to be hardware-agnostic across Pi SBCs:
- **Raspberry Pi 5 / 4 / 3B+ / Zero 2W**
- **Uplink Options**: Built-in Wi-Fi, Ethernet port, or USB Wi-Fi.
- **Printer AP Options**: Seeed Studio XIAO ESP32-C5 (via ESP-Hosted), any standard Linux-compatible USB Wi-Fi dongle (Realtek, MediaTek, Atheros), or onboard Wi-Fi when using wired Ethernet for uplink.

---

## License

MIT
