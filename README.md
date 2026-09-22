# ASL3 Dynamic Station Telemetry & Web Hub

An automated real-time hardware telemetry dashboard, digital dual clock, and station portal designed specifically for **AllStarLink 3 (ASL3)** nodes running on Debian 12 / 13 (Trixie) and Raspberry Pi hardware.

Designed and developed by **Ronik Halder (Amateur Radio Station S21SRK)**.

---

## Features

- **Live Hardware Telemetry**: Real-time scrolling graphs for CPU Temperature (°C) and 1-minute CPU Load Average via Chart.js.
- **System Metrics**: Live RAM utilization, root storage consumption, system uptime, and Asterisk daemon health.
- **Dual Synchronized Digital Clocks**: Displays UTC/GMT alongside local station time (configurable to any IANA timezone, e.g., Asia/Dhaka, America/New_York).
- **Non-Destructive Integration**: Hosts all assets outside of the default `/var/www/html/` directory (inside `/opt/`) using Apache Aliases and lightweight CGI, ensuring core ASL3 files and updates remain unaffected.
- **Dynamic Station Profiling**: Automatically detects LAN and WAN IP addresses and prompts for the operator's callsign, node number, QRZ links, and custom port configuration.

---

## One-Line Automated Installation

Log into your Raspberry Pi terminal via SSH and run:

```bash
curl -sSL [https://raw.githubusercontent.com/s21srk/asl3-telemetry-hub/main/install.sh](https://raw.githubusercontent.com/s21srk/asl3-telemetry-hub/main/install.sh) | bash
```

*(Replace `s21srk/asl3-telemetry-hub` with your GitHub username and repository name).*

### Interactive Prompts During Installation:
The installer will prompt for:
1. **Callsign** (e.g., `S21SRK`)
2. **Operator Name** (e.g., `Ronik Halder`)
3. **AllStar Node Number** (e.g., `62208`)
4. **External HTTPS Port** (default `8443` for router port forwarding)
5. **Local Timezone** (e.g., `Asia/Dhaka`, `America/Chicago`)
6. **Timezone Display Label** (e.g., `BST (UTC+6)`)

---

## Web Access Endpoints

Once installed, the services are accessible at:

| Destination | Local Network (LAN) | Remote Network (WAN) |
|---|---|---|
| **Live Telemetry Dashboard** | `https://<PI-IP>/iot/` | `https://<WAN-IP>:8443/iot/` |
| **Station Control Portal** | `https://<PI-IP>/hub/` | `https://<WAN-IP>:8443/hub/` |
| **AllMon3 Monitor** | `https://<PI-IP>/allmon3/` | `https://<WAN-IP>:8443/allmon3/` |
| **AllScan Scanner** | `https://<PI-IP>/allscan/` | `https://<WAN-IP>:8443/allscan/` |

---

## Directory Architecture

```text
/opt/
├── hub/
│   └── index.html          # Clean card-based launcher for all services
└── iot/
    ├── index.html          # High-refresh responsive telemetry dashboard
    └── stats.py            # Lightweight, zero-overhead Bash CGI JSON engine
```

---

## Credits & License

- **Developer**: Ronik Halder ([S21SRK](https://www.qrz.com/db/S21SRK))
- **Platform**: Designed for [AllStarLink](https://allstarlink.org/)
- **License**: MIT License. Free to use, adapt, and distribute for the amateur radio community.
