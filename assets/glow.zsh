# ============================================================
#  terminal-glow —— 终端美化运行时（由 mac-terminal-glow skill 安装）
#  在你的 ~/.zshrc 末尾用一行 `source` 引入本文件即可。
#  本文件可被覆盖更新；个人定制请写在 ~/.zshrc 自己的区域。
# ============================================================

# 兼容 Intel(/usr/local) 与 Apple Silicon(/opt/homebrew)
if [[ -z "$HOMEBREW_PREFIX" ]]; then
  if [[ -x /opt/homebrew/bin/brew ]]; then HOMEBREW_PREFIX=/opt/homebrew
  elif [[ -x /usr/local/bin/brew ]]; then HOMEBREW_PREFIX=/usr/local
  fi
fi
_glow_share="$HOMEBREW_PREFIX/share"

# —— 启动画面：fastfetch（默认关闭，保持开终端只有干净提示符）——
#    想开机自动显示系统信息？取消下面三行注释即可（手动随时可运行 fastfetch）：
# if [[ -o interactive && -z "$CLAUDECODE" && -z "$INSIDE_EMACS" ]] && command -v fastfetch >/dev/null; then
#   fastfetch
# fi

# —— Powerlevel10k instant prompt（必须尽量靠前）——
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# —— Oh My Zsh ——
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME=""
plugins=(git z extract sudo macos)
[[ -r "$ZSH/oh-my-zsh.sh" ]] && source "$ZSH/oh-my-zsh.sh"

# —— 主题 Powerlevel10k ——
[[ -r "$_glow_share/powerlevel10k/powerlevel10k.zsh-theme" ]] && source "$_glow_share/powerlevel10k/powerlevel10k.zsh-theme"
[[ -f ~/.p10k.zsh ]] && source ~/.p10k.zsh

# —— 颜色 / 别名（eza + bat 替代 ls/cat）——
export CLICOLOR=1
export LSCOLORS=GxFxCxDxBxegedabagaced
if command -v eza >/dev/null; then
  alias ls='eza --icons --group-directories-first'
  alias ll='eza -lh --icons --group-directories-first --git'
  alias la='eza -lah --icons --group-directories-first --git'
  alias lt='eza --tree --level=2 --icons'
fi
if command -v bat >/dev/null; then
  alias cat='bat --paging=never'
  alias catp='bat'
fi
command -v lazygit >/dev/null && alias lg='lazygit'

# —— fzf（模糊查找）+ zoxide（智能 cd）——
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
command -v fzf >/dev/null && eval "$(fzf --zsh)" 2>/dev/null
command -v zoxide >/dev/null && eval "$(zoxide init zsh)"

# —— 自动补全建议（灰字，→ 接受）——
[[ -r "$_glow_share/zsh-autosuggestions/zsh-autosuggestions.zsh" ]] && source "$_glow_share/zsh-autosuggestions/zsh-autosuggestions.zsh"

# —— 语法高亮（须在历史搜索之前）——
[[ -r "$_glow_share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ]] && source "$_glow_share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"

# —— 历史子串搜索（↑↓ 按前缀翻历史）——
if [[ -r "$_glow_share/zsh-history-substring-search/zsh-history-substring-search.zsh" ]]; then
  source "$_glow_share/zsh-history-substring-search/zsh-history-substring-search.zsh"
  bindkey '^[[A' history-substring-search-up
  bindkey '^[[B' history-substring-search-down
  bindkey '^P'   history-substring-search-up
  bindkey '^N'   history-substring-search-down
fi

# —— 历史记录优化 ——
HISTSIZE=50000
SAVEHIST=50000
setopt HIST_IGNORE_ALL_DUPS HIST_FIND_NO_DUPS HIST_REDUCE_BLANKS SHARE_HISTORY

unset _glow_share
