# sync-config.ps1
# Syncs the main Claude Desktop config to Instance 2
# Run after making changes to the MCP config in Instance 1

$src = "$env:LOCALAPPDATA\Packages\Claude_pzs8sxrjxfjjc\LocalCache\Roaming\Claude\claude_desktop_config.json"
$dst = "$env:APPDATA\Claude-Instance2\claude_desktop_config.json"

if (-not (Test-Path $src)) {
    Write-Host "ERROR: Source config not found at $src" -ForegroundColor Red
    exit 1
}

Copy-Item $src $dst -Force
Write-Host "Config synced from Instance 1 to Instance 2" -ForegroundColor Green
Write-Host "Restart Instance 2 to apply changes." -ForegroundColor Yellow
