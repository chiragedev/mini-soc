# ============================================================
# Mini SOC - Step 2: Install Wazuh Agent + Sysmon on Windows
# Run as Administrator in PowerShell
# ============================================================

$ErrorActionPreference = "Stop"
$PROJECT_DIR = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)

Write-Host ''
Write-Host '============================================' -ForegroundColor Cyan
Write-Host '  Mini SOC - Windows Agent Installation' -ForegroundColor Cyan
Write-Host '============================================' -ForegroundColor Cyan
Write-Host ''

# -----------------------------------------------------------
# Check if running as Administrator
# -----------------------------------------------------------
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] 'Administrator')
if (-not $isAdmin) {
    Write-Host '[X] This script must be run as Administrator!' -ForegroundColor Red
    Write-Host '    Right-click PowerShell -> Run as Administrator' -ForegroundColor Yellow
    exit 1
}

# -----------------------------------------------------------
# Detect Wazuh Manager IP
# -----------------------------------------------------------
Write-Host '[>] Detecting Wazuh Manager IP...' -ForegroundColor Yellow

# The Wazuh Manager runs in Docker, so we connect to localhost
# But the agent needs the actual Docker container IP or host IP
$MANAGER_IP = 'localhost'

# Try to get the Docker bridge network IP
try {
    $dockerIP = docker inspect -f '{{range.NetworkSettings.Networks}}{{.IPAddress}}{{end}}' single-node-wazuh.manager-1 2>$null
    if ($dockerIP) {
        Write-Host "[+] Wazuh Manager container IP: $dockerIP" -ForegroundColor Green
    }
} catch {}

# For Docker Desktop on Windows, localhost works via port mapping
Write-Host "[+] Using Manager address: $MANAGER_IP" -ForegroundColor Green

# -----------------------------------------------------------
# Step 1: Install Sysmon for enhanced Windows logging
# -----------------------------------------------------------
Write-Host ''
Write-Host '[>] Installing Sysmon for enhanced event logging...' -ForegroundColor Yellow

$sysmonDir = Join-Path $PROJECT_DIR 'tools'
$sysmonZip = Join-Path $sysmonDir 'Sysmon.zip'
$sysmonExe = Join-Path $sysmonDir 'Sysmon64.exe'
$sysmonConfig = Join-Path $PROJECT_DIR 'config\sysmon-config.xml'

if (-not (Test-Path $sysmonDir)) {
    New-Item -ItemType Directory -Path $sysmonDir -Force | Out-Null
}

# Check if Sysmon is already installed
$sysmonService = Get-Service -Name 'Sysmon64' -ErrorAction SilentlyContinue
if ($sysmonService) {
    Write-Host '[+] Sysmon is already installed' -ForegroundColor Green
} else {
    # Download Sysmon
    if (-not (Test-Path $sysmonExe)) {
        Write-Host '[>] Downloading Sysmon from Microsoft Sysinternals...' -ForegroundColor Yellow
        $sysmonUrl = 'https://download.sysinternals.com/files/Sysmon.zip'
        Invoke-WebRequest -Uri $sysmonUrl -OutFile $sysmonZip
        Expand-Archive -Path $sysmonZip -DestinationPath $sysmonDir -Force
        Write-Host '[+] Sysmon downloaded' -ForegroundColor Green
    }

    # Install Sysmon with our config
    Write-Host '[>] Installing Sysmon with custom configuration...' -ForegroundColor Yellow
    & $sysmonExe -accepteula -i $sysmonConfig
    Write-Host '[+] Sysmon installed successfully' -ForegroundColor Green
}

# -----------------------------------------------------------
# Step 2: Install Wazuh Agent
# -----------------------------------------------------------
Write-Host ''
Write-Host '[>] Installing Wazuh Agent...' -ForegroundColor Yellow

$agentService = Get-Service -Name 'WazuhSvc' -ErrorAction SilentlyContinue
if ($agentService) {
    Write-Host '[+] Wazuh Agent is already installed' -ForegroundColor Green
} else {
    $agentMsi = Join-Path $sysmonDir 'wazuh-agent.msi'
    $agentVersion = '4.14.8'
    $agentUrl = "https://packages.wazuh.com/4.x/windows/wazuh-agent-${agentVersion}-1.msi"

    # Download Agent
    Write-Host "[>] Downloading Wazuh Agent v${agentVersion}..." -ForegroundColor Yellow
    Invoke-WebRequest -Uri $agentUrl -OutFile $agentMsi
    Write-Host '[+] Agent MSI downloaded' -ForegroundColor Green

    # Install Agent silently
    Write-Host "[>] Installing agent (connecting to manager at ${MANAGER_IP})..." -ForegroundColor Yellow
    Start-Process msiexec.exe -ArgumentList "/i `"$agentMsi`" /q WAZUH_MANAGER=`"$MANAGER_IP`" WAZUH_REGISTRATION_SERVER=`"$MANAGER_IP`"" -Wait -NoNewWindow
    Write-Host '[+] Wazuh Agent installed' -ForegroundColor Green
}

# -----------------------------------------------------------
# Step 3: Configure Agent for enhanced monitoring
# -----------------------------------------------------------
Write-Host ''
Write-Host '[>] Configuring Wazuh Agent for enhanced monitoring...' -ForegroundColor Yellow

$agentConfPath = 'C:\Program Files (x86)\ossec-agent\ossec.conf'
$customConf = Join-Path $PROJECT_DIR 'config\ossec-agent.conf'

if (Test-Path $agentConfPath) {
    # Backup original config
    $backupPath = "${agentConfPath}.bak"
    if (-not (Test-Path $backupPath)) {
        Copy-Item $agentConfPath $backupPath
        Write-Host '[+] Original config backed up to ossec.conf.bak' -ForegroundColor Green
    }

    # Copy our enhanced config
    Copy-Item $customConf $agentConfPath -Force
    Write-Host '[+] Enhanced agent configuration applied' -ForegroundColor Green
}

# -----------------------------------------------------------
# Step 4: Start/Restart the Wazuh Agent service
# -----------------------------------------------------------
Write-Host ''
Write-Host '[>] Starting Wazuh Agent service...' -ForegroundColor Yellow

$agentService = Get-Service -Name 'WazuhSvc' -ErrorAction SilentlyContinue
if ($agentService) {
    if ($agentService.Status -eq 'Running') {
        Restart-Service -Name 'WazuhSvc'
        Write-Host '[+] Wazuh Agent restarted' -ForegroundColor Green
    } else {
        Start-Service -Name 'WazuhSvc'
        Write-Host '[+] Wazuh Agent started' -ForegroundColor Green
    }
} else {
    Write-Host '[X] WazuhSvc service not found. Check installation.' -ForegroundColor Red
    exit 1
}

# -----------------------------------------------------------
# Verify
# -----------------------------------------------------------
Write-Host ''
Start-Sleep -Seconds 3
$agentStatus = Get-Service -Name 'WazuhSvc'
Write-Host ''
Write-Host '============================================' -ForegroundColor Green
Write-Host '  Agent Installation Complete!             ' -ForegroundColor Green
Write-Host '============================================' -ForegroundColor Green
Write-Host ''
Write-Host "  Agent Status: $($agentStatus.Status)" -ForegroundColor White
Write-Host "  Manager:      $MANAGER_IP" -ForegroundColor White
Write-Host '  Sysmon:       Installed and Running' -ForegroundColor White
Write-Host ''
Write-Host '  Check the Wazuh Dashboard -> Endpoints' -ForegroundColor Yellow
Write-Host '  to see this agent appear as Active' -ForegroundColor Yellow
Write-Host ''
Write-Host '  Next step:  Run .\scripts\03-deploy-rules.ps1' -ForegroundColor Yellow
Write-Host ''
