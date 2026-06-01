#!/usr/bin/env bash
# ==============================================================================
# install_tools.sh — 跨平台工具安装调度器
# 被 setup.sh source 使用，不单独执行
# ==============================================================================

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'
info()  { printf "${CYAN}[INFO]${NC}  %s\n" "$*"; }
ok()    { printf "${GREEN}[OK]${NC}    %s\n" "$*"; }
warn()  { printf "${YELLOW}[WARN]${NC}  %s\n" "$*"; }
error() { printf "${RED}[ERROR]${NC} %s\n" "$*"; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

detect_os() {
  case "$(uname -s)" in
    Darwin) echo "macos" ;;
    Linux)
      if [ -f /etc/os-release ]; then
        . /etc/os-release
        case "$(echo "$ID" | tr '[:upper:]' '[:lower:]')" in
          debian|devuan|ubuntu|linuxmint|pop|elementary|zorin|kali)
            echo "debian" ;;
          rhel|centos|almalinux|rocky|fedora|ol|amzn)
            echo "redhat" ;;
          *) echo "linux" ;;
        esac
      elif [ -f /etc/debian_version ]; then
        echo "debian"
      elif [ -f /etc/redhat-release ]; then
        echo "redhat"
      else
        echo "linux"
      fi
      ;;
    *) echo "unknown" ;;
  esac
}

load_platform() {
  local os="$1"
  local script
  case "$os" in
    macos)  script="$SCRIPT_DIR/install_mac.sh" ;;
    debian) script="$SCRIPT_DIR/install_debian.sh" ;;
    redhat) script="$SCRIPT_DIR/install_redhat.sh" ;;
    *)      error "不支持的系统: $os"; return 1 ;;
  esac

  if [ ! -f "$script" ]; then
    error "未找到平台安装脚本: $script"
    return 1
  fi

  # 防止重复 source
  source "$script"
}

install_packages() {
  local os
  os=$(detect_os)
  info "检测到系统: $(uname -s) → $os"
  load_platform "$os" || return 1
  install_packages
}

ensure_fonts() {
  local os
  os=$(detect_os)
  load_platform "$os" 2>/dev/null || return 1
  ensure_fonts
}
