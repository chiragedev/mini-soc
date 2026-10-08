# ============================================================
# Mini SOC - Step 5: Dashboard Demo Helper
# Opens key dashboard views for screenshots
# ============================================================

$ErrorActionPreference = "Continue"

Write-Host ''
Write-Host '============================================' -ForegroundColor Cyan
Write-Host '  Mini SOC - Dashboard Screenshot Guide' -ForegroundColor Cyan
Write-Host '============================================' -ForegroundColor Cyan
Write-Host ''

# Open Wazuh Dashboard
$dashboardUrl = 'https://localhost'

Write-Host '[>] Opening Wazuh Dashboard...' -ForegroundColor Yellow
Start-Process $dashboardUrl

Write-Host ''
Write-Host '  Login with:' -ForegroundColor White
Write-Host '    Username: admin' -ForegroundColor White
Write-Host '    Password: SecretPassword' -ForegroundColor White
Write-Host ''
Write-Host '  (Accept the self-signed certificate warning)' -ForegroundColor Yellow
Write-Host ''

Write-Host '============================================' -ForegroundColor Magenta
Write-Host '  SCREENSHOT CHECKLIST FOR LINKEDIN' -ForegroundColor Magenta
Write-Host '============================================' -ForegroundColor Magenta
Write-Host ''
Write-Host '  Take these screenshots for your post:' -ForegroundColor White
Write-Host ''
Write-Host '  1. DASHBOARD OVERVIEW' -ForegroundColor Cyan
Write-Host '     Navigate: Home > Dashboard' -ForegroundColor Gray
Write-Host '     Shows: Agent count, alert summary, severity' -ForegroundColor Gray
Write-Host ''
Write-Host '  2. MITRE ATT and CK VIEW (most impressive!)' -ForegroundColor Cyan
Write-Host '     Navigate: Threat Intelligence > MITRE ATT and CK' -ForegroundColor Gray
Write-Host '     Shows: Technique heatmap, tactic coverage' -ForegroundColor Gray
Write-Host ''
Write-Host '  3. SECURITY ALERTS' -ForegroundColor Cyan
Write-Host '     Navigate: Threat Hunting > Events' -ForegroundColor Gray
Write-Host '     Filter: level >= 10' -ForegroundColor Gray
Write-Host '     Shows: Custom rules firing with MITRE IDs' -ForegroundColor Gray
Write-Host ''
Write-Host '  4. AGENT DETAILS' -ForegroundColor Cyan
Write-Host '     Navigate: Endpoints > (select your agent)' -ForegroundColor Gray
Write-Host '     Shows: Agent inventory, OS info, events' -ForegroundColor Gray
Write-Host ''
Write-Host '  5. ALERT DETAIL (drill into one alert)' -ForegroundColor Cyan
Write-Host '     Click any alert to expand' -ForegroundColor Gray
Write-Host '     Shows: Full JSON, MITRE mapping, severity' -ForegroundColor Gray
Write-Host ''
Write-Host '============================================' -ForegroundColor Green
Write-Host '  Tips for Great Screenshots' -ForegroundColor Green
Write-Host '============================================' -ForegroundColor Green
Write-Host ''
Write-Host '  - Use Dark Mode (Settings > Theme > Dark)' -ForegroundColor White
Write-Host '  - Maximize browser window' -ForegroundColor White
Write-Host '  - Use Win+Shift+S for region screenshots' -ForegroundColor White
Write-Host '  - Set time range to Last 1 hour' -ForegroundColor White
Write-Host '  - Crop to show the most interesting data' -ForegroundColor White
Write-Host ''
