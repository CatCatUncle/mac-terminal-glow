#!/usr/bin/env bash
# ============================================================
#  mac-terminal-glow —— 一键终端美化安装器（幂等、可重复运行）
#  效果：iTerm2 + Oh My Zsh + Powerlevel10k + 语法高亮 + 自动建议
#        + fastfetch 启动画面 + git-delta + tmux + 一堆现代 CLI
#
#  用法：  bash install.sh            # 完整安装
#         bash install.sh --no-gui   # 跳过 iTerm/字体/深色模式（纯 shell，适合服务器/SSH）
# ============================================================
set -uo pipefail

GUI=1
[[ "${1:-}" == "--no-gui" ]] && GUI=0

say() { printf "\033[1;36m▸ %s\033[0m\n" "$1"; }
ok()  { printf "\033[1;32m  ✓ %s\033[0m\n" "$1"; }
warn(){ printf "\033[1;33m  ! %s\033[0m\n" "$1"; }

[[ "$(uname)" == "Darwin" ]] || { echo "本脚本仅支持 macOS / macOS only"; exit 1; }

# ---------- 0) 自举：通过 curl|bash 运行时本地无 assets，先克隆仓库 ----------
#            Self-bootstrap: when run via curl|bash there are no local assets,
#            so clone the repo and re-exec from there.
REPO_URL="https://github.com/CatCatUncle/mac-terminal-glow.git"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" 2>/dev/null && pwd || echo /nonexistent)"
ASSETS="$HERE/assets"
if [[ ! -d "$ASSETS" ]]; then
  say "下载美化资源 / Fetching assets …"
  TMP="$(mktemp -d)"
  if git clone --depth 1 "$REPO_URL" "$TMP/repo" >/dev/null 2>&1; then
    exec bash "$TMP/repo/install.sh" "$@"
  else
    echo "克隆仓库失败，请检查网络 / Failed to clone $REPO_URL"; exit 1
  fi
fi

# ---------- 1) Homebrew ----------
say "检查 Homebrew"
if ! command -v brew >/dev/null; then
  warn "未装 Homebrew，开始安装（需要联网，可能要输密码）"
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi
# 载入 brew 环境
if [[ -x /opt/homebrew/bin/brew ]]; then eval "$(/opt/homebrew/bin/brew shellenv)"
elif [[ -x /usr/local/bin/brew ]]; then eval "$(/usr/local/bin/brew shellenv)"; fi
BREW_PREFIX="$(brew --prefix)"
ok "Homebrew: $BREW_PREFIX"

# ---------- 2) 安装包 ----------
say "安装命令行工具与插件"
FORMULAE=(powerlevel10k zsh-syntax-highlighting zsh-autosuggestions \
          zsh-history-substring-search eza bat fzf zoxide fastfetch \
          git-delta btop tmux lazygit tlrc)
brew install "${FORMULAE[@]}"
ok "CLI 工具就绪"

if [[ "$GUI" == "1" ]]; then
  say "安装 iTerm2 与 Meslo Nerd 字体"
  brew install --cask iterm2 font-meslo-lg-nerd-font 2>&1 | tail -2 || true
  command -v duti >/dev/null || brew install duti >/dev/null 2>&1 || true
  ok "iTerm2 / 字体就绪"
fi

# ---------- 3) Oh My Zsh ----------
say "安装 Oh My Zsh"
if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
  RUNZSH=no CHSH=no KEEP_ZSHRC=yes \
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended --keep-zshrc
  ok "Oh My Zsh 已安装"
else
  ok "Oh My Zsh 已存在，跳过"
fi

# ---------- 4) 铺设配置文件 ----------
say "部署配置文件"
mkdir -p "$HOME/.config/terminal-glow" "$HOME/.config/fastfetch"
cp "$ASSETS/glow.zsh"     "$HOME/.config/terminal-glow/glow.zsh"
cp "$ASSETS/fastfetch.jsonc" "$HOME/.config/fastfetch/config.jsonc"
# p10k / tmux 配置：不存在才放，避免覆盖用户已有定制
[[ -f "$HOME/.p10k.zsh" ]]  || cp "$ASSETS/p10k.zsh"  "$HOME/.p10k.zsh"
[[ -f "$HOME/.tmux.conf" ]] || cp "$ASSETS/tmux.conf" "$HOME/.tmux.conf"
ok "配置已部署到 ~/.config/terminal-glow 等"

# ---------- 5) 接入 .zshrc（只追加一行 source，幂等）----------
say "接入 ~/.zshrc"
ZSHRC="$HOME/.zshrc"
MARK="# >>> terminal-glow >>>"
if [[ -f "$ZSHRC" ]] && grep -qF "$MARK" "$ZSHRC"; then
  ok ".zshrc 已接入，跳过"
else
  cp "$ZSHRC" "$ZSHRC.backup.$(date +%Y%m%d-%H%M%S)" 2>/dev/null && warn "已备份原 .zshrc"
  {
    echo ""
    echo "$MARK"
    echo "source \"\$HOME/.config/terminal-glow/glow.zsh\""
    echo "# <<< terminal-glow <<<"
  } >> "$ZSHRC"
  ok "已向 .zshrc 追加 source 行"
fi

# ---------- 6) git-delta 美化 diff（幂等）----------
say "配置 git 用 delta 美化 diff"
git config --global core.pager "delta"
git config --global interactive.diffFilter "delta --color-only"
git config --global delta.navigate true
git config --global delta.line-numbers true
git config --global delta.syntax-theme "Dracula"
git config --global delta.dark true
git config --global merge.conflictStyle "zdiff3"
git config --global diff.colorMoved "default"
ok "git diff 已美化"

# ---------- 7) GUI：iTerm 配色 + 深色模式 + 默认终端 ----------
if [[ "$GUI" == "1" ]]; then
  say "生成 iTerm2 暗色 profile（自动检测 Meslo 字体名）"
  DP_DIR="$HOME/Library/Application Support/iTerm2/DynamicProfiles"
  mkdir -p "$DP_DIR"
  # 自动找一个已装的 Meslo Nerd Font Mono Regular，读其 PostScript 名。
  # mdls -raw 对部分字体返回数组形式 ( "Name" )，故用 tr/xargs 清洗成纯字符串。
  shopt -s nullglob
  FONT_PS=""
  for f in "$HOME/Library/Fonts"/*Meslo*NerdFontMono-Regular.ttf \
           "$HOME/Library/Fonts"/*Meslo*NFM-Regular.ttf \
           /Library/Fonts/*Meslo*NerdFontMono-Regular.ttf; do
    [[ -f "$f" ]] || continue
    FONT_PS="$(mdls -raw -name com_apple_ats_name_postscript "$f" 2>/dev/null | tr -d '()\n"' | xargs)"
    [[ -n "$FONT_PS" ]] && break
  done
  shopt -u nullglob
  [[ -z "$FONT_PS" || "$FONT_PS" == "(null)" ]] && FONT_PS="Menlo-Regular" && warn "未找到 Meslo 字体，回退 Menlo（图标可能缺）"
  /usr/bin/python3 - "$DP_DIR/terminal-glow.json" "$FONT_PS" <<'PY'
import json, sys
out_path, font = sys.argv[1], sys.argv[2]
def c(h):
    h=h.lstrip('#'); r,g,b=(int(h[i:i+2],16)/255 for i in (0,2,4))
    return {"Red Component":round(r,4),"Green Component":round(g,4),"Blue Component":round(b,4),"Color Space":"sRGB"}
P={"Background Color":c("282a36"),"Foreground Color":c("eff0eb"),"Cursor Color":c("97979b"),
   "Cursor Text Color":c("282a36"),"Selection Color":c("424450"),"Selected Text Color":c("eff0eb"),
   "Bold Color":c("eff0eb"),"Ansi 0 Color":c("282a36"),"Ansi 1 Color":c("ff5c57"),"Ansi 2 Color":c("5af78e"),
   "Ansi 3 Color":c("f3f99d"),"Ansi 4 Color":c("57c7ff"),"Ansi 5 Color":c("ff6ac1"),"Ansi 6 Color":c("9aedfe"),
   "Ansi 7 Color":c("f1f1f0"),"Ansi 8 Color":c("686868"),"Ansi 9 Color":c("ff5c57"),"Ansi 10 Color":c("5af78e"),
   "Ansi 11 Color":c("f3f99d"),"Ansi 12 Color":c("57c7ff"),"Ansi 13 Color":c("ff6ac1"),"Ansi 14 Color":c("9aedfe"),
   "Ansi 15 Color":c("eff0eb")}
prof={"Name":"Terminal Glow ✨","Guid":"terminal-glow-snazzy-0001",
      "Normal Font":f"{font} 14","Non Ascii Font":f"{font} 14","Use Non-ASCII Font":True,
      "Horizontal Spacing":1.0,"Vertical Spacing":1.05,"Use Bold Font":True,"Use Bright Bold":True,
      "Use Italic Font":True,"ASCII Anti Aliased":True,"Non-ASCII Anti Aliased":True,
      "Transparency":0.04,"Blur":True,"Blur Radius":12,"Columns":110,"Rows":30,
      "Scrollback Lines":50000,"Terminal Type":"xterm-256color","Cursor Type":2,"Blinking Cursor":False}
prof.update(P)
json.dump({"Profiles":[prof]}, open(out_path,"w"), indent=2, ensure_ascii=False)
print("OK")
PY
  ok "iTerm2 profile 已生成（字体: $FONT_PS）"

  say "设 iTerm2 暗色 profile 为默认（不改系统外观：Finder/浏览器保持原样）"
  pkill -x iTerm2 2>/dev/null; sleep 1
  defaults write com.googlecode.iterm2 "Default Bookmark Guid" -string "terminal-glow-snazzy-0001" 2>/dev/null || true
  # 注意：终端黑底来自 iTerm profile 与 Terminal.app Pro 主题，独立于系统深/浅色，
  #       因此这里【不】调用系统深色模式，避免连累 Finder / 浏览器变黑。
  osascript <<'A' 2>/dev/null && ok "Terminal.app 默认主题 -> Pro(黑)"
tell application "Terminal"
  set default settings to settings set "Pro"
  set startup settings to settings set "Pro"
end tell
A
  if command -v duti >/dev/null; then
    duti -s com.googlecode.iterm2 com.apple.terminal.shell-script all 2>/dev/null || true
    duti -s com.googlecode.iterm2 .command all 2>/dev/null || true
    ok "iTerm2 已设为默认终端"
  fi
fi

echo ""
printf "\033[1;32m╭──────────────────────────────────────────────────╮\033[0m\n"
printf "\033[1;32m│  ✨ 美化完成！  All set! Your terminal now glows. │\033[0m\n"
printf "\033[1;32m╰──────────────────────────────────────────────────╯\033[0m\n"
echo "下一步 / Next steps:"
echo "  1) 打开 iTerm2（已设默认 profile 与字体）/ Open iTerm2 (default profile & font set)"
echo "  2) 新开标签页或运行 exec zsh 查看效果 / Open a new tab or run: exec zsh"
echo "  3) 想重调提示符 / Re-tune the prompt:  p10k configure"
[[ "$GUI" == "0" ]] && echo "  (--no-gui: 未装 iTerm/字体，请手动把终端字体设为 Nerd Font / set a Nerd Font manually)"
