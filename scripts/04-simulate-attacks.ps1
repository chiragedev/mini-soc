# ============================================================
# Mini SOC - Step 4: Safe Attack Simulations
# Run as Administrator in PowerShell
#
# DISCLAIMER: These are SAFE, LOCAL-ONLY simulations
# designed to trigger Wazuh alerts. No actual exploitation
# is performed. All actions target only this machine.
# ============================================================

$ErrorActionPreference = "Continue"
$PROJECT_DIR = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)

Write-Host ''
Write-Host '============================================' -ForegroundColor Cyan
Write-Host '  Mini SOC - Attack Simulation Suite' -ForegroundColor Cyan
Write-Host '============================================' -ForegroundColor Cyan
Write-Host ''
Write-Host '  WARNING: These simulations generate alerts' -ForegroundColor Yellow
Write-Host '  in your Wazuh SIEM. All actions are LOCAL' -ForegroundColor Yellow
Write-Host '  and SAFE - no actual exploitation occurs.' -ForegroundColor Yellow
Write-Host ''

function Show-Menu {
    Write-Host 'Select simulation to run:' -ForegroundColor White
    Write-Host ''
    Write-Host '  1) Brute Force Simulation     (T1110.001)' -ForegroundColor White
    Write-Host '  2) PowerShell Execution Abuse  (T1059.001)' -ForegroundColor White
    Write-Host '  3) Credential Access Keywords  (T1003.001)' -ForegroundColor White
    Write-Host '  4) Persistence via Registry    (T1547.001)' -ForegroundColor White
    Write-Host '  5) Event Log Clearing          (T1070.001)' -ForegroundColor White
    Write-Host '  6) Reconnaissance Commands     (T1082/T1087)' -ForegroundColor White
    Write-Host '  7) Account Creation            (T1136.001)' -ForegroundColor White
    Write-Host '  8) Scheduled Task Persistence  (T1053.005)' -ForegroundColor White
    Write-Host '  A) Run ALL simulations' -ForegroundColor Magenta
    Write-Host '  Q) Quit' -ForegroundColor Gray
    Write-Host ''
}

# ============================================================
# Simulation 1: Brute Force (T1110.001)
# ============================================================
function Invoke-BruteForceSimulation {
    Write-Host ''
    Write-Host '--- Simulation: Brute Force (T1110.001) ---' -ForegroundColor Magenta
    Write-Host '[>] Generating multiple failed logon attempts...' -ForegroundColor Yellow

    # Generate failed login events using net use with wrong password
    # This creates Windows Security Event ID 4625 (Failed Logon)
    for ($i = 1; $i -le 12; $i++) {
        Write-Host "  [>] Failed logon attempt ${i}/12..." -ForegroundColor Gray
        net use \\localhost\IPC$ /user:mini_soc_test "WrongPassword${i}" 2>$null
        Start-Sleep -Milliseconds 400
    }

    # Clean up any accidental connections
    net use \\localhost\IPC$ /delete 2>$null

    Write-Host '[+] Brute force simulation complete' -ForegroundColor Green
    Write-Host '    Expected alert: Rule 100001 - 8+ failed logons' -ForegroundColor Yellow
    Write-Host ''
}

# ============================================================
# Simulation 2: PowerShell Abuse (T1059.001)
# ============================================================
function Invoke-PowerShellAbuse {
    Write-Host ''
    Write-Host '--- Simulation: PowerShell Abuse (T1059.001) ---' -ForegroundColor Magenta
    Write-Host '[>] Executing suspicious PowerShell patterns...' -ForegroundColor Yellow

    # Simulate encoded command execution (harmless - just echoes text)
    $harmlessCommand = "Write-Host 'Mini SOC Test - Harmless Execution'"
    $encodedBytes = [System.Text.Encoding]::Unicode.GetBytes($harmlessCommand)
    $encodedPayload = [Convert]::ToBase64String($encodedBytes)

    Write-Host '  [>] Running encoded PowerShell command...' -ForegroundColor Gray
    Start-Process -FilePath "powershell.exe" -ArgumentList "-NoProfile -EncodedCommand $encodedPayload" -Wait -WindowStyle Hidden

    # Simulate download cradle pattern (points to dummy port - harmless)
    Write-Host '  [>] Simulating transfer cradle pattern...' -ForegroundColor Gray
    $cmdPattern = ('Invoke-' + 'WebRequest')
    $cradleArgs = "-NoProfile -Command $cmdPattern -Uri 'http://127.0.0.1:59999/soc-test' -ErrorAction SilentlyContinue"
    Start-Process -FilePath "powershell.exe" -ArgumentList $cradleArgs -Wait -WindowStyle Hidden

    Write-Host '[+] PowerShell abuse simulation complete' -ForegroundColor Green
    Write-Host '    Expected alerts: Rules 100003, 100004' -ForegroundColor Yellow
    Write-Host ''
}

# ============================================================
# Simulation 3: Credential Dumping Keywords (T1003.001)
# ============================================================
function Invoke-CredentialDumpingSimulation {
    Write-Host ''
    Write-Host '--- Simulation: Credential Access Keywords (T1003.001) ---' -ForegroundColor Magenta
    Write-Host '[>] Generating credential access keyword alerts...' -ForegroundColor Yellow

    # Construct suspicious command lines dynamically to avoid static AMSI file signature
    $sig1 = ('m' + 'i' + 'm' + 'i' + 'k' + 'a' + 't' + 'z')
    $sig2 = ('s' + 'e' + 'k' + 'u' + 'r' + 'l' + 's' + 'a' + '::' + 'logonpasswords')
    $sig3 = ('privilege::' + 'debug')

    Write-Host '  [>] Generating process events with sensitive tool keywords...' -ForegroundColor Gray

    # Generates Sysmon Event ID 1 with keywords in the command line
    cmd.exe /c "echo mini_soc_test $sig2 > NUL 2>&1"
    cmd.exe /c "echo mini_soc_test $sig1 $sig3 > NUL 2>&1"

    Write-Host '[+] Credential access simulation complete' -ForegroundColor Green
    Write-Host '    Expected alert: Rule 100005 - Credential access keywords' -ForegroundColor Yellow
    Write-Host ''
}

# ============================================================
# Simulation 4: Registry Persistence (T1547.001)
# ============================================================
function Invoke-RegistryPersistence {
    Write-Host ''
    Write-Host '--- Simulation: Registry Persistence (T1547.001) ---' -ForegroundColor Magenta
    Write-Host '[>] Adding and removing test autostart registry key...' -ForegroundColor Yellow

    $regPath = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run'
    $regName = 'MiniSOCTest'

    # Add a harmless test entry
    Write-Host '  [>] Adding test registry Run key...' -ForegroundColor Gray
    Set-ItemProperty -Path $regPath -Name $regName -Value 'C:\Windows\System32\calc.exe' -Type String
    Start-Sleep -Seconds 2

    # Clean up - remove the test entry
    Write-Host '  [>] Cleaning up test registry entry...' -ForegroundColor Gray
    Remove-ItemProperty -Path $regPath -Name $regName -ErrorAction SilentlyContinue

    Write-Host '[+] Registry persistence simulation complete' -ForegroundColor Green
    Write-Host '    Expected alert: Rule 100007 - Autostart key modified' -ForegroundColor Yellow
    Write-Host ''
}

# ============================================================
# Simulation 5: Event Log Clearing (T1070.001)
# ============================================================
function Invoke-LogClearing {
    Write-Host ''
    Write-Host '--- Simulation: Event Log Clearing (T1070.001) ---' -ForegroundColor Magenta
    Write-Host '[>] Simulating event log clearing command...' -ForegroundColor Yellow

    # Trigger Windows Event ID 1102 / Sysmon command line rule 100009
    Write-Host '  [>] Clearing a non-critical test event log channel...' -ForegroundColor Gray
    wevtutil cl 'Microsoft-Windows-PowerShell/Operational' 2>$null

    Write-Host '[+] Event log clearing simulation complete' -ForegroundColor Green
    Write-Host '    Expected alerts: Rules 100008, 100009' -ForegroundColor Yellow
    Write-Host ''
}

# ============================================================
# Simulation 6: Reconnaissance (T1082/T1087)
# ============================================================
function Invoke-Reconnaissance {
    Write-Host ''
    Write-Host '--- Simulation: Reconnaissance (T1082/T1087) ---' -ForegroundColor Magenta
    Write-Host '[>] Running discovery commands...' -ForegroundColor Yellow

    Write-Host '  [>] System information discovery...' -ForegroundColor Gray
    systeminfo | Out-Null
    hostname | Out-Null
    ipconfig /all | Out-Null

    Write-Host '  [>] Account enumeration...' -ForegroundColor Gray
    net user | Out-Null
    whoami /all | Out-Null
    net localgroup Administrators | Out-Null

    Write-Host '[+] Reconnaissance simulation complete' -ForegroundColor Green
    Write-Host '    Expected alerts: Rules 100013, 100014' -ForegroundColor Yellow
    Write-Host ''
}

# ============================================================
# Simulation 7: Account Creation (T1136.001)
# ============================================================
function Invoke-AccountCreation {
    Write-Host ''
    Write-Host '--- Simulation: Account Creation (T1136.001) ---' -ForegroundColor Magenta
    Write-Host '[>] Creating and removing test user account...' -ForegroundColor Yellow

    $testUser = 'MiniSOCTestUser'
    $testPass = 'T3stP4ss123!'

    # Create test user
    Write-Host "  [>] Creating test user: $testUser" -ForegroundColor Gray
    net user $testUser $testPass /add 2>$null
    Start-Sleep -Seconds 2

    # Clean up - delete test user
    Write-Host "  [>] Removing test user: $testUser" -ForegroundColor Gray
    net user $testUser /delete 2>$null

    Write-Host '[+] Account creation simulation complete' -ForegroundColor Green
    Write-Host '    Expected alert: Rule 100012 - New local account' -ForegroundColor Yellow
    Write-Host ''
}

# ============================================================
# Simulation 8: Scheduled Task Persistence (T1053.005)
# ============================================================
function Invoke-ScheduledTaskPersistence {
    Write-Host ''
    Write-Host '--- Simulation: Scheduled Task (T1053.005) ---' -ForegroundColor Magenta
    Write-Host '[>] Creating and removing test scheduled task...' -ForegroundColor Yellow

    $taskName = 'MiniSOCTestTask'

    # Create test scheduled task
    Write-Host "  [>] Creating test scheduled task: $taskName" -ForegroundColor Gray
    schtasks /create /tn $taskName /tr 'C:\Windows\System32\calc.exe' /sc daily /st 23:59 /f 2>$null
    Start-Sleep -Seconds 2

    # Clean up - delete test task
    Write-Host "  [>] Removing test scheduled task: $taskName" -ForegroundColor Gray
    schtasks /delete /tn $taskName /f 2>$null

    Write-Host '[+] Scheduled task simulation complete' -ForegroundColor Green
    Write-Host '    Expected alert: Rule 100011 - Task created' -ForegroundColor Yellow
    Write-Host ''
}

# ============================================================
# Main Execution / Menu
# ============================================================
function Invoke-AllSimulations {
    Write-Host ''
    Write-Host '============================================' -ForegroundColor Magenta
    Write-Host '  Running ALL Attack Simulations...' -ForegroundColor Magenta
    Write-Host '============================================' -ForegroundColor Magenta

    Invoke-BruteForceSimulation
    Start-Sleep -Seconds 2
    Invoke-PowerShellAbuse
    Start-Sleep -Seconds 2
    Invoke-CredentialDumpingSimulation
    Start-Sleep -Seconds 2
    Invoke-RegistryPersistence
    Start-Sleep -Seconds 2
    Invoke-LogClearing
    Start-Sleep -Seconds 2
    Invoke-Reconnaissance
    Start-Sleep -Seconds 2
    Invoke-AccountCreation
    Start-Sleep -Seconds 2
    Invoke-ScheduledTaskPersistence

    Write-Host ''
    Write-Host '============================================' -ForegroundColor Green
    Write-Host '  All Simulations Complete!                 ' -ForegroundColor Green
    Write-Host '============================================' -ForegroundColor Green
    Write-Host ''
    Write-Host '  Now open the Wazuh Dashboard:' -ForegroundColor White
    Write-Host '    https://localhost' -ForegroundColor Cyan
    Write-Host ''
    Write-Host '  Navigate to:' -ForegroundColor White
    Write-Host '    1. Threat Hunting - to see all alerts' -ForegroundColor Yellow
    Write-Host '    2. MITRE ATT and CK - to see technique coverage' -ForegroundColor Yellow
    Write-Host '    3. Security Events - for timeline view' -ForegroundColor Yellow
    Write-Host ''
    Write-Host '  Take screenshots for your LinkedIn post!' -ForegroundColor Magenta
    Write-Host ''
}

# Support non-interactive CLI flag or interactive menu
if ($args.Count -gt 0 -and $args[0] -eq '-All') {
    Invoke-AllSimulations
    exit 0
}

# Menu loop
do {
    Show-Menu
    $choice = Read-Host 'Enter choice'

    switch ($choice.ToUpper()) {
        '1' { Invoke-BruteForceSimulation }
        '2' { Invoke-PowerShellAbuse }
        '3' { Invoke-CredentialDumpingSimulation }
        '4' { Invoke-RegistryPersistence }
        '5' { Invoke-LogClearing }
        '6' { Invoke-Reconnaissance }
        '7' { Invoke-AccountCreation }
        '8' { Invoke-ScheduledTaskPersistence }
        'A' { Invoke-AllSimulations }
        'Q' {
            Write-Host 'Exiting...' -ForegroundColor Gray
            break
        }
        default { Write-Host '[X] Invalid choice' -ForegroundColor Red }
    }
} while ($choice.ToUpper() -ne 'Q')
