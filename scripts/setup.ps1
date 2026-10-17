# setup.ps1
# First-time setup for dual Claude Desktop launcher
# Run once after cloning the repo
#
#   .\scripts\setup.ps1                      # auto-detect Claude.exe
#   .\scripts\setup.ps1 -ClaudeExe "<path>"  # use an explicit path
#   .\scripts\setup.ps1 -Force               # overwrite an existing Instance 2 config

param(
    [string]$ClaudeExe,
    [switch]$Force
)

$ErrorActionPreference = "Stop"
. "$PSScriptRoot\common.ps1"

Write-Host "=== Dual Claude Launcher Setup ===" -ForegroundColor Cyan

# 1. Find current Claude exe
Write-Host "`nFinding Claude executable..." -ForegroundColor Yellow
$ClaudeExe = Find-ClaudeExe -ClaudeExe $ClaudeExe
Write-Host "Found: $ClaudeExe" -ForegroundColor Green

# 2. Create Instance 2 profile dir
if (-not (Test-Path $instance2Dir)) {
    New-Item -ItemType Directory -Path $instance2Dir -Force | Out-Null
    Write-Host "Created: $instance2Dir" -ForegroundColor Green
} else {
    Write-Host "Exists: $instance2Dir" -ForegroundColor Green
}

# 3. Write Instance 2 config (existing config is kept unless -Force)
$configSrc = "$PSScriptRoot\..\config\claude_desktop_config.instance2.json"
$configDst = "$instance2Dir\claude_desktop_config.json"

if ((Test-Path $configDst) -and -not $Force) {
    Write-Host "Config exists, not overwritten: $configDst (use -Force to replace)" -ForegroundColor Yellow
} else {
    if (Test-Path $configDst) {
        Backup-File -Path $configDst
    }

    $cfg = Get-Content $configSrc -Raw | ConvertFrom-Json

    # Resolve uvx.exe for OfficeMCP instead of leaving the YOUR_USERNAME placeholder
    $uvx = Get-Command "uvx.exe" -ErrorAction SilentlyContinue | Select-Object -First 1 -ExpandProperty Source
    if (-not $uvx -and (Test-Path "$env:USERPROFILE\.local\bin\uvx.exe")) {
        $uvx = "$env:USERPROFILE\.local\bin\uvx.exe"
    }
    if ($uvx) {
        $cfg.mcpServers.officemcp.command = $uvx
        Write-Host "OfficeMCP uvx: $uvx" -ForegroundColor Green
    } else {
        Write-Host "WARNING: uvx.exe not found; set mcpServers.officemcp.command in $configDst" -ForegroundColor Yellow
    }

    Write-JsonFile -Path $configDst -Object $cfg
    Write-Host "Config written to Instance 2" -ForegroundColor Green
}

# 4. Create desktop shortcuts
Set-ClaudeShortcuts -ClaudeExe $ClaudeExe

Write-Host "`n=== Setup complete ===" -ForegroundColor Cyan
Write-Host "1. Launch both shortcuts and confirm each window opens."
Write-Host "2. Instance 1 config is not modified by this script. Merge the mcpServers block from"
Write-Host "   config\claude_desktop_config.instance1.json into:"
Write-Host "   $env:LOCALAPPDATA\Packages\Claude_pzs8sxrjxfjjc\LocalCache\Roaming\Claude\claude_desktop_config.json"
