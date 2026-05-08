# sync-shortcuts.ps1
# Run after any Claude Desktop update to fix broken shortcuts

$claudeExe = Get-ChildItem "C:\Program Files\WindowsApps" -Filter "Claude.exe" -Recurse -ErrorAction SilentlyContinue |
    Sort-Object LastWriteTime -Descending |
    Select-Object -First 1 -ExpandProperty FullName

if (-not $claudeExe) {
    Write-Host "ERROR: Could not find Claude.exe" -ForegroundColor Red
    exit 1
}

Write-Host "Found Claude at: $claudeExe" -ForegroundColor Green

$sh = New-Object -ComObject WScript.Shell
$instance2Dir = "$env:APPDATA\Claude-Instance2"

$sc1 = $sh.CreateShortcut("$env:USERPROFILE\Desktop\Claude Instance 1.lnk")
$sc1.TargetPath = $claudeExe
$sc1.Arguments = ""
$sc1.Description = "Claude Desktop - Instance 1 (desktop-commander)"
$sc1.Save()
Write-Host "Updated: Claude Instance 1.lnk" -ForegroundColor Green

$sc2 = $sh.CreateShortcut("$env:USERPROFILE\Desktop\Claude Instance 2.lnk")
$sc2.TargetPath = $claudeExe
$sc2.Arguments = "--user-data-dir=`"$instance2Dir`""
$sc2.Description = "Claude Desktop - Instance 2 (desktop-commander-2)"
$sc2.Save()
Write-Host "Updated: Claude Instance 2.lnk" -ForegroundColor Green

Write-Host "`nDone! Both shortcuts updated to: $claudeExe" -ForegroundColor Cyan
