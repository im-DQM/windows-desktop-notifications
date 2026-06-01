# Claude Code Windows Desktop Notifications
这只是我使用cc过程中为了不一直盯着终端看，从而腾出注意力去做别的事情，给自己做的一个小工具

> 🔔 一行命令，让 Claude Code 在 Windows 上弹出右下角气泡通知——权限请求、任务完成，配上音效，不再错过任何交互。

## 一键安装

在 PowerShell 中运行：

```powershell
irm https://raw.githubusercontent.com/im-DQM/windows-desktop-notifications/master/install.ps1 | iex
```

安装后，在 Claude Code 中输入 `/hooks` 或重启即可生效。

## 效果

| 场景 | 标题 | 音效 |
|------|------|------|
| 需要权限 | 需要确认 | chimes.wav（风铃） |
| 任务完成 | 任务完成 | tada.wav（凯旋） |

气泡在右下角弹出，5 秒自动消失，无需点击。**无系统提示音**，只有你选的自定义音效。

## 自定义音效

**最简单的方式：直接告诉 Claude。** 比如：

> "我想用自己的音频文件，在 D:\my-sounds 文件夹里"

Claude 会自动帮你配置好，无需手动编辑任何文件。

---

如果你想自己控制，也可以直接编辑 `~/.claude/notify-config.json`：

```json
{ "soundDir": "D:\\my-sounds" }
```

`-SoundFile` 参数支持两种形式：
- **文件名**（如 `ding.wav`）→ 从 `notify-config.json` 中配置的目录读取
- **完整路径**（如 `D:\music\custom.wav`）→ 直接播放

默认目录为 `C:\Windows\Media\`，内置音效：

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
