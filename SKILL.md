---
name: mac-terminal-glow
description: One-command macOS terminal beautification. Installs and configures iTerm2 + Oh My Zsh + Powerlevel10k + zsh syntax highlighting + autosuggestions + history search + fastfetch splash + git-delta + tmux + modern CLI tools (eza/bat/fzf/zoxide/btop/lazygit), with a Snazzy dark theme. Use when the user asks to beautify/美化 their terminal, set up a new Mac's shell, replicate this terminal look on another machine, or share the setup with someone else. macOS only.
---

# mac-terminal-glow

把一台 macOS 的终端一键美化成「iTerm2 + Powerlevel10k + 高亮 + 启动画面」的完整观感，**幂等、可移植、可卸载**，且**不破坏用户已有的 `.zshrc` / `.gitconfig`**。

## 何时使用
- 用户说「美化终端 / 美化一下 shell / 让终端好看点」
- 配置一台新 Mac 的命令行环境
- 想把当前这套观感复刻到另一台机器，或打包发给别人安装

## 怎么做

**首选：直接跑安装脚本。** 它已封装全部步骤，幂等可重复运行：

```bash
bash "$SKILL_DIR/install.sh"          # 完整安装（含 iTerm2 / 字体 / 默认终端）
bash "$SKILL_DIR/install.sh" --no-gui # 纯 shell，适合服务器 / SSH（不装 iTerm 与字体）
```

`$SKILL_DIR` = 本 skill 所在目录。安装后让用户**新开一个 iTerm 标签页**或运行 `exec zsh` 查看效果。

## 安装内容
- **iTerm2** + Meslo Nerd Font，自带 `Terminal Glow ✨` 暗色 Snazzy profile（自动设为默认）
- **Oh My Zsh** + **Powerlevel10k** 两行提示符（配置在 `~/.p10k.zsh`）
- **zsh-syntax-highlighting**（命令对错变色）、**zsh-autosuggestions**（灰字历史建议）、**history-substring-search**（↑↓ 按前缀翻历史）
- **fastfetch** 启动画面（在 Claude Code 内自动跳过）
- **git-delta** 美化 `git diff`
- **tmux** 带 Snazzy 状态栏配置（`~/.tmux.conf`）
- CLI：eza / bat / fzf / zoxide / btop / lazygit / tldr

## 设计要点（改动这个 skill 时务必遵守）
- **绝不重写用户的 `.zshrc`**：所有运行时逻辑放在 `~/.config/terminal-glow/glow.zsh`，只往 `.zshrc` 追加一行 `source`（带 `# >>> terminal-glow >>>` 标记，幂等）。
- **不强制系统深色模式**：终端黑底来自 iTerm profile 与 Terminal.app Pro 主题，与系统外观无关。强开系统深色会连累 Finder / 浏览器变黑——用户明确不要这个。
- **`~/.p10k.zsh` / `~/.tmux.conf` 已存在则不覆盖**，保护用户定制。
- 兼容 Intel(`/usr/local`) 与 Apple Silicon(`/opt/homebrew`)。

## 卸载
```bash
bash "$SKILL_DIR/uninstall.sh"   # 移除 source 行与 glow 配置；不卸 brew 包（手动 brew uninstall）
```

## 文件
- `install.sh` — 幂等安装器
- `uninstall.sh` — 还原接入
- `assets/glow.zsh` — shell 运行时（被 `.zshrc` source）
- `assets/p10k.zsh` — Powerlevel10k 提示符配置
- `assets/tmux.conf` — tmux 配置
- `assets/fastfetch.jsonc` — 启动画面配置
