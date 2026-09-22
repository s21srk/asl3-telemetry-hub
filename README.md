# ASL3 Dynamic Station Telemetry & Web Hub

An automated real-time hardware telemetry dashboard, digital dual clock, and station portal designed specifically for **AllStarLink 3 (ASL3)** nodes running on Debian 12 / 13 (Trixie) and Raspberry Pi hardware.

Designed and developed by **Ronik Halder ([S21SRK](https://www.qrz.com/db/S21SRK))**.

---

## Direct Terminal Quick Install (Root / Sudo)

Log in to your Raspberry Pi via SSH, switch to root (or use standard sudo privileges), and paste either of the following commands directly into the terminal:

## Direct Terminal Quick Install (Root / Sudo)

Log in to your Raspberry Pi via SSH and run either of the following commands:

### Option 1: Standard One-Line Curl Install
```bash
curl -sSL https://raw.githubusercontent.com/s21srk/asl3-telemetry-hub/main/install.sh | bash
```

### Option 2: Process Substitution (Recommended for Root Shells)
```bash
bash <(curl -sSL https://raw.githubusercontent.com/s21srk/asl3-telemetry-hub/main/install.sh)
```

### Option 3: Manual Download & Execute
```bash
curl -sSL -o install.sh https://raw.githubusercontent.com/s21srk/asl3-telemetry-hub/main/install.sh
chmod +x install.sh
./install.sh
```

## Interactive Installation Prompts

During execution, the installer directly connects to the terminal keyboard (`/dev/tty`) and prompts for station information:

1. **Amateur Radio Callsign** (e.g., `S21SRK`)
2. **Operator Name / Handle** (e.g., `Ronik Halder`)
3. **AllStar Node Number** (e.g., `62208`)
4. **External HTTPS Port** (default: `8443`)
5. **Local Timezone** (e.g., `Asia/Dhaka`, `America/New_York`, `UTC`)
6. **Timezone Display Label** (e.g., `BST (UTC+6)`)

The script automatically detects the local LAN IP and external WAN IP to construct the dashboard endpoints.

---

## Key Features

- **Real-Time Dynamic Graphs**: Continuously plotting CPU temperature (°C) and 1-minute load averages via Chart.js.
- **Hardware Telemetry**: Monitored RAM usage, root storage (`/`), uptime counter, and live Asterisk systemd service status.
- **Synchronized Dual Digital Clocks**: Displays UTC/GMT alongside station local time.
- **Isolated Deployment**: Installs to `/opt/hub/` and `/opt/iot/` using Apache Aliases and lightweight CGI, protecting core ASL3 system files from corruption or overwrites during package updates.

---

## Accessing Station Portals

After installation completes, navigate to the generated URLs:

| Service | Local LAN Access | Remote WAN Access |
|---|---|---|
| **Live Telemetry Dashboard** | `https://<PI-IP>/iot/` | `https://<WAN-IP>:<PORT>/iot/` |
| **Station Control Hub** | `https://<PI-IP>/hub/` | `https://<WAN-IP>:<PORT>/hub/` |
| **AllMon3 Monitor** | `https://<PI-IP>/allmon3/` | `https://<WAN-IP>:<PORT>/allmon3/` |
| **AllScan Scanner** | `https://<PI-IP>/allscan/` | `https://<WAN-IP>:<PORT>/allscan/` |

---

## Directory Architecture

```text
/opt/
├── hub/
│   └── index.html          # Station navigation hub
└── iot/
    ├── index.html          # High-refresh responsive telemetry dashboard
    └── stats.py            # Zero-overhead Bash CGI JSON telemetry engine
```

---

## Credits & License

- **Developer**: Ronik Halder ([S21SRK](https://www.qrz.com/db/S21SRK))
- **Target Platform**: [AllStarLink 3 (ASL3)](https://allstarlink.org/)
- **License**: MIT License. Open source and free for the amateur radio community.
