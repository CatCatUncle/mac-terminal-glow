#!/usr/bin/env bash
# 还原 mac-terminal-glow 的接入（不卸载 brew 包）
set -uo pipefail
ZSHRC="$HOME/.zshrc"

if [[ -f "$ZSHRC" ]] && grep -qF "# >>> terminal-glow >>>" "$ZSHRC"; then
  cp "$ZSHRC" "$ZSHRC.backup.$(date +%Y%m%d-%H%M%S)"
  # 删除 >>> terminal-glow >>> 到 <<< terminal-glow <<< 之间的块
  /usr/bin/sed -i '' '/# >>> terminal-glow >>>/,/# <<< terminal-glow <<</d' "$ZSHRC"
  echo "✓ 已从 ~/.zshrc 移除 terminal-glow 接入（原文件已备份）"
else
  echo "· ~/.zshrc 未发现 terminal-glow 接入"
fi

rm -f "$HOME/.config/terminal-glow/glow.zsh"
rmdir "$HOME/.config/terminal-glow" 2>/dev/null || true
echo "✓ 已删除 ~/.config/terminal-glow/glow.zsh"

echo ""
echo "保留未动的内容（如需彻底清理请手动处理）："
echo "  · ~/.p10k.zsh / ~/.tmux.conf / ~/.config/fastfetch"
echo "  · iTerm2 DynamicProfiles/terminal-glow.json 与默认 profile 设置"
echo "  · git 全局 delta 配置（git config --global --unset core.pager 等）"
echo "  · brew 安装的包（brew uninstall powerlevel10k eza bat ... 自行决定）"
echo ""
echo "运行 exec zsh 或重开终端生效。"
