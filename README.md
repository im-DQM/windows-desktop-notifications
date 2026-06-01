# Claude Code Windows Desktop Notifications

> 🔔 一行命令，让 Claude Code 在 Windows 上弹出右下角气泡通知——权限请求、任务完成，配上风铃与凯旋音效，不再错过任何交互。

## 一键安装

在 PowerShell 中运行：

```powershell
irm https://raw.githubusercontent.com/im-DQM/windows-desktop-notifications/main/install.ps1 | iex
```

安装后，在 Claude Code 中输入 `/hooks` 或重启即可生效。

## 效果

| 场景 | 标题 | 音效 |
|------|------|------|
| 需要权限 | 需要确认 | chimes.wav（风铃） |
| 任务完成 | 任务完成 | tada.wav（凯旋） |

气泡在右下角弹出，5 秒自动消失，无需点击。**无系统提示音**，只有你选的自定义音效。

## 自定义音效

编辑 `~/.claude/settings.json`，找到 hook 命令里的 `-SoundFile` 参数，换成 `C:\Windows\Media\` 下任意 `.wav` 文件：

| 文件 | 听感 |
|------|------|
| `chimes.wav` | 风铃清脆 |
| `ding.wav` | 简洁叮咚 |
| `Windows Notify.wav` | 系统标准通知 |
| `Windows Information Bar.wav` | 信息栏提示 |
| `tada.wav` | 凯旋号角 |

要去掉声音，把 `-SoundFile "xxx.wav"` 替换为 `-Silent`。

## 工作原理

- 原生 Win32 `Shell_NotifyIcon` + `NIIF_NOSOUND` 抑制 Windows 默认提示音
- `PermissionRequest` hook → 需要权限时触发
- `Stop` hook → Claude 完成回复时触发
- 异步执行，不阻塞主流程
