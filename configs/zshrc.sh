# ==============================================================================
# Shell 增强片段 — 由 easyMyspace/setup.sh 注入 rc 文件
# 兼容 zsh 和 bash，zsh 专属功能用条件判断包裹
# ==============================================================================

# -------------------- 0. Starship 提示符 --------------------
if command -v starship &>/dev/null; then
  eval "$(starship init zsh)"
fi

# -------------------- 1. Zsh 自动建议（基于历史） --------------------
if [ -n "$ZSH_VERSION" ]; then
  if [ -f /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh ]; then
    source /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh
  elif [ -f /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh ]; then
    source /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh
  elif [ -f "$HOME/.zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh" ]; then
    source "$HOME/.zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh"
  fi
fi

# -------------------- 2. Zsh 语法高亮（必须放在最后） --------------------
if [ -n "$ZSH_VERSION" ]; then
  if [ -f /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]; then
    source /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
  elif [ -f /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]; then
    source /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
  elif [ -f "$HOME/.zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ]; then
    source "$HOME/.zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
  fi
fi

# -------------------- 3. fzf 集成 --------------------
if command -v fzf &>/dev/null; then
  if [ -n "$ZSH_VERSION" ]; then
    source <(fzf --zsh) 2>/dev/null || source /opt/homebrew/opt/fzf/shell/completion.zsh 2>/dev/null
  fi

  if command -v fd &>/dev/null; then
    export FZF_DEFAULT_COMMAND="fd --hidden --follow --exclude .git"
    export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
    export FZF_ALT_C_COMMAND="fd --hidden --type d --exclude .git"
  fi

  export FZF_DEFAULT_OPTS="
    --height 60% --layout=reverse --border
    --color 'bg+:#313244,fg+:#cdd6f4,hl:#f38ba8'
    --color 'info:#89b4fa,pointer:#f5c2e7,marker:#f5c2e7,spinner:#f5c2e7,header:#f38ba8'
    --color 'prompt:#a6e3a1,query:#cdd6f4'
    --preview 'bat --style=numbers --color=always {} 2>/dev/null || ls -la {}'
    --bind 'ctrl-/:change-preview-window(down|hidden|)'
  "

  if [ -n "$ZSH_VERSION" ]; then
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
fi

# -------------------- 4. zoxide（智能目录跳转） --------------------
if command -v zoxide &>/dev/null; then
  if [ -n "$ZSH_VERSION" ]; then
    eval "$(zoxide init zsh)"
  elif [ -n "$BASH_VERSION" ]; then
    eval "$(zoxide init bash)"
  fi
fi

# -------------------- 5. 现代工具别名 --------------------
if command -v eza &>/dev/null; then
  _ls() {
    local args=() has_t=false has_r=false
    for arg in "$@"; do
      if [[ "$arg" == -* && "$arg" != --* ]]; then
        [[ "$arg" == *t* ]] && has_t=true
        [[ "$arg" == *r* ]] && has_r=true
        local cleaned="${arg//[rt]/}"
        [[ -n "$cleaned" && "$cleaned" != "-" ]] && args+=("$cleaned")
      else
        args+=("$arg")
      fi
    done
    if $has_t && $has_r; then
      eza --icons=auto --group-directories-first --sort oldest "${args[@]}"
    elif $has_t; then
      eza --icons=auto --group-directories-first --sort modified "${args[@]}"
    elif $has_r; then
      eza --icons=auto --group-directories-first --reverse "${args[@]}"
    else
      eza --icons=auto --group-directories-first "${args[@]}"
    fi
  }
  alias ls=_ls
  alias ll="eza -la --icons=auto --group-directories-first --time-style=long-iso"
  alias lt="eza -la --icons=auto --tree --level=2"
else
  alias ls="ls --color"
  alias ll="ls -altr --color"
fi

if command -v bat &>/dev/null; then
  alias cat="bat --theme='Catppuccin Mocha'"
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

# -------------------- 7. 目录导航快捷方式 --------------------
alias ..="cd .."
alias ...="cd ../.."
alias ....="cd ../../.."
alias ~="cd ~"

# -------------------- 8. Zsh 补全优化 --------------------
if [ -n "$ZSH_VERSION" ]; then
  zstyle ':completion:*' menu select
  zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
  zstyle ':completion:*' verbose yes
  zstyle ':completion:*:options' description 'yes'
  zstyle ':completion:*:descriptions' format '%F{blue}-- %d --%f'
  zstyle ':completion:*:corrections' format '%F{yellow}-- %d --%f'
  zstyle ':completion:*:messages' format '%F{purple}-- %d --%f'
  zstyle ':completion:*:warnings' format '%F{red}-- no matches found --%f'
  zstyle ':completion:*:cd:*' tag-order local-directories directory-stack path-directories
  zstyle ':completion:*:cd:*' ignore-parents parent pwd
  zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}' 'r:|[._-]=* r:|=*' 'l:|=* r:|=*'
fi

# -------------------- 9. Sway 自动启动（仅 TTY1，无桌面时） --------------------
if [ -z "${DISPLAY}" ] && [ "${XDG_VTNR:-0}" -eq 1 ]; then
  exec sway
fi

# -------------------- 10. Rust 镜像 & 路径 --------------------
export PATH="$HOME/.local/bin:$HOME/.cargo/bin:$HOME/.opencode/bin:$PATH"
export CARGO_REGISTRIES_TUNA_INDEX="sparse+https://mirrors.tuna.tsinghua.edu.cn/crates.io-index/"

# -------------------- 11. Go 路径（如果存在） --------------------
export PATH="$HOME/go/bin:$PATH"
