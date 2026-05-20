# ==============================================================================
# install_tools.sh — 跨平台工具安装函数库
# 被 setup.sh source 使用，不单独执行
# ==============================================================================

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'

info()  { printf "${CYAN}[INFO]${NC}  %s\n" "$*"; }
ok()    { printf "${GREEN}[OK]${NC}    %s\n" "$*"; }
warn()  { printf "${YELLOW}[WARN]${NC}  %s\n" "$*"; }
error() { printf "${RED}[ERROR]${NC} %s\n" "$*"; }

detect_os() {
  case "$(uname -s)" in
    Darwin)  echo "macos" ;;
    Linux)   echo "linux" ;;
    *)       echo "unknown" ;;
  esac
}

ensure_brew() {
  if ! command -v brew &>/dev/null; then
    info "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    eval "$(/opt/homebrew/bin/brew shellenv)"
    ok "Homebrew installed"
  else
    ok "Homebrew already installed"
  fi
}

install_packages_macos() {
  ensure_brew

  local casks=(
    kitty               # 终端模拟器
    zed                 # 编辑器
    font-jetbrains-mono # 等宽字体（已使用）
  )

  local formulae=(
    tmux                # 终端复用器
    zsh                 # shell
    neovim              # 终端编辑器
    starship            # 提示符
    fzf                 # 模糊搜索
    bat                 # cat 增强
    eza                 # ls 增强
    fd                  # find 增强
    ripgrep             # grep 增强
    zoxide              # cd 增强
    delta               # diff 增强
    lazygit             # Git TUI
    yazi                # 文件管理器
    btop                # 系统监控
    tealdeer            # man 增强
    jq                  # JSON 处理
    tree                # 目录树
    wget                # 下载
  )

  info "Installing casks..."
  for c in "${casks[@]}"; do
    if brew list --cask "$c" &>/dev/null 2>&1; then
      ok "  $c already installed"
    else
      brew install --cask "$c" && ok "  $c installed" || warn "  $c failed"
    fi
  done

  info "Installing formulae..."
  for f in "${formulae[@]}"; do
    if brew list "$f" &>/dev/null 2>&1; then
      ok "  $f already installed"
    else
      brew install "$f" && ok "  $f installed" || warn "  $f failed"
    fi
  done

  install_gitu_macos
  install_opencode
}

install_gitu_macos() {
  if command -v gitu &>/dev/null; then
    ok "gitu already installed"
    return
  fi
  info "Installing gitu via cargo..."
  if command -v cargo &>/dev/null; then
    cargo install gitu && ok "gitu installed" || warn "gitu install failed"
  else
    warn "cargo not found, skipping gitu (install Rust first: curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh)"
  fi
}

install_opencode() {
  if command -v opencode &>/dev/null; then
    ok "opencode already installed"
    return
  fi
  info "Installing opencode via npm..."
  if command -v npm &>/dev/null; then
    npm install -g @opencod3/cli && ok "opencode installed" || warn "opencode install failed"
  else
    warn "npm not found, skipping opencode (install Node.js first)"
  fi
}

install_packages_linux() {
  info "Updating apt..."
  sudo apt update -qq

  local packages=(
    # X11 核心（全新系统必须）
    xorg-server xf86-video-fbdev xf86-input-libinput
    udev dbus
    # 桌面 & 窗口管理器
    i3wm polybar rofi picom feh
    xrandr xinit font-noto
    # 终端 & Shell
    kitty tmux zsh neovim starship
    # 现代 CLI 工具
    fzf bat eza fd-find ripgrep zoxide delta
    lazygit yazi btop
    # 通用工具
    jq tree wget curl git
    # 构建依赖
    libssl-dev zlib1g-dev
  )

  sudo apt install -y "${packages[@]}"

  install_tpm_plugins
  install_opencode
}

install_tpm_plugins() {
  local tpm_dir="$HOME/.tmux/plugins/tpm"
  if [ -d "$tpm_dir" ]; then
    ok "TPM already installed"
  else
    info "Installing Tmux Plugin Manager..."
    git clone --depth 1 https://github.com/tmux-plugins/tpm "$tpm_dir"
    ok "TPM installed (run 'prefix + I' inside tmux to install plugins)"
  fi
}

ensure_fonts() {
  local os
  os=$(detect_os)

  if [ "$os" = "macos" ]; then
    # JetBrains Mono should already be installed via cask
    local jb_dir="/Library/Fonts"
    if ls "$jb_dir"/JetBrains* &>/dev/null 2>&1; then
      ok "JetBrains Mono font found"
    else
      warn "JetBrains Mono font not found in $jb_dir"
    fi
  elif [ "$os" = "linux" ]; then
    local fd="$HOME/.local/share/fonts"
    mkdir -p "$fd"
    if ls "$fd"/JetBrains* &>/dev/null 2>&1; then
      ok "JetBrains Mono font found"
    else
      info "Downloading JetBrains Mono Nerd Font..."
      local url="https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip"
      wget -q "$url" -O /tmp/jetbrains.zip && \
        unzip -q /tmp/jetbrains.zip -d "$fd" && \
        fc-cache -fv "$fd" && \
        ok "JetBrains Mono Nerd Font installed" || \
        warn "Font install failed, please install manually: $url"
    fi
  fi
}

print_summary() {
  local os
  os=$(detect_os)
  echo ""
  echo "============================================"
  printf "${GREEN}  安装完成！${NC}\n"
  echo "============================================"
  echo ""
  echo "  OS  : $os"
  echo "  Shell: zsh"
  echo "  Font : JetBrains Mono"
  echo "  Theme: Catppuccin Mocha"
  echo ""
  echo "  下一步："
  if [ "$os" = "linux" ]; then
    echo "    tmux: 进入 tmux 后按 prefix + I 安装插件"
    echo "    i3wm: 重新加载 i3 (Mod+Shift+R)"
  fi
  echo "    zsh:  source ~/.zshrc"
  echo "    kitty: 重新打开 Kitty"
  echo ""
}
