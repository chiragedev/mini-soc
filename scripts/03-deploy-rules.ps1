# ============================================================
# Mini SOC - Step 3: Deploy Custom Detection Rules
# Run as Administrator in PowerShell
# ============================================================

$ErrorActionPreference = "Stop"
$PROJECT_DIR = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)

Write-Host ''
Write-Host '============================================' -ForegroundColor Cyan
Write-Host '  Mini SOC - Deploy Custom Detection Rules' -ForegroundColor Cyan
Write-Host '============================================' -ForegroundColor Cyan
Write-Host ''

# -----------------------------------------------------------
# Find the Wazuh Manager container
# -----------------------------------------------------------
Write-Host '[>] Finding Wazuh Manager container...' -ForegroundColor Yellow

$SINGLE_NODE_DIR = Join-Path $PROJECT_DIR 'wazuh-docker\single-node'
$managerContainer = ''

# Try to find the manager container
$containers = docker ps --format '{{.Names}}' 2>$null
foreach ($c in $containers) {
    if ($c -match 'wazuh.*manager') {
        $managerContainer = $c
        break
    }
}

if (-not $managerContainer) {
    Write-Host '[X] Wazuh Manager container not found. Is the stack running?' -ForegroundColor Red
    Write-Host '    Run 01-deploy-wazuh.ps1 first.' -ForegroundColor Yellow
    exit 1
}

Write-Host "[+] Found Wazuh Manager: $managerContainer" -ForegroundColor Green

# -----------------------------------------------------------
# Deploy custom rules to the Wazuh Manager
# -----------------------------------------------------------
Write-Host ''
Write-Host '[>] Deploying custom MITRE ATT and CK detection rules...' -ForegroundColor Yellow

$rulesFile = Join-Path $PROJECT_DIR 'rules\local_rules.xml'

# Copy rules into the container
docker cp $rulesFile "${managerContainer}:/var/ossec/etc/rules/local_rules.xml"
Write-Host '[+] Rules copied to Wazuh Manager' -ForegroundColor Green

# -----------------------------------------------------------
# Verify rules syntax
# -----------------------------------------------------------
Write-Host ''
Write-Host '[>] Verifying rules syntax...' -ForegroundColor Yellow

$verifyResult = docker exec $managerContainer /var/ossec/bin/wazuh-analysisd -t 2>&1
if ($LASTEXITCODE -eq 0) {
    Write-Host '[+] Rules syntax is valid!' -ForegroundColor Green
} else {
    Write-Host '[X] Rule syntax check found issues:' -ForegroundColor Red
    Write-Host $verifyResult -ForegroundColor Red
    exit 1
}

# -----------------------------------------------------------
# Restart Wazuh Manager to apply rules
# -----------------------------------------------------------
Write-Host ''
Write-Host '[>] Restarting Wazuh Manager to apply new rules...' -ForegroundColor Yellow

docker exec $managerContainer /var/ossec/bin/wazuh-control restart
Start-Sleep -Seconds 5

Write-Host '[+] Wazuh Manager restarted' -ForegroundColor Green

# -----------------------------------------------------------
# List deployed rules
# -----------------------------------------------------------
Write-Host ''
Write-Host '============================================' -ForegroundColor Green
Write-Host '  Custom Rules Deployed Successfully!      ' -ForegroundColor Green
Write-Host '============================================' -ForegroundColor Green
Write-Host ''
Write-Host '  Rules deployed with MITRE ATT and CK mapping:' -ForegroundColor White
Write-Host ''
Write-Host '  Rule 100001 - T1110.001  Brute Force Detection' -ForegroundColor White
Write-Host '  Rule 100002 - T1110/T1078 Brute Force + Successful Logon' -ForegroundColor White
Write-Host '  Rule 100003 - T1059.001  Encoded PowerShell' -ForegroundColor White
Write-Host '  Rule 100004 - T1059.001  PowerShell Download Cradle' -ForegroundColor White
Write-Host '  Rule 100005 - T1003.001  Mimikatz Keywords' -ForegroundColor White
Write-Host '  Rule 100006 - T1003.001  LSASS Access' -ForegroundColor White
Write-Host '  Rule 100007 - T1547.001  Registry Persistence' -ForegroundColor White
Write-Host '  Rule 100008 - T1070.001  Event Log Cleared' -ForegroundColor White
Write-Host '  Rule 100009 - T1070.001  Log Clearing Command' -ForegroundColor White
Write-Host '  Rule 100010 - T1569.002  Service Creation' -ForegroundColor White
Write-Host '  Rule 100011 - T1053.005  Scheduled Task' -ForegroundColor White
Write-Host '  Rule 100012 - T1136.001  Account Creation' -ForegroundColor White
Write-Host '  Rule 100013 - T1087.001  Account Discovery' -ForegroundColor White
Write-Host '  Rule 100014 - T1082      System Info Discovery' -ForegroundColor White
Write-Host ''
Write-Host '  View in Dashboard: MITRE ATT and CK > Framework' -ForegroundColor Yellow
Write-Host ''
Write-Host '  Next step:  Run .\scripts\04-simulate-attacks.ps1' -ForegroundColor Yellow
Write-Host ''
