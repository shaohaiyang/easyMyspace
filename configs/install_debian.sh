#!/usr/bin/env bash
# ==============================================================================
# install_debian.sh — Debian/Ubuntu 工具安装（被 install_tools.sh source 使用）
# ==============================================================================
__DEBIAN_LOADED=1

install_packages() {
  local CONFIG_DIR SUDO
  CONFIG_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  [ "$EUID" -eq 0 ] && SUDO="" || SUDO="sudo"

  # 可选清华源切换（Devuan 跳过，使用官方 merged 源）
  local sources_list="$CONFIG_DIR/sway/sources.list"
  if [ -f "$sources_list" ]; then
    . /etc/os-release 2>/dev/null || true
    if [ "${ID,,}" = "devuan" ]; then
      warn "Devuan 系统跳过清华源替换，使用官方 merged 源"
    else
      $SUDO cp "$sources_list" /etc/apt/sources.list
      ok "已切换 apt 源为清华大学镜像"
    fi
  fi

  # Node.js 22.x（NodeSource）
  info "Setting up Node.js 22.x (NodeSource)..."
  $SUDO apt install -y ca-certificates curl gnupg &>/dev/null
  curl -fsSL https://deb.nodesource.com/setup_22.x | $SUDO bash - || true
  ok "Node.js 22.x 源已添加"

  info "Updating apt..."
  $SUDO apt update -qq

  local packages=(
    # 终端 & Shell
    kitty tmux neovim starship
    # 现代 CLI 工具
    fzf bat eza fd-find ripgrep zoxide git-delta
    lazygit htop nmon btop tealdeer glow
    golang-go luarocks tree-sitter-cli
    # 通用工具
    jq tree wget curl git vim unzip gpg lsb-release
    poppler-utils p7zip-full
    # 基础网络与系统工具
    openssh-server ncat lldpd ethtool lsscsi smartmontools
    ifupdown net-tools sysstat python3-pip
    xfsprogs bind9-dnsutils iproute2 tcpdump sudo
    iputils-ping iputils-tracepath
    # 字体 & 语言
    fonts-liberation fonts-noto-color-emoji locales
    # Python
    python3-venv
    # 构建依赖
    libssl-dev zlib1g-dev
    # 运行时
    nodejs
  )

  $SUDO apt install -y "${packages[@]}"

  $SUDO apt autoremove -y &>/dev/null && ok "已清理无用依赖包"

  info "配置 bat 兼容性..."
  if command -v batcat &>/dev/null && ! command -v bat &>/dev/null; then
    $SUDO ln -sf "$(command -v batcat)" /usr/local/bin/bat && ok "已创建 bat → batcat 软链接" || warn "创建 bat 软链接失败"
  fi

  info "配置 locale..."
  # 确保 /etc/locale.gen 中包含所需 locale，然后生成
  for loc in en_US.UTF-8 zh_CN.UTF-8; do
    if ! locale -a 2>/dev/null | grep -qi "^${loc%.*}"; then
      $SUDO sed -i "s/^#${loc}/$loc/" /etc/locale.gen 2>/dev/null || \
        echo "$loc UTF-8" >> /etc/locale.gen
      $SUDO locale-gen "$loc" &>/dev/null && ok "$loc locale 已生成" || warn "$loc locale 生成失败"
    else
      ok "$loc locale 已存在"
    fi
  done

  install_uv
  install_rust
  install_gitu
  install_yazi
  install_tpm
  install_opencode
  install_omp
  install_dmux
  install_herdr
  install_gonzo
}

install_uv() {
  if command -v uv &>/dev/null; then
    ok "uv already installed"
    return
  fi
  info "Installing uv..."
  curl -LsSf https://astral.sh/uv/install.sh | sh
  ok "uv installed"
}

install_rust() {
  if command -v rustup &>/dev/null; then
    ok "Rust already installed ($(rustc --version))"
    return
  fi
  info "Installing Rust via rustup..."
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --default-toolchain stable

  [ -f "$HOME/.cargo/env" ] && . "$HOME/.cargo/env"

  if command -v cargo &>/dev/null; then
    ok "Rust installed ($(rustc --version))"
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

install_gitu() {
  if command -v gitu &>/dev/null; then
    ok "gitu already installed"
    return
  fi
  if command -v cargo &>/dev/null; then
    info "Installing gitu via cargo..."
    cargo install gitu && ok "gitu installed" || warn "gitu install failed"
  fi
}

install_yazi() {
  if command -v yazi &>/dev/null; then
    ok "yazi already installed"
    install_yazi_plugins
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
  triple="${arch}-unknown-linux-gnu"
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
  install_yazi_plugins
}

install_yazi_plugins() {
  export PATH="$HOME/.local/bin:$PATH"
  if ! command -v ya &>/dev/null; then
    warn "ya not found, skipping yazi plugins"
    return
  fi
  if ! command -v git &>/dev/null; then
    warn "git not found, skipping yazi plugins"
    return
  fi
  mkdir -p "$HOME/.config/yazi"
  local plugins=(
    yazi-rs/plugins:full-border
    yazi-rs/plugins:smart-enter
    yazi-rs/plugins:piper
  )
  for p in "${plugins[@]}"; do
    info "Installing yazi plugin: $p..."
    if out=$(ya pkg add "$p" 2>&1); then
      ok "  $p installed"
    else
      warn "  $p failed: $out"
    fi
  done
}

install_tpm() {
  local tpm_dir="$HOME/.tmux/plugins/tpm"
  if [ -d "$tpm_dir" ]; then
    ok "TPM already installed"
  else
    info "Installing Tmux Plugin Manager..."
    git clone --depth 1 https://github.com/tmux-plugins/tpm "$tpm_dir"
    ok "TPM installed (run 'prefix + I' inside tmux to install plugins)"
  fi
}

install_opencode() {
  if command -v opencode &>/dev/null || [ -x "$HOME/.opencode/bin/opencode" ]; then
    ok "opencode already installed"
    return
  fi
  info "Installing opencode via official install script..."
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

  if ! command -v bun &>/dev/null && [ ! -x "$HOME/.bun/bin/bun" ]; then
    info "Installing bun..."
    npm install -g bun &>/dev/null \
      || curl -fsSL https://bun.sh/install | bash \
      || curl -fsSL https://raw.githubusercontent.com/oven-sh/bun/main/scripts/install.sh | bash
  fi
  export PATH="$HOME/.bun/bin:$PATH"

  if command -v bun &>/dev/null; then
    info "Installing oh-my-pi via bun..."
    bun install -g @oh-my-pi/pi-coding-agent \
      && ok "oh-my-pi installed" \
      || warn "oh-my-pi install failed"
  else
    warn "bun install failed, skipping oh-my-pi"
  fi
}

install_dmux() {
  if command -v dmux &>/dev/null; then
    ok "dmux already installed"
    return
  fi
  info "Installing dmux via npm..."
  if command -v npm &>/dev/null; then
    $SUDO npm install -g dmux \
      && ok "dmux installed" \
      || warn "dmux install failed"
  else
    warn "npm not found, skipping dmux (Node.js required)"
  fi
}

install_herdr() {
  if command -v herdr &>/dev/null; then
    ok "herdr already installed"
    return
  fi
  info "Installing herdr via official script..."
  curl -fsSL https://herdr.dev/install.sh | sh \
    && ok "herdr installed" \
    || warn "herdr install failed"
}

install_gonzo() {
  if command -v gonzo &>/dev/null; then
    ok "gonzo already installed"
    return
  fi

  local arch triple
  arch="$(uname -m)"
  case "$arch" in
    x86_64)  triple="linux-amd64" ;;
    aarch64|arm64) triple="linux-arm64" ;;
    *)       warn "unsupported arch: $arch, skipping gonzo"; return 1 ;;
  esac

  local version="v0.4.2"
  local url="https://github.com/control-theory/gonzo/releases/download/${version}/gonzo-${version}-${triple}.tar.gz"

  info "Downloading gonzo ${version} (${triple})..."
  local tmp_dir
  tmp_dir="$(mktemp -d)"
  if curl -fsSL "$url" -o "$tmp_dir/gonzo.tar.gz"; then
    tar -xzf "$tmp_dir/gonzo.tar.gz" -C "$tmp_dir" gonzo
    mkdir -p "$HOME/.local/bin"
    cp "$tmp_dir/gonzo" "$HOME/.local/bin/gonzo"
    chmod +x "$HOME/.local/bin/gonzo"
    rm -rf "$tmp_dir"
    ok "gonzo installed to ~/.local/bin/gonzo"
  else
    rm -rf "$tmp_dir"
    warn "gonzo download failed"
  fi
}

ensure_fonts() {
  local fd="$HOME/.local/share/fonts"
  mkdir -p "$fd"

  if ls "$fd"/JetBrains* &>/dev/null 2>&1; then
    ok "JetBrains Mono Nerd Font found (user)"
  elif fc-list | grep -qi "JetBrainsMonoNLNerd" &>/dev/null 2>&1; then
    ok "JetBrains Mono Nerd Font found (system)"
  elif ls /usr/share/fonts/JetBrains* &>/dev/null 2>&1 || \
       ls /usr/local/share/fonts/JetBrains* &>/dev/null 2>&1; then
    ok "JetBrains Mono Nerd Font found (system)"
  else
    info "Downloading JetBrains Mono Nerd Font..."
    local url="https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.tar.xz"
    wget -q "$url" -O /tmp/jetbrains.tar.xz && \
      tar xf /tmp/jetbrains.tar.xz -C "$fd" && \
      fc-cache -fv "$fd" && \
      ok "JetBrains Mono Nerd Font installed" || \
      warn "Font install failed, please install manually: $url"
  fi
}
