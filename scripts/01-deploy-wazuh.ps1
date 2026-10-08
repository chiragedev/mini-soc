# ============================================================
# Mini SOC - Step 1: Deploy Wazuh Stack via Docker
# Run as Administrator in PowerShell
# ============================================================

$ErrorActionPreference = "Stop"
$PROJECT_DIR = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)

Write-Host ''
Write-Host '============================================' -ForegroundColor Cyan
Write-Host '  Mini SOC - Wazuh Docker Deployment' -ForegroundColor Cyan
Write-Host '============================================' -ForegroundColor Cyan
Write-Host ''

# -----------------------------------------------------------
# Step 1: Check prerequisites
# -----------------------------------------------------------
Write-Host '[>] Checking prerequisites...' -ForegroundColor Yellow

# Check Docker
try {
    $dockerVersion = docker --version
    Write-Host "[+] $dockerVersion" -ForegroundColor Green
} catch {
    Write-Host '[X] Docker is not installed or not in PATH.' -ForegroundColor Red
    Write-Host '    Install Docker Desktop from https://docker.com' -ForegroundColor Red
    exit 1
}

# Check Docker is running
try {
    docker info 2>$null | Out-Null
    Write-Host '[+] Docker daemon is running' -ForegroundColor Green
} catch {
    Write-Host '[X] Docker daemon is not running. Start Docker Desktop.' -ForegroundColor Red
    exit 1
}

# Check Docker Compose
try {
    $composeVersion = docker compose version
    Write-Host "[+] $composeVersion" -ForegroundColor Green
} catch {
    Write-Host '[X] Docker Compose not available.' -ForegroundColor Red
    exit 1
}

# -----------------------------------------------------------
# Step 2: Set vm.max_map_count (required for Wazuh Indexer)
# -----------------------------------------------------------
Write-Host ''
Write-Host '[>] Configuring vm.max_map_count for Wazuh Indexer...' -ForegroundColor Yellow

# On Docker Desktop for Windows, we need to set this inside the WSL2 VM
try {
    wsl -d docker-desktop -u root -- sysctl -w vm.max_map_count=262144 2>$null
    Write-Host '[+] vm.max_map_count set to 262144 (via docker-desktop WSL)' -ForegroundColor Green
} catch {
    Write-Host '[>] Trying alternative WSL method...' -ForegroundColor Yellow
    try {
        wsl -- sudo sysctl -w vm.max_map_count=262144 2>$null
        Write-Host '[+] vm.max_map_count set to 262144 (via default WSL)' -ForegroundColor Green
    } catch {
        Write-Host '[X] Could not set vm.max_map_count automatically.' -ForegroundColor Red
        Write-Host '    Run manually: wsl -d docker-desktop -u root -- sysctl -w vm.max_map_count=262144' -ForegroundColor Yellow
    }
}

# -----------------------------------------------------------
# Step 3: Clone Wazuh Docker repository
# -----------------------------------------------------------
Write-Host ''
Write-Host '[>] Setting up Wazuh Docker files...' -ForegroundColor Yellow

$WAZUH_DIR = Join-Path $PROJECT_DIR 'wazuh-docker'
$WAZUH_VERSION = 'v4.14.8'

if (Test-Path $WAZUH_DIR) {
    Write-Host '[>] Wazuh Docker directory already exists, updating...' -ForegroundColor Yellow
    Push-Location $WAZUH_DIR
    git fetch --all --tags 2>$null
    git checkout $WAZUH_VERSION 2>$null
    Pop-Location
} else {
    Write-Host "[>] Cloning Wazuh Docker repository (tag: $WAZUH_VERSION)..." -ForegroundColor Yellow
    git clone https://github.com/wazuh/wazuh-docker.git $WAZUH_DIR
    Push-Location $WAZUH_DIR
    git checkout $WAZUH_VERSION
    Pop-Location
}

Write-Host '[+] Wazuh Docker repository ready' -ForegroundColor Green

# -----------------------------------------------------------
# Step 4: Generate TLS Certificates
# -----------------------------------------------------------
Write-Host ''
Write-Host '[>] Generating TLS certificates for Wazuh components...' -ForegroundColor Yellow

$SINGLE_NODE_DIR = Join-Path $WAZUH_DIR 'single-node'
Push-Location $SINGLE_NODE_DIR

docker compose -f generate-indexer-certs.yml run --rm generator
Write-Host '[+] TLS certificates generated' -ForegroundColor Green

# -----------------------------------------------------------
# Step 5: Start Wazuh Stack
# -----------------------------------------------------------
Write-Host ''
Write-Host '[>] Starting Wazuh stack (this may take 2-5 minutes)...' -ForegroundColor Yellow
Write-Host '[>] Pulling images and starting containers...' -ForegroundColor Yellow

docker compose up -d

Pop-Location

# -----------------------------------------------------------
# Step 6: Wait for services to be healthy
# -----------------------------------------------------------
Write-Host ''
Write-Host '[>] Waiting for Wazuh services to become healthy...' -ForegroundColor Yellow

$maxWait = 180  # 3 minutes
$elapsed = 0

while ($elapsed -lt $maxWait) {
    $containers = docker compose -f (Join-Path $SINGLE_NODE_DIR 'docker-compose.yml') ps --format json 2>$null | ConvertFrom-Json
    $allHealthy = $true

    foreach ($c in $containers) {
        if ($c.State -ne 'running') {
            $allHealthy = $false
            break
        }
    }

    if ($allHealthy -and $containers.Count -ge 3) {
        break
    }

    Write-Host "  Waiting... ${elapsed}s elapsed" -ForegroundColor Gray
    Start-Sleep -Seconds 10
    $elapsed += 10
}

# -----------------------------------------------------------
# Step 7: Verify deployment
# -----------------------------------------------------------
Write-Host ''
Write-Host '[>] Verifying deployment...' -ForegroundColor Yellow

Push-Location $SINGLE_NODE_DIR
docker compose ps
Pop-Location

Write-Host ''
Write-Host '============================================' -ForegroundColor Green
Write-Host '  Wazuh Stack Deployed Successfully!       ' -ForegroundColor Green
Write-Host '============================================' -ForegroundColor Green
Write-Host ''
Write-Host '  Dashboard:  https://localhost' -ForegroundColor White
Write-Host '  Username:   admin' -ForegroundColor White
Write-Host '  Password:   SecretPassword' -ForegroundColor White
Write-Host ''
Write-Host '  Next step:  Run .\scripts\02-install-agent.ps1' -ForegroundColor Yellow
Write-Host ''
