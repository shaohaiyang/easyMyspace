# ==============================================================================
# Shell 增强片段 — bash 版（由 setup.sh 注入 ~/.bashrc）
# ==============================================================================

# --- Starship 提示符 ---
if command -v starship &>/dev/null; then
  eval "$(starship init bash)"
fi

# --- PATH ---
export PATH="$HOME/.local/bin:$HOME/.cargo/bin:$HOME/.opencode/bin:$HOME/go/bin:$PATH"

# --- fzf ---
if command -v fzf &>/dev/null; then
  eval "$(fzf --bash 2>/dev/null)" || true
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
    --bind 'ctrl-/:change-preview-window(down|hidden|)'"
fi

# --- zoxide ---
if command -v zoxide &>/dev/null; then
  eval "$(zoxide init bash)"
fi

# --- 工具别名 ---
if command -v eza &>/dev/null; then
  alias ls="eza --icons=auto --group-directories-first"
  alias ll="eza -la --icons=auto --group-directories-first --time-style=long-iso"
  alias lt="eza -la --icons=auto --tree --level=2"
else
  alias ls="ls --color"
  alias ll="ls -altr --color"
fi

if command -v bat &>/dev/null; then
  alias cat="bat --theme='Catppuccin Mocha'"
elif command -v batcat &>/dev/null; then
  alias cat="batcat --theme='Catppuccin Mocha'"
fi
if command -v fd &>/dev/null; then alias findf="fd"; fi
if command -v rg &>/dev/null; then alias grep="rg"; fi
if command -v delta &>/dev/null; then alias diff="delta"; fi
if command -v btop &>/dev/null; then alias top="btop"; fi
if command -v tldr &>/dev/null; then alias help="tldr"; fi

# --- Git ---
alias g="lazygit"
alias gi="gitu"
alias gs="git status -s"
alias gl="git log --oneline --graph --decorate -15"
alias gp="git push"
alias gpl="git pull"
alias gc="git commit"
alias gca="git commit --amend"
alias ga="git add"
alias gaa="git add --all"
alias gd="git diff"
alias gds="git diff --staged"
alias gb="git branch"
alias gco="git checkout"
alias gsw="git switch"
alias grb="git rebase"
alias grbi="git rebase -i"
alias gcl="git clone"

# --- 应用 ---
alias f="yazi"
alias py="python3"

# --- 目录 ---
alias ..="cd .."
alias ...="cd ../.."
alias ....="cd ../../.."
alias ~="cd ~"
