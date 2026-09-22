#!/bin/bash
# ==============================================================================
# ASL3 Dynamic Station Telemetry & Web Hub Installer
# Developed by: Ronik Halder (S21SRK)
# Compatibility: Debian 12 / 13 (Trixie) & Raspberry Pi (ASL3)
# ==============================================================================

set -e

echo "===================================================================="
echo "    AllStarLink 3 Station Telemetry & Web Hub Installer            "
echo "    Developed by Ronik Halder (S21SRK)                              "
echo "===================================================================="
echo ""

# 1. User Interactive Prompts (Read directly from /dev/tty)
read -p "Enter Amateur Radio Callsign [e.g. S21SRK]: " CALLSIGN </dev/tty
CALLSIGN=${CALLSIGN^^}
CALLSIGN=${CALLSIGN:-S21SRK}

read -p "Enter Operator Name/Handle [e.g. Ronik Halder]: " OPERATOR_NAME </dev/tty
OPERATOR_NAME=${OPERATOR_NAME:-Ronik Halder}

read -p "Enter AllStar Node Number [e.g. 62208]: " NODE_NUM </dev/tty
NODE_NUM=${NODE_NUM:-62208}

read -p "Enter External HTTPS Port [default: 8443]: " WAN_PORT </dev/tty
WAN_PORT=${WAN_PORT:-8443}

read -p "Enter Local Timezone [default: Asia/Dhaka]: " LOCAL_TZ </dev/tty
LOCAL_TZ=${LOCAL_TZ:-Asia/Dhaka}

read -p "Enter Local Timezone Display Label [default: BST (UTC+6)]: " TZ_LABEL </dev/tty
TZ_LABEL=${TZ_LABEL:-BST (UTC+6)}

echo ""
echo "[*] Detecting Network Interfaces..."
DETECTED_LAN_IP=$(hostname -I | awk '{print $1}')
DETECTED_WAN_IP=$(curl -s -4 https://ifconfig.me || curl -s -4 https://api.ipify.org || echo "YOUR-PUBLIC-IP")

echo "    -> Local LAN IP: $DETECTED_LAN_IP"
echo "    -> Public WAN IP: $DETECTED_WAN_IP"
echo ""

# 2. File System Setup
echo "[1/5] Setting up /opt/ directories..."
sudo mkdir -p /opt/hub /opt/iot
sudo chown -R www-data:www-data /opt/hub /opt/iot
sudo chmod 755 /opt/hub /opt/iot

# 3. Apache Configuration
echo "[2/5] Configuring Apache2 and CGI modules..."
sudo a2enmod cgid cgi

sudo tee /etc/apache2/conf-available/custom-dirs.conf > /dev/null << 'EOF'
Alias /hub /opt/hub
<Directory "/opt/hub">
    Options Indexes FollowSymLinks
    AllowOverride None
    Require all granted
</Directory>

Alias /iot /opt/iot
<Directory "/opt/iot">
    Options Indexes FollowSymLinks ExecCGI
    AddHandler cgi-script .py
    AllowOverride None
    Require all granted
</Directory>
EOF

sudo a2enconf custom-dirs
sudo apache2ctl configtest
sudo systemctl restart apache2

# 4. Telemetry Backend Script
echo "[3/5] Installing live telemetry backend (/opt/iot/stats.py)..."
sudo tee /opt/iot/stats.py > /dev/null << 'EOF'
#!/bin/bash
echo "Content-Type: application/json"
echo ""

# Thermal Zone
if [ -f /sys/class/thermal/thermal_zone0/temp ]; then
    raw_temp=$(cat /sys/class/thermal/thermal_zone0/temp)
    temp_num=$(awk -v t="$raw_temp" 'BEGIN { printf "%.1f", t / 1000 }')
else
    temp_num="0"
fi

# CPU Load Averages
read load1 load5 load15 rest < /proc/loadavg

# RAM Calculations
total_ram=$(awk '/MemTotal/ {print int($2/1024)}' /proc/meminfo)
avail_ram=$(awk '/MemAvailable/ {print int($2/1024)}' /proc/meminfo)
used_ram=$((total_ram - avail_ram))
ram_pct=$((used_ram * 100 / total_ram))

# Storage Usage
disk_info=$(df -h / | awk 'NR==2 {print $3, $2, $5}')
disk_used=$(echo "$disk_info" | awk '{print $1}')
disk_total=$(echo "$disk_info" | awk '{print $2}')
disk_pct=$(echo "$disk_info" | awk '{print $3}')

# Uptime
up_sec=$(awk '{print int($1)}' /proc/uptime)
hours=$((up_sec / 3600))
mins=$(((up_sec % 3600) / 60))
uptime_str="${hours}h${mins}m"

# Asterisk Process
if systemctl is-active --quiet asterisk; then
    ast_status="ONLINE"
else
    ast_status="OFFLINE"
fi

cat << JSON
{
  "temp": $temp_num,
  "load1": $load1,
  "load5": $load5,
  "load15": $load15,
  "ram_used": $used_ram,
  "ram_total": $total_ram,
  "ram_pct": $ram_pct,
  "disk_used": "$disk_used",
  "disk_total": "$disk_total",
  "disk_pct": "$disk_pct",
  "uptime": "$uptime_str",
  "asl_status": "$ast_status"
}
JSON
EOF

sudo chmod 755 /opt/iot/stats.py
sudo chown www-data:www-data /opt/iot/stats.py

# 5. Station Portal Hub HTML
echo "[4/5] Building portal landing page (/opt/hub/index.html)..."
sudo tee /opt/hub/index.html > /dev/null << EOF
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>${CALLSIGN} // Node Control Hub</title>
    <style>
        * { box-sizing: border-box; margin: 0; padding: 0; }
        body { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif; background: #080b11; color: #e6edf3; display: flex; justify-content: center; align-items: center; min-height: 100vh; padding: 20px; }
        .card-panel { background: #101522; border: 1px solid #1f2c47; border-radius: 14px; max-width: 580px; width: 100%; padding: 30px; box-shadow: 0 8px 30px rgba(0,0,0,0.5); }
        h1 { font-size: 1.6rem; color: #ffffff; text-align: center; margin-bottom: 6px; }
        p.sub { text-align: center; color: #8b9bb4; font-size: 0.95rem; margin-bottom: 24px; }
        .grid { display: grid; grid-template-columns: 1fr 1fr; gap: 14px; }
        .btn { display: flex; flex-direction: column; align-items: center; justify-content: center; background: #161e31; border: 1px solid #1f2c47; border-radius: 10px; padding: 18px 12px; text-decoration: none; color: #fff; transition: 0.2s ease-in-out; }
        .btn:hover { border-color: #00e5ff; background: #1c2740; transform: translateY(-2px); }
        .btn-title { font-weight: bold; font-size: 1.05rem; color: #00e5ff; margin-bottom: 4px; }
        .btn-desc { font-size: 0.8rem; color: #8b9bb4; }
    </style>
</head>
<body>
    <div class="card-panel">
        <h1>${CALLSIGN} // Node${NODE_NUM}</h1>
        <p class="sub">Station Operator: ${OPERATOR_NAME}</p>
        <div class="grid">
            <a href="/allmon3/" class="btn">
                <span class="btn-title">AllMon3</span>
                <span class="btn-desc">Radio Node Monitor</span>
            </a>
            <a href="/allscan/" class="btn">
                <span class="btn-title">AllScan</span>
                <span class="btn-desc">Node Scanner</span>
            </a>
            <a href="/iot/" class="btn">
                <span class="btn-title">IoT Telemetry</span>
                <span class="btn-desc">Real-Time Metrics</span>
            </a>
            <a href="https://${DETECTED_LAN_IP}:9090/" class="btn" target="_blank">
                <span class="btn-title">Cockpit Admin</span>
                <span class="btn-desc">Pi System Admin (LAN)</span>
            </a>
        </div>
    </div>
</body>
</html>
EOF

sudo chmod 644 /opt/hub/index.html
sudo chown www-data:www-data /opt/hub/index.html

# 6. Station Live Telemetry Page
echo "[5/5] Building live IoT dashboard (/opt/iot/index.html)..."
sudo tee /opt/iot/index.html > /dev/null << EOF
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>${CALLSIGN} // Node${NODE_NUM} Telemetry Hub</title>
    <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
    <style>
        :root {
            --bg-base: #0a0d14;
            --bg-surface: #121722;
            --bg-card: #182030;
            --border-line: #222e47;
            --accent-green: #00ff88;
            --accent-cyan: #00e5ff;
            --accent-gold: #ffb703;
            --accent-red: #ff3366;
            --text-primary: #e6edf3;
            --text-secondary: #8b9bb4;
        }
        * { box-sizing: border-box; margin: 0; padding: 0; }
        body { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, monospace; background: var(--bg-base); color: var(--text-primary); padding: 18px; line-height: 1.5; }
        .container { max-width: 950px; margin: 0 auto; }

        header { display: flex; justify-content: space-between; align-items: center; border-bottom: 2px solid var(--border-line); padding-bottom: 14px; margin-bottom: 16px; flex-wrap: wrap; gap: 10px; }
        .brand { display: flex; align-items: center; gap: 12px; }
        .badge { background: linear-gradient(135deg, #0052cc, #00e5ff); color: #fff; font-weight: 800; font-size: 1.15rem; padding: 5px 12px; border-radius: 6px; letter-spacing: 1.5px; box-shadow: 0 0 12px rgba(0,229,255,0.3); }
        .station-desc { font-size: 0.85rem; color: var(--text-secondary); text-transform: uppercase; letter-spacing: 1px; }
        .header-links a { color: var(--accent-cyan); text-decoration: none; font-size: 0.85rem; margin-left: 14px; padding: 5px 10px; background: #131c2e; border: 1px solid var(--border-line); border-radius: 4px; transition: 0.2s; }
        .header-links a:hover { border-color: var(--accent-cyan); background: #1b2842; }

        .clock-strip { display: grid; grid-template-columns: 1fr 1fr; gap: 12px; margin-bottom: 14px; }
        @media (max-width: 580px) { .clock-strip { grid-template-columns: 1fr; } }
        .clock-box { background: var(--bg-surface); border: 1px solid var(--border-line); border-radius: 8px; padding: 10px 16px; display: flex; justify-content: space-between; align-items: center; }
        .clock-title { font-size: 0.72rem; text-transform: uppercase; color: var(--text-secondary); letter-spacing: 1px; }
        .clock-time { font-size: 1.35rem; font-family: monospace; font-weight: 800; color: #fff; letter-spacing: 1px; }

        .status-strip { display: flex; gap: 12px; margin-bottom: 18px; flex-wrap: wrap; }
        .status-pill { background: var(--bg-surface); border: 1px solid var(--border-line); padding: 7px 14px; border-radius: 20px; font-size: 0.8rem; display: flex; align-items: center; gap: 8px; }
        .indicator { width: 8px; height: 8px; border-radius: 50%; background: var(--accent-green); box-shadow: 0 0 6px var(--accent-green); }

        .cards-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(210px, 1fr)); gap: 14px; margin-bottom: 22px; }
        .metric-card { background: var(--bg-surface); border: 1px solid var(--border-line); border-radius: 10px; padding: 18px; position: relative; overflow: hidden; }
        .metric-card::after { content: ""; position: absolute; top: 0; left: 0; width: 4px; height: 100%; background: var(--accent-cyan); }
        .metric-card.gold::after { background: var(--accent-gold); }
        .metric-card.green::after { background: var(--accent-green); }
        
        .metric-label { font-size: 0.75rem; text-transform: uppercase; color: var(--text-secondary); letter-spacing: 1px; }
        .metric-value { font-size: 1.8rem; font-weight: 700; margin: 6px 0 2px 0; color: #fff; font-family: monospace; }
        .metric-sub { font-size: 0.75rem; color: var(--text-secondary); }

        .bar-wrap { width: 100%; height: 5px; background: #1a2233; border-radius: 3px; margin: 8px 0; overflow: hidden; }
        .bar-fill { height: 100%; background: var(--accent-cyan); width: 0%; transition: width 0.4s ease; }

        .charts-row { display: grid; grid-template-columns: 1fr 1fr; gap: 14px; margin-bottom: 22px; }
        @media (max-width: 720px) { .charts-row { grid-template-columns: 1fr; } }
        .chart-box { background: var(--bg-surface); border: 1px solid var(--border-line); border-radius: 10px; padding: 16px; }
        .chart-box h3 { font-size: 0.85rem; color: var(--text-secondary); text-transform: uppercase; letter-spacing: 1px; margin-bottom: 12px; }

        .action-strip { background: var(--bg-surface); border: 1px solid var(--border-line); border-radius: 10px; padding: 14px; display: grid; grid-template-columns: repeat(auto-fit, minmax(140px, 1fr)); gap: 10px; text-align: center; margin-bottom: 20px; }
        .action-btn { background: var(--bg-card); border: 1px solid var(--border-line); padding: 10px; border-radius: 6px; text-decoration: none; color: var(--text-primary); font-size: 0.85rem; font-weight: bold; transition: 0.2s; }
        .action-btn:hover { border-color: var(--accent-cyan); color: var(--accent-cyan); }

        footer { border-top: 1px solid var(--border-line); padding: 16px 0 6px 0; text-align: center; font-size: 0.8rem; color: var(--text-secondary); }
        footer .dev-title { color: #fff; font-weight: 600; margin-bottom: 4px; }
        footer .copyright { color: #62728d; font-size: 0.72rem; }
    </style>
</head>
<body>
    <div class="container">
        <header>
            <div class="brand">
                <span class="badge">${CALLSIGN}</span>
                <div>
                    <div style="font-weight: 700; font-size: 1.05rem;">AllStar Node ${NODE_NUM}</div>
                    <div class="station-desc">Telemetry & IoT Gateway</div>
                </div>
            </div>
            <div class="header-links">
                <a href="/hub/">&larr; Portal</a>
                <a href="/allmon3/">AllMon3</a>
                <a href="/allscan/">AllScan</a>
            </div>
        </header>

        <div class="clock-strip">
            <div class="clock-box">
                <div class="clock-title">World Time // <span style="color:var(--accent-cyan)">UTC / GMT</span></div>
                <div class="clock-time" id="clock-utc">--:--:-- UTC</div>
            </div>
            <div class="clock-box">
                <div class="clock-title">Station Time // <span style="color:var(--accent-green)">${TZ_LABEL}</span></div>
                <div class="clock-time" id="clock-local" style="color:var(--accent-green)">--:--:--</div>
            </div>
        </div>

        <div class="status-strip">
            <div class="status-pill"><span class="indicator"></span>Asterisk: <strong id="val-ast">ONLINE</strong></div>
            <div class="status-pill">WAN IP: <strong>${DETECTED_WAN_IP}:${WAN_PORT}</strong></div>
            <div class="status-pill">LAN Node: <strong>${DETECTED_LAN_IP}</strong></div>
            <div class="status-pill">Uptime: <strong id="val-uptime">--</strong></div>
        </div>

        <div class="cards-grid">
            <div class="metric-card gold">
                <div class="metric-label">CPU Temperature</div>
                <div class="metric-value" id="val-temp" style="color: var(--accent-gold);">-- °C</div>
                <div class="metric-sub">Thermal Sensor: Zone 0</div>
            </div>

            <div class="metric-card">
                <div class="metric-label">CPU Load (1m Avg)</div>
                <div class="metric-value" id="val-load" style="color: var(--accent-cyan);">--</div>
                <div class="metric-sub" id="val-load-sub">5m: -- | 15m: --</div>
            </div>

            <div class="metric-card green">
                <div class="metric-label">RAM Consumption</div>
                <div class="metric-value" id="val-ram" style="color: var(--accent-green);">-- %</div>
                <div class="bar-wrap"><div class="bar-fill" id="fill-ram" style="background: var(--accent-green);"></div></div>
                <div class="metric-sub" id="val-ram-sub">-- / -- MB</div>
            </div>

            <div class="metric-card">
                <div class="metric-label">MicroSD Storage (Root)</div>
                <div class="metric-value" id="val-disk">--</div>
                <div class="bar-wrap"><div class="bar-fill" id="fill-disk"></div></div>
                <div class="metric-sub" id="val-disk-sub">-- used of --</div>
            </div>
        </div>

        <div class="charts-row">
            <div class="chart-box">
                <h3>Thermal History (°C)</h3>
                <canvas id="chartTemp" height="170"></canvas>
            </div>
            <div class="chart-box">
                <h3>Core Processor Load (1m)</h3>
                <canvas id="chartLoad" height="170"></canvas>
            </div>
        </div>

        <div class="action-strip">
            <a href="/allmon3/" class="action-btn">AllMon3 Monitor</a>
            <a href="/allscan/" class="action-btn">AllScan Scanner</a>
            <a href="https://${DETECTED_LAN_IP}:9090/" class="action-btn" target="_blank">Cockpit Web Admin</a>
            <a href="https://www.qrz.com/db/${CALLSIGN}" class="action-btn" target="_blank" style="color: var(--accent-gold);">QRZ: ${CALLSIGN}</a>
        </div>

        <footer>
            <div class="dev-title">Station ${CALLSIGN} &bull; Developed by${OPERATOR_NAME}</div>
            <div class="copyright">&copy; <span id="cur-year"></span> AllStar Node ${NODE_NUM} Telemetry Gateway. Original Design by Ronik Halder (S21SRK).</div>
        </footer>
    </div>

    <script>
        function updateDigitalClocks() {
            const now = new Date();
            document.getElementById('clock-utc').innerText = now.toLocaleTimeString('en-GB', { timeZone: 'UTC', hour12: false }) + ' UTC';
            document.getElementById('clock-local').innerText = now.toLocaleTimeString('en-GB', { timeZone: '${LOCAL_TZ}', hour12: false });
        }
        setInterval(updateDigitalClocks, 1000);
        updateDigitalClocks();
        document.getElementById('cur-year').innerText = new Date().getFullYear();

        const POINTS = 25;
        const labels = Array(POINTS).fill('');
        const dataTemp = Array(POINTS).fill(null);
        const dataLoad = Array(POINTS).fill(null);

        const chartConfig = {
            responsive: true,
            animation: false,
            plugins: { legend: { display: false } },
            scales: {
                x: { display: false },
                y: { grid: { color: '#1a2233' }, ticks: { color: '#8b9bb4', font: { family: 'monospace' } } }
            }
        };

        const chartTemp = new Chart(document.getElementById('chartTemp'), {
            type: 'line',
            data: {
                labels: labels,
                datasets: [{
                    data: dataTemp,
                    borderColor: '#ffb703',
                    backgroundColor: 'rgba(255, 183, 3, 0.08)',
                    fill: true,
                    tension: 0.25,
                    borderWidth: 2
                }]
            },
            options: chartConfig
        });

        const chartLoad = new Chart(document.getElementById('chartLoad'), {
            type: 'line',
            data: {
                labels: labels,
                datasets: [{
                    data: dataLoad,
                    borderColor: '#00e5ff',
                    backgroundColor: 'rgba(0, 229, 255, 0.08)',
                    fill: true,
                    tension: 0.25,
                    borderWidth: 2
                }]
            },
            options: chartConfig
        });

        async function streamTelemetry() {
            try {
                const response = await fetch('/iot/stats.py?t=' + Date.now());
                if (!response.ok) throw new Error();
                const metrics = await response.json();

                document.getElementById('val-temp').innerText = metrics.temp + ' °C';
                document.getElementById('val-load').innerText = metrics.load1;
                document.getElementById('val-load-sub').innerText = \`5m: \${metrics.load5} | 15m: \${metrics.load15}\`;
                document.getElementById('val-ram').innerText = metrics.ram_pct + ' %';
                document.getElementById('fill-ram').style.width = metrics.ram_pct + '%';
                document.getElementById('val-ram-sub').innerText = \`\${metrics.ram_used} MB / \${metrics.ram_total} MB\`;
                document.getElementById('val-disk').innerText = metrics.disk_pct;
                document.getElementById('fill-disk').style.width = metrics.disk_pct;
                document.getElementById('val-disk-sub').innerText = \`\${metrics.disk_used} / \${metrics.disk_total}\`;
                document.getElementById('val-uptime').innerText = metrics.uptime;
                document.getElementById('val-ast').innerText = metrics.asl_status;

                dataTemp.push(metrics.temp);
                dataTemp.shift();
                chartTemp.update();

                dataLoad.push(metrics.load1);
                dataLoad.shift();
                chartLoad.update();
            } catch (err) {
                console.warn('Telemetry cycle skipped:', err);
            }
        }

        streamTelemetry();
        setInterval(streamTelemetry, 2000);
    </script>
</body>
</html>
EOF

sudo chmod 644 /opt/iot/index.html
sudo chown www-data:www-data /opt/iot/index.html

echo ""
echo "===================================================================="
echo "    Installation Successful!                                        "
echo "===================================================================="
echo "Local Dashboard:   https://${DETECTED_LAN_IP}/iot/"
echo "Remote Dashboard:  https://${DETECTED_WAN_IP}:${WAN_PORT}/iot/"
echo "Portal Launcher:   https://${DETECTED_LAN_IP}/hub/"
echo "===================================================================="
