#!/usr/bin/env bash
# ==============================================================================
# install_mac.sh — macOS 工具安装（被 install_tools.sh source 使用）
# ==============================================================================
# 标记已加载，防止重复 source
__MAC_LOADED=1

install_packages() {
  # 确保 Homebrew
  if ! command -v brew &>/dev/null; then
    info "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    eval "$(/opt/homebrew/bin/brew shellenv)"
    ok "Homebrew installed"
  else
    ok "Homebrew already installed"
  fi

  local casks=(
    kitty               # 终端模拟器
    font-jetbrains-mono # 等宽字体
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
    node                # JavaScript 运行时
    glow                # Markdown 终端渲染 (yazi 预览)
    poppler             # PDF 预览 (pdftoppm)
    sevenzip            # 归档预览 (7zz)
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

  install_yazi
  install_gitu
  install_opencode
  install_omp
}

install_yazi() {
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
  triple="${arch}-apple-darwin"
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

install_gitu() {
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
    curl -fsSL https://raw.githubusercontent.com/oven-sh/bun/main/scripts/install.sh | bash \
      || curl -fsSL https://bun.sh/install | bash \
      || npm install -g bun
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

ensure_fonts() {
  local jb_dir="/Library/Fonts"
  if ls "$jb_dir"/JetBrains* &>/dev/null 2>&1; then
    ok "JetBrains Mono font found"
  else
    warn "JetBrains Mono font not found in $jb_dir"
  fi
}
