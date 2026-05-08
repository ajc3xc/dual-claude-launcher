# setup.ps1
# First-time setup for dual Claude Desktop launcher
# Run once after cloning the repo

$ErrorActionPreference = "Stop"

Write-Host "=== Dual Claude Launcher Setup ===" -ForegroundColor Cyan

# 1. Find current Claude exe
Write-Host "`nFinding Claude executable..." -ForegroundColor Yellow
$claudeExe = Get-ChildItem "C:\Program Files\WindowsApps" -Filter "Claude.exe" -Recurse -ErrorAction SilentlyContinue |
    Sort-Object LastWriteTime -Descending |
    Select-Object -First 1 -ExpandProperty FullName

if (-not $claudeExe) {
    Write-Host "ERROR: Could not find Claude.exe. Is Claude Desktop installed?" -ForegroundColor Red
    exit 1
}
Write-Host "Found: $claudeExe" -ForegroundColor Green

# 2. Create Instance 2 profile dir
$instance2Dir = "$env:APPDATA\Claude-Instance2"
if (-not (Test-Path $instance2Dir)) {
    New-Item -ItemType Directory -Path $instance2Dir -Force | Out-Null
    Write-Host "Created: $instance2Dir" -ForegroundColor Green
} else {
    Write-Host "Exists: $instance2Dir" -ForegroundColor Green
}

# 3. Copy config to Instance 2
$configSrc = "$PSScriptRoot\..\config\claude_desktop_config.json"
$configDst = "$instance2Dir\claude_desktop_config.json"
Copy-Item $configSrc $configDst -Force
Write-Host "Config copied to Instance 2" -ForegroundColor Green

# 4. Create desktop shortcuts
$sh = New-Object -ComObject WScript.Shell

$sc1 = $sh.CreateShortcut("$env:USERPROFILE\Desktop\Claude Instance 1.lnk")
$sc1.TargetPath = $claudeExe
$sc1.Arguments = ""
$sc1.Description = "Claude Desktop - Instance 1 (desktop-commander)"
$sc1.Save()
Write-Host "Shortcut created: Claude Instance 1.lnk" -ForegroundColor Green

$sc2 = $sh.CreateShortcut("$env:USERPROFILE\Desktop\Claude Instance 2.lnk")
$sc2.TargetPath = $claudeExe
$sc2.Arguments = "--user-data-dir=`"$instance2Dir`""
$sc2.Description = "Claude Desktop - Instance 2 (desktop-commander-2)"
$sc2.Save()
Write-Host "Shortcut created: Claude Instance 2.lnk" -ForegroundColor Green

Write-Host "`n=== Setup complete! ===" -ForegroundColor Cyan
Write-Host "Launch Instance 1: Claude Instance 1 shortcut on desktop"
Write-Host "Launch Instance 2: Claude Instance 2 shortcut on desktop"
Write-Host "`nNOTE: Edit config\claude_desktop_config.json to set your uvx.exe path for OfficeMCP"
