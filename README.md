<div align="center">

# 🛡️ Mini SOC Lab — Wazuh SIEM & Detection Engineering

[![Wazuh](https://img.shields.io/badge/Wazuh-v4.14-00A4E4?style=for-the-badge&logo=wazuh&logoColor=white)](https://wazuh.com)
[![Docker](https://img.shields.io/badge/Docker-Single--Node-2496ED?style=for-the-badge&logo=docker&logoColor=white)](https://www.docker.com/)
[![Sysmon](https://img.shields.io/badge/Microsoft-Sysmon-0078D4?style=for-the-badge&logo=windows&logoColor=white)](https://learn.microsoft.com/en-us/sysinternals/downloads/sysmon)
[![MITRE ATT&CK](https://img.shields.io/badge/MITRE-ATT%26CK-red?style=for-the-badge)](https://attack.mitre.org/)
[![PowerShell](https://img.shields.io/badge/PowerShell-Automation-5391FE?style=for-the-badge&logo=powershell&logoColor=white)](https://microsoft.com)

**Centralized log telemetry, real-time threat detection, and automated attack simulations mapped directly to the MITRE ATT&CK matrix.**

[Architecture](#-architecture) • [The Blind Spot Problem](#-the-blind-spot-why-sysmon) • [Detection Rules](#-mitre-attck-detection-matrix) • [Quick Start](#-quickstart--deployment) • [Simulations](#-attack-simulation-suite)

</div>

---

## 📌 Overview

This project is a functional, production-patterned **Security Operations Center (SOC)** and detection pipeline deployed locally on Windows using Docker.

It demonstrates end-to-end blue team security engineering:
1. **Endpoint Telemetry Ingestion**: Capturing deep system events from Windows endpoints.
2. **Custom Detection Engineering**: Authoring fine-grained XML rules with MITRE ATT&CK tagging.
3. **Correlation & Alerting**: Parsing process telemetry, registry modifications, and authentication failures.
4. **Safe Adversary Simulation**: Running controlled simulations to validate detections in real time.

---

## 🏗️ Architecture

```
┌────────────────────────────────────────────────────────────────────────────────────────┐
│                                   MINI SOC PIPELINE                                    │
└────────────────────────────────────────────────────────────────────────────────────────┘

  WINDOWS ENDPOINT                              WAZUH SIEM CLUSTER (DOCKER)
 ┌───────────────────────────┐                 ┌───────────────────────────────────────┐
 │ • Windows Event Logs      │                 │                                       │
 │   - Security (4624, 4625) │                 │   ┌───────────────────────────────┐   │
 │   - System (7045)         │                 │   │         Wazuh Manager         │   │
 │ • Sysmon v15+             │  TLS Port 1514  │   │  (Analysis Engine / Rules)    │   │
 │   - Event ID 1 (Processes)│────────────────▶│   └───────────────┬───────────────┘   │
 │   - Event ID 13 (Registry)│  Encrypted      │                   │ Logstash / Alerts │
 │ • PowerShell Auditing     │                 │                   ▼                   │
 │ • Wazuh Agent v4.14       │                 │   ┌───────────────────────────────┐   │
 └───────────────────────────┘                 │   │         Wazuh Indexer         │   │
                                               │   │     (OpenSearch Cluster)      │   │
                                               │   └───────────────┬───────────────┘   │
                                               │                   │ REST API          │
                                               │                   ▼                   │
                                               │   ┌───────────────────────────────┐   │
                                               │   │        Wazuh Dashboard        │   │
                                               │   │      https://localhost:443    │   │
                                               │   │    (MITRE ATT&CK Heatmap)     │   │
                                               │   └───────────────────────────────┘   │
                                               └───────────────────────────────────────┘
```

---

## 🔍 The Blind Spot: Why Default Windows Logging Isn't Enough

A standard Windows installation has a critical security visibility gap:

> **By default, Windows Event ID 4688 records process execution, but NOT the command-line arguments.**

If an adversary runs:
```powershell
powershell.exe -EncodedCommand SQBuAHYAbwBrAGUALQ...
```
Default event logs only tell you that `powershell.exe` started. You have **zero visibility** into what script ran, what parameters were supplied, or whether an in-memory cradle was downloaded.

### How this SOC fixes it:
- **Sysmon (System Monitor)** is installed with a customized security-focused filter ([sysmon-config.xml](config/sysmon-config.xml)).
- Captures **Sysmon Event ID 1** (Process Create with complete command lines and SHA256 hashes).
- Captures **Sysmon Event ID 12/13/14** (Registry modifications) and **Event ID 10** (LSASS process memory access).
- Telemetry is streamed continuously via the Wazuh Agent channel directly into the Wazuh Manager's analysis engine (`wazuh-analysisd`).

---

## 🎯 MITRE ATT&CK Detection Matrix

The custom rules deployed in [rules/local_rules.xml](rules/local_rules.xml) detect specific attacker behaviors:

| Rule ID | MITRE Technique | Tactic | Detection Focus | Severity |
|:---:|:---:|:---:|:---|:---:|
| **100001** | `T1110.001` | Credential Access | **Logon Brute Force**: 8+ failed attempts within 120s | Level 10 |
| **100002** | `T1110` / `T1078` | Initial Access | **Brute Force Followed by Successful Logon** (Correlation) | Level 12 |
| **100003** | `T1059.001` | Execution | **Encoded PowerShell**: Flags `-EncodedCommand` / `-e` | Level 10 |
| **100004** | `T1059.001` / `T1105` | Execution / Ingress | **PowerShell Download Cradle**: `Invoke-WebRequest`, `IEX` | Level 12 |
| **100005** | `T1003.001` | Credential Access | **Mimikatz Keywords**: `sekurlsa`, `logonpasswords`, `lsadump` | Level 14 |
| **100006** | `T1003.001` | Credential Access | **LSASS Memory Access**: Sysmon Event ID 10 with `0x1010` access | Level 14 |
| **100007** | `T1547.001` | Persistence | **Registry Run Key Modification**: Autostart persistence | Level 10 |
| **100008** | `T1070.001` | Defense Evasion | **Security Event Log Cleared**: Event ID 1102 / 104 | Level 12 |
| **100009** | `T1070.001` | Defense Evasion | **Log Clearing via CLI**: `wevtutil cl` execution | Level 10 |
| **100010** | `T1569.002` | Execution | **Suspicious Service Creation**: Event ID 7045 | Level 10 |
| **100011** | `T1053.005` | Persistence | **Scheduled Task Creation**: `schtasks /create` commands | Level 8 |
| **100012** | `T1136.001` | Persistence | **New Local User Creation**: Event ID 4720 | Level 8 |
| **100013** | `T1087.001` | Discovery | **Account Discovery**: `net user`, `whoami /all`, `net localgroup` | Level 7 |
| **100014** | `T1082` | Discovery | **System Information Discovery**: `systeminfo`, `ipconfig /all` | Level 7 |

---

## ⚡ Attack Simulation Suite

A safe, automated attack simulation script ([scripts/04-simulate-attacks.ps1](scripts/04-simulate-attacks.ps1)) triggers real alerts in Wazuh without causing harm to the host:

1. **Authentication Attacks**: Fires failed logon attempts via loopback IPC.
2. **Obfuscated Execution**: Launches base64 encoded PowerShell sub-processes.
3. **Download Cradles**: Tests web transfer patterns toward non-routable localhost endpoints.
4. **Credential Harvesting**: Simulates command lines with sensitive security keywords.
5. **Persistence**: Writes and immediately purges a test `HKCU\Software\Microsoft\Windows\CurrentVersion\Run` key.
6. **Defense Evasion**: Issues clearing commands to a test operational event channel.
7. **Reconnaissance**: Runs structured discovery commands to test threat correlation.

---

## 🚀 Quickstart & Deployment

### Prerequisites
- Windows 10/11 or Windows Server
- [Docker Desktop](https://www.docker.com/products/docker-desktop/) (WSL2 backend, min. 4 cores & 8 GB RAM allocated)
- PowerShell 5.1+ (Run as Administrator)

### Step 1: Deploy the Wazuh Cluster
Clones the Wazuh stack, adjusts `vm.max_map_count`, generates TLS certificates, and starts the containers:
```powershell
.\scripts\01-deploy-wazuh.ps1
```

### Step 2: Install Wazuh Agent & Sysmon
Downloads Sysmon, applies our hardened Sysmon config, installs the Windows agent, and establishes connection:
```powershell
.\scripts\02-install-agent.ps1
```

### Step 3: Deploy Custom Detection Rules
Transfers custom MITRE ATT&CK rules to the Wazuh Manager container, verifies syntax with `wazuh-analysisd`, and reloads the engine:
```powershell
.\scripts\03-deploy-rules.ps1
```

### Step 4: Run Safe Attack Simulations
Launches the interactive red team simulation menu:
```powershell
.\scripts\04-simulate-attacks.ps1
```

### Step 5: Explore the SOC Dashboard
Navigate to `https://localhost` (Ignore the self-signed SSL warning).

| Default Credentials | Value |
|:---|:---|
| **URL** | `https://localhost` |
| **Username** | `admin` |
| **Password** | `SecretPassword` |

---

## 📊 Dashboard Views to Inspect

- **Threat Intelligence > MITRE ATT&CK**: View real-time tactical heatmaps populated by simulation triggers.
- **Threat Hunting > Events**: Filter by `rule.level >= 10` to view high-severity alerts.
- **Endpoints > Summary**: Verify endpoint telemetry status, active daemons, and system inventory.

---

## 📂 Project Structure

```
mini-soc/
├── .gitignore                   # Excludes certs, keys, installer binaries & logs
├── README.md                    # Project overview & documentation
├── config/
│   ├── ossec-agent.conf         # Windows agent log channel configuration
│   └── sysmon-config.xml        # Sysmon event filtering configuration
├── rules/
│   └── local_rules.xml          # Custom detection rules with MITRE ATT&CK IDs
└── scripts/
    ├── 01-deploy-wazuh.ps1      # Automated Wazuh Docker deployment
    ├── 02-install-agent.ps1     # Automated Sysmon + Agent installer
    ├── 03-deploy-rules.ps1      # Rules deployment & analysisd syntax validation
    ├── 04-simulate-attacks.ps1  # Safe red team attack simulations
    └── 05-capture-demo.ps1      # Screenshot & walkthrough helper
```

---

## 🔒 Security Notice

- All simulations provided are **safe and strictly local**. No external network exploitation occurs.
- Private TLS certificates, installer binaries, and environment secrets are excluded from source control.
- Designed strictly for educational and detection engineering portfolio purposes.
