# sync-shortcuts.ps1
# Run after any Claude Desktop update to fix broken shortcuts
#
#   .\scripts\sync-shortcuts.ps1                      # auto-detect Claude.exe
#   .\scripts\sync-shortcuts.ps1 -ClaudeExe "<path>"  # use an explicit path

param([string]$ClaudeExe)

$ErrorActionPreference = "Stop"
. "$PSScriptRoot\common.ps1"

$ClaudeExe = Find-ClaudeExe -ClaudeExe $ClaudeExe
Write-Host "Found Claude at: $ClaudeExe" -ForegroundColor Green

Set-ClaudeShortcuts -ClaudeExe $ClaudeExe

Write-Host "`nDone! Both shortcuts updated to: $ClaudeExe" -ForegroundColor Cyan
