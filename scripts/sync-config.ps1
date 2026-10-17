# sync-config.ps1
# Syncs MCP servers from the Instance 1 config to Instance 2
# Run after making changes to the MCP config in Instance 1
#
# - desktop-commander is renamed to desktop-commander-2 so each instance keeps its own server
# - Instance 2 "preferences" are kept; only "mcpServers" is replaced
# - The existing Instance 2 config is backed up first

$ErrorActionPreference = "Stop"
. "$PSScriptRoot\common.ps1"

$src = "$env:LOCALAPPDATA\Packages\Claude_pzs8sxrjxfjjc\LocalCache\Roaming\Claude\claude_desktop_config.json"
$dst = "$Instance2Dir\claude_desktop_config.json"

if (-not (Test-Path $src)) {
    Write-Host "ERROR: Source config not found at $src" -ForegroundColor Red
    exit 1
}

$srcCfg = Get-Content $src -Raw | ConvertFrom-Json

$servers = [ordered]@{}
if ($srcCfg.mcpServers) {
    foreach ($p in $srcCfg.mcpServers.PSObject.Properties) {
        if ($p.Name -eq "desktop-commander-2") { continue }
        $name = if ($p.Name -eq "desktop-commander") { "desktop-commander-2" } else { $p.Name }
        $servers[$name] = $p.Value
    }
}

if (Test-Path $dst) {
    Backup-File -Path $dst
    $dstCfg = Get-Content $dst -Raw | ConvertFrom-Json
} else {
    New-Item -ItemType Directory -Path $Instance2Dir -Force | Out-Null
    $dstCfg = [pscustomobject]@{}
}

$dstCfg | Add-Member -NotePropertyName "mcpServers" -NotePropertyValue ([pscustomobject]$servers) -Force
Write-JsonFile -Path $dst -Object $dstCfg

Write-Host "MCP servers synced from Instance 1 to Instance 2: $($servers.Keys -join ', ')" -ForegroundColor Green
Write-Host "Restart Instance 2 to apply changes." -ForegroundColor Yellow
