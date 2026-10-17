# common.ps1
# Shared helpers, dot-sourced by setup.ps1 and sync-shortcuts.ps1

$Instance2Dir = "$env:APPDATA\Claude-Instance2"

# Order: explicit path, running MSIX process, installed MSIX package.
# The WindowsApps root is not listable without admin, so it is not scanned.
function Find-ClaudeExe {
    param([string]$ClaudeExe)

    if (-not $ClaudeExe) {
        # Filter on WindowsApps so the Claude Code CLI (also claude.exe) is not matched
        $ClaudeExe = Get-Process -Name "claude" -ErrorAction SilentlyContinue |
            Where-Object { $_.Path -like "*\WindowsApps\*" } |
            Select-Object -First 1 -ExpandProperty Path
    }

    if (-not $ClaudeExe) {
        $pkg = Get-AppxPackage -Name "Claude" -ErrorAction SilentlyContinue |
            Sort-Object Version -Descending |
            Select-Object -First 1
        if ($pkg) {
            $ClaudeExe = Get-ChildItem $pkg.InstallLocation -Filter "Claude.exe" -Recurse -ErrorAction SilentlyContinue |
                Select-Object -First 1 -ExpandProperty FullName
        }
    }

    if (-not $ClaudeExe -or -not (Test-Path $ClaudeExe)) {
        Write-Host "ERROR: Could not find Claude.exe." -ForegroundColor Red
        Write-Host "Start Claude Desktop and re-run, or pass -ClaudeExe <path>." -ForegroundColor Red
        exit 1
    }
    return $ClaudeExe
}

# GetFolderPath honors OneDrive Desktop redirection
function Set-ClaudeShortcuts {
    param([Parameter(Mandatory)][string]$ClaudeExe)

    $desktop = [Environment]::GetFolderPath("Desktop")
    $workDir = Split-Path $ClaudeExe -Parent
    $sh = New-Object -ComObject WScript.Shell

    $sc1 = $sh.CreateShortcut("$desktop\Claude Instance 1.lnk")
    $sc1.TargetPath = $ClaudeExe
    $sc1.Arguments = ""
    $sc1.WorkingDirectory = $workDir
    $sc1.Description = "Claude Desktop - Instance 1 (desktop-commander)"
    $sc1.Save()
    Write-Host "Shortcut: $desktop\Claude Instance 1.lnk" -ForegroundColor Green

    $sc2 = $sh.CreateShortcut("$desktop\Claude Instance 2.lnk")
    $sc2.TargetPath = $ClaudeExe
    $sc2.Arguments = "--user-data-dir=`"$Instance2Dir`""
    $sc2.WorkingDirectory = $workDir
    $sc2.Description = "Claude Desktop - Instance 2 (desktop-commander-2)"
    $sc2.Save()
    Write-Host "Shortcut: $desktop\Claude Instance 2.lnk" -ForegroundColor Green
}

# UTF-8 without BOM; Set-Content -Encoding UTF8 on PS 5.1 adds a BOM that breaks JSON.parse
function Write-JsonFile {
    param([Parameter(Mandatory)][string]$Path, [Parameter(Mandatory)]$Object)
    [System.IO.File]::WriteAllText($Path, ($Object | ConvertTo-Json -Depth 10))
}

function Backup-File {
    param([Parameter(Mandatory)][string]$Path)
    $backup = "$Path.bak-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
    Copy-Item $Path $backup
    Write-Host "Backed up: $backup" -ForegroundColor Green
}
