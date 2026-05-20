# ==============================================================================
# Zsh 增强片段 — 由 easyMyspace/setup.sh 注入 ~/.zshrc
# 提供：语法高亮 + 自动建议 + fzf 集成 + zoxide + 别名 + 补全优化
# ==============================================================================

# -------------------- 1. 自动建议（基于历史） --------------------
if [ -f /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh ]; then
  source /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh
elif [ -f /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh ]; then
  source /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh
elif [ -f "$HOME/.zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh" ]; then
  source "$HOME/.zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh"
fi

# -------------------- 2. 语法高亮（必须放在最后） --------------------
if [ -f /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]; then
  source /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
elif [ -f /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]; then
  source /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
elif [ -f "$HOME/.zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ]; then
  source "$HOME/.zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
fi

# -------------------- 3. fzf 集成 --------------------
if command -v fzf &>/dev/null; then
  source <(fzf --zsh) 2>/dev/null || source /opt/homebrew/opt/fzf/shell/completion.zsh 2>/dev/null

  # fzf 使用 fd 增强（如果安装了 fd）
  if command -v fd &>/dev/null; then
    export FZF_DEFAULT_COMMAND="fd --hidden --follow --exclude .git"
    export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
    export FZF_ALT_C_COMMAND="fd --hidden --type d --exclude .git"
  fi

  # fzf 预览窗口配置
  export FZF_DEFAULT_OPTS="
    --height 60% --layout=reverse --border
    --color 'bg+:#313244,fg+:#cdd6f4,hl:#f38ba8'
    --color 'info:#89b4fa,pointer:#f5c2e7,marker:#f5c2e7,spinner:#f5c2e7,header:#f38ba8'
    --color 'prompt:#a6e3a1,query:#cdd6f4'
    --preview 'bat --style=numbers --color=always {} 2>/dev/null || ls -la {}'
    --bind 'ctrl-/:change-preview-window(down|hidden|)'
  "

  # fzf Git 集成
  fzf-git-branch() {
    git branch -a --color=always | fzf --height 50% --ansi --preview 'echo {}' | tr -d ' *' | head -n 1 | tr -d '\n' | pbcopy
    zle reset-prompt
  }
  zle -N fzf-git-branch

  fzf-git-log() {
    git log --oneline --graph --color=always | fzf --height 50% --ansi --preview 'echo {}' | awk '{print $1}' | tr -d '\n' | pbcopy
    zle reset-prompt
  }
  zle -N fzf-git-log
fi

# -------------------- 4. zoxide（智能目录跳转） --------------------
if command -v zoxide &>/dev/null; then
  eval "$(zoxide init zsh)"
fi

# -------------------- 5. 现代工具别名 --------------------
if command -v eza &>/dev/null; then
  alias ls="eza --icons=auto --group-directories-first"
  alias ll="eza -la --icons=auto --group-directories-first --time-style=long-iso"
  alias lt="eza -la --icons=auto --tree --level=2"
else
  alias ls="ls --color"
  alias ll="ls -altr --color"
fi

if command -v bat &>/dev/null; then
  alias cat="bat --theme=Catppuccin-mocha"
fi

if command -v fd &>/dev/null; then
  alias findf="fd"
fi

if command -v tealdeer &>/dev/null; then
  alias help="tldr"
fi

alias grep="rg"
alias diff="delta"
alias top="btop"

# -------------------- 6. 开发工具别名 --------------------
alias g="lazygit"
alias gi="gitu"
alias f="yazi"
alias py="python3"
alias dev="zed ."

# -------------------- 7. 目录导航快捷方式 --------------------
alias ..="cd .."
alias ...="cd ../.."
alias ....="cd ../../.."
alias ~="cd ~"

# -------------------- 8. 编辑环境变量补全 --------------------
# Enhanced completion for common tools
zstyle ':completion:*' menu select
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' verbose yes
zstyle ':completion:*:options' description 'yes'
zstyle ':completion:*:descriptions' format '%F{blue}-- %d --%f'
zstyle ':completion:*:corrections' format '%F{yellow}-- %d --%f'
zstyle ':completion:*:messages' format '%F{purple}-- %d --%f'
zstyle ':completion:*:warnings' format '%F{red}-- no matches found --%f'

# cd 命令补全时不跟踪 symlink（更快）
zstyle ':completion:*:cd:*' tag-order local-directories directory-stack path-directories
zstyle ':completion:*:cd:*' ignore-parents parent pwd

# 大小写不敏感补全
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}' 'r:|[._-]=* r:|=*' 'l:|=* r:|=*'

# -------------------- 9. Go / Rust 等语言路径（如果存在） --------------------
export PATH="$HOME/.cargo/bin:$PATH"
export PATH="$HOME/go/bin:$PATH"
