# ==============================================================================
# 跨工具通用别名集 — 由 setup.sh 注入 ~/.zshrc
# 统一所有工具的快捷入口
# ==============================================================================

# --- 文件管理 ---
alias f="yazi"
{ command -v eza &>/dev/null && alias tree="eza -T --icons=auto"; } || alias tree="tree"

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

# --- 系统 ---
alias top="btop"
alias ps="procs"
alias du="dua i"
alias df="duf"

# --- 网络 ---
alias ip="curl -s ip.sb"
alias localip="ipconfig getifaddr en0 || ip -4 addr show | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | head -1"
alias myip="curl -s ip.sb"

# --- 目录跳转 ---
if [ -n "$ZSH_VERSION" ]; then
  alias -g ...="../.."
  alias -g ....="../../.."
  alias -g .....="../../../.."
fi
