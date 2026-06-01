---
name: windows-desktop-notifications
description: Use when the user wants desktop toast notifications for Claude Code permission requests or task completion on Windows, or asks for popup reminders when Claude needs attention. Provides a silent balloon tip in the system tray with optional custom sounds.
---

# Windows Desktop Notifications

## Overview

Deploy a PowerShell-based notification system that shows silent balloon tips in the Windows system tray when Claude Code needs permission or finishes a task, with optional custom `.wav` sounds.

## Deployment (Two Files)

### 1. Deploy `notify.ps1`

Copy the bundled `notify.ps1` to `C:\Users\<USER>\.claude\notify.ps1`.

**Do NOT rewrite it.** Use the exact file shipped with this skill. It uses native `Shell_NotifyIcon` + `NIIF_NOSOUND` to suppress the Windows default beep, and supports three parameters:

| Parameter | Default | Purpose |
|-----------|---------|---------|
| `-Title` | "Claude Code" | Balloon title |
| `-Message` | "Notification" | Balloon body |
| `-SoundFile` | `""` (no sound) | Custom `.wav` filename from `C:\Windows\Media\` |
| `-Silent` | off | Suppress custom sound |

### 2. Add Hooks to `settings.json`

Merge these hooks into the user's **global** `~/.claude/settings.json` (preserve existing settings):

```json
{
  "hooks": {
    "PermissionRequest": [{
      "matcher": "",
      "hooks": [{
        "type": "command",
        "command": "powershell -NoProfile -ExecutionPolicy Bypass -File \"C:\\Users\\<USER>\\.claude\\notify.ps1\" -Title \"需要确认\" -Message \"Claude Code 需要你的权限批准\" -SoundFile \"chimes.wav\"",
        "timeout": 30,
        "async": true
      }]
    }],
    "Stop": [{
      "matcher": "",
      "hooks": [{
        "type": "command",
        "command": "powershell -NoProfile -ExecutionPolicy Bypass -File \"C:\\Users\\<USER>\\.claude\\notify.ps1\" -Title \"任务完成\" -Message \"Claude Code 已完成当前任务\" -SoundFile \"tada.wav\"",
        "timeout": 30,
        "async": true
      }]
    }]
  }
}
```

Replace `<USER>` with the actual Windows username. Merge with existing hooks — never overwrite.

## Customizing Sounds

Available `.wav` files in `C:\Windows\Media\`:

| File | Character |
|------|-----------|
| `chimes.wav` | Wind chime, soft |
| `ding.wav` | Short ding |
| `Windows Notify.wav` | Standard notification |
| `Windows Information Bar.wav` | Information bar |
| `Windows Balloon.wav` | Balloon pop |
| `tada.wav` | Fanfare (good for completion) |

To preview a sound: `powershell -NoProfile -Command "(New-Object System.Media.SoundPlayer 'C:\Windows\Media\<file>').PlaySync()"`

To disable sound: add `-Silent` flag, remove `-SoundFile`.

## Verification

Run manually to test:
```
powershell -NoProfile -ExecutionPolicy Bypass -File "C:\Users\<USER>\.claude\notify.ps1" -Title "Test" -Message "Hello" -Silent
```

The user must run `/hooks` or restart Claude Code for hook changes to take effect.

## How It Works

- Uses native Win32 `Shell_NotifyIcon` with `NIIF_NOSOUND` (0x10) flag — suppresses Windows system notification sound
- Creates a hidden message-only window via `CreateWindowEx` + `RegisterClass`
- Uses `PeekMessage` pump (non-blocking) to keep the icon alive for the balloon duration
- Balloon auto-dismisses after 5 seconds, no user interaction required

## Requirements

- Windows 10 or later
- PowerShell (Windows PowerShell 5.1 or PowerShell 7)
