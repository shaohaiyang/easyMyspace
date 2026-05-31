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
    font-jetbrains-mono # 等宽字体（已使用）
  )

  local formulae=(
    tmux                # 终端复用器
    zsh                 # shell
    neovim              # 终端编辑器
    go                  # Go 语言运行时 (gopls LSP 依赖)
    starship            # 提示符
    fzf                 # 模糊搜索
    bat                 # cat 增强
    eza                 # ls 增强
    fd                  # find 增强
    ripgrep             # grep 增强
    zoxide              # cd 增强
    delta               # diff 增强
    lazygit             # Git TUI
    btop                # 系统监控
    tealdeer            # man 增强
    luarocks            # Lua 包管理器 (nvim lazy rocks)
    tree-sitter-cli     # 解析器生成器 (nvim treesitter)
    jq                  # JSON 处理
    tree                # 目录树
    wget                # 下载
    node                # JavaScript 运行时 (oh-my-pi 依赖)
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

  install_yazi_macos
  install_gitu_macos
  install_opencode
  install_omp
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
  info "Installing opencode via official install script (prebuilt binary)..."
  if command -v curl &>/dev/null; then
    curl -fsSL https://opencode.ai/install | bash \
      && ok "opencode installed" \
      || warn "opencode install failed"
  else
    warn "curl not found, skipping opencode"
  fi
}

install_omp() {
  if command -v pi &>/dev/null || command -v omp &>/dev/null; then
    ok "oh-my-pi already installed"
    return
  fi
  info "Installing oh-my-pi (pi coding agent) via npm..."
  if command -v npm &>/dev/null; then
    npm install -g @oh-my-pi/pi-coding-agent \
      && ok "oh-my-pi installed" \
      || warn "oh-my-pi install failed"
  else
    warn "npm not found, please install Node.js first"
  fi
}

install_yazi_from_github() {
  if command -v yazi &>/dev/null; then
    ok "yazi already installed"
    return
  fi

  if ! command -v curl &>/dev/null; then
    warn "curl not found, skipping yazi"
    return 1
  fi

  local arch triple latest_tag
  arch="$(uname -m)"
  case "$arch" in
    x86_64)  arch="x86_64" ;;
    aarch64|arm64) arch="aarch64" ;;
    *)       warn "unsupported arch: $arch, skipping yazi"; return 1 ;;
  esac

  case "$(uname -s)" in
    Darwin) triple="${arch}-apple-darwin" ;;
    Linux)  triple="${arch}-unknown-linux-gnu" ;;
    *)      warn "unsupported OS, skipping yazi"; return 1 ;;
  esac

  info "Fetching latest yazi release..."
  latest_tag="$(curl -fsSL https://api.github.com/repos/sxyazi/yazi/releases/latest \
    | grep '"tag_name"' | cut -d'"' -f4)" || {
    warn "failed to fetch yazi latest release"
    return 1
  }

  mkdir -p "$HOME/.local/bin"

  info "Downloading yazi ${latest_tag} (${triple})..."
  local tmp_dir
  tmp_dir="$(mktemp -d)"
  curl -fsSL "https://github.com/sxyazi/yazi/releases/download/${latest_tag}/yazi-${triple}.zip" \
    -o "$tmp_dir/yazi.zip" && \
  unzip -q "$tmp_dir/yazi.zip" -d "$tmp_dir" && \
  cp "$tmp_dir/yazi-${triple}/yazi" "$HOME/.local/bin/yazi" && \
  cp "$tmp_dir/yazi-${triple}/ya" "$HOME/.local/bin/ya" && \
  chmod +x "$HOME/.local/bin/yazi" "$HOME/.local/bin/ya" && \
  ok "yazi installed (${latest_tag})" || {
    warn "yazi install failed"
    rm -rf "$tmp_dir"
    return 1
  }
  rm -rf "$tmp_dir"
}

install_yazi_macos() {
  install_yazi_from_github
}

install_yazi_linux() {
  install_yazi_from_github
}

install_packages_linux() {
  # 使用清华大学镜像源加速
  local sources_list="$CONFIG_DIR/sway/sources.list"
  if [ -f "$sources_list" ]; then
    sudo cp "$sources_list" /etc/apt/sources.list
    ok "已切换 apt 源为清华大学镜像"
  fi

  info "Updating apt..."
  sudo apt update -qq

  local packages=(
    # Wayland 核心
    sway swaybg swayidle swaylock
    udev dbus
    # 桌面 & 状态栏 & 启动器
    waybar wofi wl-clipboard mako-notifier wlr-randr
    fonts-noto fonts-noto-cjk
    # 终端 & Shell
    kitty tmux zsh neovim starship
    # 现代 CLI 工具
    fzf bat eza fd-find ripgrep zoxide delta
    lazygit htop nmon
    golang-go luarocks tree-sitter-cli
      # 通用工具
    jq tree wget curl git vim unzip gpg lsb-release
    # 基础网络与系统工具
    openssh-server ncat lldpd ethtool lsscsi smartmontools
    ifupdown net-tools sysstat python3-pip
    xfsprogs bind9-dnsutils iproute2 tcpdump sudo
    iputils-ping iputils-tracepath
    # 构建依赖
    libssl-dev zlib1g-dev
    # 运行时
    nodejs npm
  )

  sudo apt install -y "${packages[@]}"

  install_tpm_plugins
  install_rust_linux
  install_yazi_linux
  install_opencode
  install_omp
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

install_rust_linux() {
  # 检查是否已安装 rustup
  if command -v rustup &>/dev/null; then
    local current_ver
    current_ver=$(rustc --version | grep -oP '^\d+\.\d+' || echo "0")
    if [ "$(echo "$current_ver" | cut -d. -f1)" -ge 2 ] || \
       { [ "$(echo "$current_ver" | cut -d. -f1)" -eq 1 ] && \
         [ "$(echo "$current_ver" | cut -d. -f2)" -ge 95 ]; }; then
      ok "Rust $current_ver already installed (>= 1.95)"
    else
      info "Rust $current_ver too old, upgrading to latest stable..."
      rustup update stable
    fi
    return
  fi

  info "Installing Rust via rustup (>= 1.95)..."
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --default-toolchain stable

  # 加载 cargo 环境
  [ -f "$HOME/.cargo/env" ] && . "$HOME/.cargo/env"

  if command -v cargo &>/dev/null; then
    ok "Rust installed via rustup ($(rustc --version))"

    # 配置 crates.io 清华稀疏镜像
    mkdir -p "$HOME/.cargo"
    cat > "$HOME/.cargo/config.toml" <<- 'CARGO_EOF'
[source.crates-io]
replace-with = "tuna"

[source.tuna]
registry = "sparse+https://mirrors.tuna.tsinghua.edu.cn/crates.io-index/"
CARGO_EOF
    ok "cargo 镜像已切换为清华大学（稀疏索引）"
  else
    warn "Rust install failed"
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

    # 检查是否已安装（全局或用户目录）
    if ls "$fd"/JetBrains* &>/dev/null 2>&1; then
      ok "JetBrains Mono Nerd Font found (user)"
    elif fc-list | grep -qi "JetBrainsMonoNLNerd" &>/dev/null 2>&1; then
      ok "JetBrains Mono Nerd Font found (system)"
    elif ls /usr/share/fonts/JetBrains* &>/dev/null 2>&1 || \
         ls /usr/local/share/fonts/JetBrains* &>/dev/null 2>&1; then
      ok "JetBrains Mono Nerd Font found (system)"
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
    echo "    sway: 运行 start-sway 启动 Sway 会话 (TTY)"
    echo "         Mod+Shift+R 重新加载配置"
  fi
  echo "    zsh:  source ~/.zshrc"
  echo "    kitty: 重新打开 Kitty"
  echo "    omp:  sync-omp-providers 同步 AI provider"
  echo ""
}
