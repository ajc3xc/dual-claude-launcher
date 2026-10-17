# dual-claude-launcher

Run two Claude Desktop windows in parallel, each with its own MCP server connection, enabling true concurrent AI-assisted task execution on Windows.

## What This Is

Claude Desktop only runs one instance by default. This repo gives you a repeatable setup for launching a second (or more) isolated Claude window using a separate `--user-data-dir`, each connected to a different Desktop Commander MCP server. You can then run long tasks in both windows simultaneously — proven to work with overlapping timestamps across 2+ minute parallel runs.

## How It Works

- **Instance 1** — normal Claude Desktop (MSIX install), uses `desktop-commander`
- **Instance 2** — launched via shortcut with `--user-data-dir`, uses `desktop-commander-2`
- Both instances connect to the same `claude_desktop_config.json` schema but live in separate profile directories
- Tasks run concurrently — no blocking between windows

## Requirements

- Windows 11
- Claude Desktop (MSIX install)
- Node.js 18+
- [uv](https://github.com/astral-sh/uv) (for OfficeMCP)
- Git + GitHub CLI (optional, for pushing)

## Setup

### 1. Find your Claude exe path

Claude MSIX installs update automatically and change version folder. Run this to find the current path:

```powershell
Get-Process | Where-Object {$_.Name -like "*claude*"} | Select-Object -First 1 -ExpandProperty Path
```

### 2. Create Instance 2 profile directory

```powershell
New-Item -ItemType Directory -Path "$env:APPDATA\Claude-Instance2" -Force
```

### 3. Review the config templates

- `config\claude_desktop_config.instance1.json` — Instance 1 (`desktop-commander`). Merge its `mcpServers` block into Instance 1's config manually; setup does not modify it.
- `config\claude_desktop_config.instance2.json` — Instance 2 (`desktop-commander-2`). `setup.ps1` writes it to `%APPDATA%\Claude-Instance2` and fills in the `uvx.exe` path for OfficeMCP.

### 4. Run the setup script

```powershell
.\scripts\setup.ps1
```

This will:
- Auto-detect the current Claude exe path (or pass `-ClaudeExe <path>`)
- Write the Instance 2 config (an existing one is kept; `-Force` replaces it after a backup)
- Create desktop shortcuts for Instance 1 and Instance 2

## Maintenance

### After a Claude update (shortcuts break)

```powershell
.\scripts\sync-shortcuts.ps1
```

### After changing MCP config

```powershell
.\scripts\sync-config.ps1
```

Copies Instance 1's `mcpServers` to Instance 2, renaming `desktop-commander` to `desktop-commander-2`. Instance 2 `preferences` are kept and the previous config is backed up.

## MCP Config

Each instance has its own template so it only loads its own Desktop Commander server:
- `claude_desktop_config.instance1.json` — `desktop-commander` + `officemcp`
- `claude_desktop_config.instance2.json` — `desktop-commander-2` + `officemcp`

Desktop Commander is pinned (`@0.2.52`) rather than `@latest`; bump it deliberately.

## Parallel Execution Convention

| Window | MCP Server | Use For |
|--------|-----------|---------|
| Instance 1 | `desktop-commander` | Primary / long-running tasks |
| Instance 2 | `desktop-commander-2` | Secondary / parallel tasks |

When prompting Instance 2, always say **"use desktop-commander-2"** explicitly.

## Concurrency Test

To verify both instances are truly running in parallel:

**Instance 1:**
```powershell
$out = "$env:USERPROFILE\Desktop\i1-log.txt"
1..120 | ForEach-Object { "I1-$_ - $(Get-Date -Format 'HH:mm:ss')" | Add-Content $out; Start-Sleep 1 }
```

**Instance 2 (say this in Instance 2 chat):**
> Use desktop-commander-2 to run: `$out = "C:\Users\YOU\Desktop\i2-log.txt"; 1..120 | ForEach-Object { "I2-$_ - $(Get-Date -Format 'HH:mm:ss')" | Add-Content $out; Start-Sleep 1 }`

Check both files — you'll see interleaved timestamps proving true concurrency.

## Repo Structure

```
dual-claude-launcher/
├── README.md
├── config/
│   ├── claude_desktop_config.instance1.json  # Instance 1 MCP config template
│   └── claude_desktop_config.instance2.json  # Instance 2 MCP config template
└── scripts/
    ├── common.ps1                    # Shared helpers (dot-sourced)
    ├── setup.ps1                     # First-time setup
    ├── sync-shortcuts.ps1            # Fix shortcuts after Claude update
    └── sync-config.ps1              # Push config changes to Instance 2
```

## Known Issues

### "Claude for Windows" onboarding popup appears occasionally
The MSIX Claude install registers itself as the handler for `claude://` OAuth redirect URIs. When Instance 2 is running and any auth event fires, the OS sometimes prompts the main instance to handle it, briefly showing the onboarding/welcome screen. **Just close it — it does not affect either instance.** Cosmetic only, no fix currently.

### Shortcuts break after Claude updates
MSIX auto-updates change the version folder (e.g. `Claude_1.5354.0.0` → `Claude_1.6608.0.0`), breaking hardcoded shortcut paths. Run `scripts\sync-shortcuts.ps1` after any update to auto-fix.

## Repo Structure

```
dual-claude-launcher/
├── README.md
├── config/
│   ├── claude_desktop_config.instance1.json  # Instance 1 MCP config template
│   └── claude_desktop_config.instance2.json  # Instance 2 MCP config template
└── scripts/
    ├── common.ps1                    # Shared helpers (dot-sourced)
    ├── setup.ps1                     # First-time setup
    ├── sync-shortcuts.ps1            # Fix shortcuts after Claude update
    └── sync-config.ps1              # Push config changes to Instance 2
```
