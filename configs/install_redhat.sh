#!/usr/bin/env bash
# ==============================================================================
# install_redhat.sh — RHEL/CentOS/AlmaLinux/RockyLinux 工具安装
# 被 install_tools.sh source 使用
# ==============================================================================
__REDHAT_LOADED=1

install_packages() {
  local SUDO
  [ "$EUID" -eq 0 ] && SUDO="" || SUDO="sudo"

  # 启用 EPEL 和 CRB（适用于 RHEL 9+ / AlmaLinux / RockyLinux）
  if command -v dnf &>/dev/null; then
    info "Enabling EPEL & CRB repositories..."
    $SUDO dnf install -y epel-release &>/dev/null || true
    $SUDO dnf config-manager --set-enabled crb &>/dev/null || true
    # RockyLinux: crb 可能叫 powertools
    $SUDO dnf config-manager --set-enabled powertools &>/dev/null || true
  fi

  info "Updating dnf..."
  $SUDO dnf check-update -qq || true

  local packages=(
    # 终端 & Shell
    kitty tmux neovim
    # 现代 CLI 工具
    fzf bat ripgrep fd-find
    htop nmon jq tree wget curl git btop tealdeer glow
    vim-enhanced unzip gnupg2 redhat-lsb-core
    poppler-utils p7zip p7zip-plugins
    # 基础网络与系统工具
    openssh-server nmap-ncat lldpd ethtool lsscsi smartmontools
    net-tools sysstat python3-pip python3-virtualenv
    xfsprogs bind-utils iproute tcpdump sudo
    iputils
    # 构建依赖
    openssl-devel zlib-devel
    # 运行时（Node.js 需 NodeSource 或 EPEL）
    nodejs npm
    golang luarocks
  )

  # starship, eza, zoxide, delta, lazygit, tree-sitter 可能部分在 EPEL 中
  for pkg in starship eza zoxide delta tree-sitter; do
    if $SUDO dnf install -y "$pkg" &>/dev/null 2>&1; then
      ok "  $pkg installed"
    else
      warn "  $pkg not in repos, will install via cargo later"
    fi
  done

  # 剩余 dnf 包批量安装
  $SUDO dnf install -y "${packages[@]}"
  $SUDO dnf autoremove -y &>/dev/null && ok "已清理无用依赖包"

  install_uv
  install_rust
  install_yazi
  install_tpm
  install_opencode
  install_omp
  install_dmux
  install_herdr
  install_gonzo

  # 通过 cargo 补充安装 repo 中没有的工具
  install_cargo_extras
}

install_cargo_extras() {
  # 检查哪些还没装，用 cargo 补
  if ! command -v starship &>/dev/null; then
    info "Installing starship via cargo..."
    command -v cargo &>/dev/null && cargo install starship --locked && ok "starship installed" || warn "starship install skipped"
  fi
  if ! command -v eza &>/dev/null; then
    info "Installing eza via cargo..."
    command -v cargo &>/dev/null && cargo install eza && ok "eza installed" || warn "eza install skipped"
  fi
  if ! command -v zoxide &>/dev/null; then
    info "Installing zoxide via cargo..."
    command -v cargo &>/dev/null && cargo install zoxide --locked && ok "zoxide installed" || warn "zoxide install skipped"
  fi
  if ! command -v delta &>/dev/null; then
    info "Installing delta via cargo..."
    command -v cargo &>/dev/null && cargo install git-delta && ok "delta installed" || warn "delta install skipped"
  fi
  if ! command -v lazygit &>/dev/null; then
    info "Installing lazygit via cargo..."
    command -v cargo &>/dev/null && cargo install lazygit && ok "lazygit installed" || warn "lazygit install skipped"
  fi
  if ! command -v tree-sitter &>/dev/null; then
    info "Installing tree-sitter via cargo..."
    command -v cargo &>/dev/null && cargo install tree-sitter-cli && ok "tree-sitter installed" || warn "tree-sitter install skipped"
  fi
  if ! command -v gitu &>/dev/null; then
    info "Installing gitu via cargo..."
    command -v cargo &>/dev/null && cargo install gitu && ok "gitu installed" || warn "gitu install skipped"
  fi
  if ! command -v glow &>/dev/null; then
    info "Installing glow via cargo..."
    command -v cargo &>/dev/null && cargo install glow && ok "glow installed" || warn "glow install skipped"
  fi
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
  else
    warn "Rust install failed"
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
  if command -v go &>/dev/null; then
    info "Installing gonzo via go install..."
    go install github.com/control-theory/gonzo/cmd/gonzo@latest \
      && ok "gonzo installed" \
      || warn "gonzo install failed"
  else
    warn "go not found, skipping gonzo"
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
