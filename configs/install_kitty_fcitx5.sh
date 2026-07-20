#!/usr/bin/env bash
# ==============================================================================
# install_kitty_fcitx5.sh - kitty + fcitx5 输入法接线脚本（X11 / XFCE / xrdp）
#
# 适用场景：setup.sh 装了 kitty 但没跑 install_xfce.sh，导致 kitty 拿不到
#           GLFW_IM_MODULE，中文输入法在 kitty 里失效。
#
# 做什么：
#   1. 检测并补装 fcitx5 包（Debian/RHEL，缺失时）
#   2. 方式一：部署 ~/.local/share/applications/kitty.desktop（Exec 注入 GLFW_IM_MODULE=ibus）
#   3. 方式二：部署 ~/.xsessionrc（5 个 *_IM_MODULE export + 强制 X11 后端）
#   4. 部署 fcitx5 自启 ~/.config/autostart/fcitx5.desktop
#   5. im-config -n fcitx5（Debian 专有）
#   6. 打印验证状态
#
# 用法:
#   bash configs/install_kitty_fcitx5.sh
#
# 幂等：可安全反复运行，已有配置自动备份为 *.bak.时间戳
# 不动：kitty.conf（setup.sh 管）、fcitx5 profile（install_sway.sh 管）、Wayland
# ==============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'
info()  { printf "${CYAN}[INFO]${NC}  %s\n" "$*"; }
ok()    { printf "${GREEN}[OK]${NC}    %s\n" "$*"; }
warn()  { printf "${YELLOW}[WARN]${NC}  %s\n" "$*"; }
error() { printf "${RED}[ERROR]${NC} %s\n" "$*"; }

# ==============================================================================
# OS 检测
# ==============================================================================
detect_os() {
  if [ -f /etc/os-release ]; then
    . /etc/os-release
    case "$(echo "$ID" | tr '[:upper:]' '[:lower:]')" in
      devuan)                                       echo "debian" ;;
      debian|ubuntu|linuxmint|pop|elementary|zorin|kali) echo "debian" ;;
      rhel|centos|almalinux|rocky|fedora|ol)       echo "redhat" ;;
      *) echo "unknown" ;;
    esac
  elif [ -f /etc/debian_version ]; then
    echo "debian"
  elif [ -f /etc/redhat-release ]; then
    echo "redhat"
  elif [ "$(uname)" = "Darwin" ]; then
    echo "macos"
  else
    echo "unknown"
  fi
}

# ==============================================================================
# SUDO & 真实用户（镜像 install_xfce.sh:171-180）
# ==============================================================================
resolve_user() {
  SUDO=""
  [ "$EUID" -ne 0 ] && SUDO="sudo"

  if [ "$EUID" -eq 0 ] && [ -n "${SUDO_USER:-}" ]; then
    REAL_HOME="$(getent passwd "$SUDO_USER" | cut -d: -f6)"
    REAL_USER="$SUDO_USER"
  else
    REAL_HOME="$HOME"
    REAL_USER="${USER:-$(whoami)}"
  fi
}

# ==============================================================================
# 通用部署：备份已有 -> 覆盖 -> chown（镜像 install_xfce.sh:294-308）
# ==============================================================================
deploy_file() {
  local src="$1" dst="$2"
  if [ ! -f "$src" ]; then
    warn "源文件不存在: $src"
    return 0
  fi
  mkdir -p "$(dirname "$dst")"

  if [ -f "$dst" ]; then
    local bak="$dst.bak.$(date +%Y%m%d%H%M%S)"
    cp "$dst" "$bak"
    if [ "$EUID" -eq 0 ] && [ -n "${REAL_USER:-}" ]; then
      chown "$REAL_USER:" "$bak"
    fi
    info "已备份: $dst -> $bak"
  fi

  cp "$src" "$dst"
  if [ "$EUID" -eq 0 ] && [ -n "${REAL_USER:-}" ]; then
    chown "$REAL_USER:" "$dst"
  fi
  ok "已部署: $src -> $dst"
}

# ==============================================================================
# 1. 装 fcitx5 包（缺失时）
# ==============================================================================
install_fcitx5_packages() {
  if command -v fcitx5 &>/dev/null; then
    ok "fcitx5 已安装: $(command -v fcitx5)"
    return 0
  fi

  case "$OS" in
    debian)
      local pkgs=(fcitx5 fcitx5-chinese-addons fcitx5-frontend-gtk3 fcitx5-frontend-gtk4 fcitx5-frontend-qt5)
      info "安装 fcitx5 包: ${pkgs[*]}"
      $SUDO apt update -qq
      $SUDO apt install -y "${pkgs[@]}"
      ;;
    redhat)
      $SUDO dnf install -y epel-release || true
      local pkgs=(fcitx5 fcitx5-configtool)
      info "安装 fcitx5 包: ${pkgs[*]}"
      $SUDO dnf install -y "${pkgs[@]}"
      ;;
  esac
  ok "fcitx5 包安装完成"
}

# ==============================================================================
# 2. 方式一：部署用户级 kitty.desktop（Exec 注入 GLFW_IM_MODULE=ibus）
#    运行时从系统 .desktop 打补丁，永远匹配已装 kitty 版本
# ==============================================================================
deploy_desktop_override() {
  local src="/usr/share/applications/kitty.desktop"
  local dst="$REAL_HOME/.local/share/applications/kitty.desktop"

  if [ ! -f "$src" ]; then
    warn "系统 kitty.desktop 不存在: $src（方式一跳过；方式二重登仍可兜底）"
    return 0
  fi

  deploy_file "$src" "$dst"

  # 精确匹配 ^Exec=kitty$，不误伤 TryExec=kitty；$ 确保不改带参数的 Exec 行
  sed -i 's|^Exec=kitty$|Exec=env GLFW_IM_MODULE=ibus kitty|' "$dst"
  if grep -q '^Exec=env GLFW_IM_MODULE=ibus kitty$' "$dst"; then
    ok "方式一：kitty.desktop Exec 已注入 GLFW_IM_MODULE=ibus"
  else
    warn "方式一：未匹配到 Exec=kitty 行，请检查 $dst（可能系统 .desktop 格式不同）"
  fi
}

# ==============================================================================
# 3. 方式二：部署 ~/.xsessionrc（复用 configs/xfce/xsessionrc，与 install_xfce.sh 同源）
# ==============================================================================
deploy_xsessionrc() {
  deploy_file "$SCRIPT_DIR/xfce/xsessionrc" "$REAL_HOME/.xsessionrc"
}

# ==============================================================================
# 4. 部署 fcitx5 自启（复用 configs/xfce/autostart/fcitx5.desktop）
# ==============================================================================
deploy_fcitx5_autostart() {
  deploy_file "$SCRIPT_DIR/xfce/autostart/fcitx5.desktop" "$REAL_HOME/.config/autostart/fcitx5.desktop"
}

# ==============================================================================
# 5. 声明系统输入法框架为 fcitx5（Debian 专有）
# ==============================================================================
configure_im_framework() {
  if [ "$OS" != "debian" ]; then
    info "im-config 仅 Debian 系有，$OS 跳过"
    return 0
  fi
  if ! command -v im-config &>/dev/null; then
    warn "im-config 未安装，跳过（可 apt install im-config 后手动 im-config -n fcitx5）"
    return 0
  fi
  # im-config 交互模式需要 zenity（im-config:136 的 sanity check）；-n 非交互虽不强制，
  # 但确保 zenity 在位，用户后续可正常跑交互式 im-config 重新选择输入法框架
  if ! command -v zenity &>/dev/null; then
    info "安装 zenity（im-config 交互模式依赖）"
    $SUDO apt install -y zenity
  fi
  # im-config 写 ~/.xinputrc，是 per-user 命令
  if [ "$EUID" -eq 0 ] && [ -n "${SUDO_USER:-}" ] && [ "$SUDO_USER" != "root" ]; then
    su "$SUDO_USER" -c "im-config -n fcitx5"
  else
    im-config -n fcitx5
  fi
  ok "已声明系统输入法框架为 fcitx5 (im-config)"
}

# ==============================================================================
# 6. 验证状态
# ==============================================================================
verify() {
  local dst_desktop="$REAL_HOME/.local/share/applications/kitty.desktop"
  local dst_xsessionrc="$REAL_HOME/.xsessionrc"
  local dst_autostart="$REAL_HOME/.config/autostart/fcitx5.desktop"

  echo ""
  echo "============================================"
  printf "${GREEN}  验证状态${NC}\n"
  echo "============================================"

  # 方式一
  if [ -f "$dst_desktop" ]; then
    local exec_line
    exec_line=$(grep '^Exec=' "$dst_desktop" | head -1)
    ok "方式一 .desktop: $exec_line"
  else
    warn "方式一 .desktop: 缺失 ($dst_desktop)"
  fi

  # 方式二
  if [ -f "$dst_xsessionrc" ] && grep -q 'GLFW_IM_MODULE=ibus' "$dst_xsessionrc"; then
    ok "方式二 .xsessionrc: 含 GLFW_IM_MODULE=ibus"
  else
    warn "方式二 .xsessionrc: 缺失或无 GLFW_IM_MODULE ($dst_xsessionrc)"
  fi

  # fcitx5 自启
  if [ -f "$dst_autostart" ]; then
    ok "fcitx5 自启: $dst_autostart"
  else
    warn "fcitx5 自启: 缺失 ($dst_autostart)"
  fi

  # fcitx5 安装/运行
  if command -v fcitx5 &>/dev/null; then
    ok "fcitx5 已安装: $(command -v fcitx5)"
  else
    warn "fcitx5 未安装"
  fi
  if pgrep -x fcitx5 &>/dev/null; then
    ok "fcitx5 进程运行中"
  else
    info "fcitx5 未运行（重登后自启；或手动 fcitx5 -d &）"
  fi

  # kitty 进程 environ（若在跑）
  local kpid
  kpid=$(pidof kitty 2>/dev/null | awk '{print $1}' || true)
  if [ -n "$kpid" ]; then
    local glfw
    glfw=$(tr '\0' '\n' < "/proc/$kpid/environ" 2>/dev/null | grep '^GLFW_IM_MODULE=' || true)
    if [ -n "$glfw" ]; then
      ok "kitty(pid=$kpid) environ: $glfw"
    else
      warn "kitty(pid=$kpid) environ: GLFW_IM_MODULE 为空（修复前启动的 kitty，关掉重开即生效）"
    fi
  else
    info "kitty 未运行"
  fi

  echo ""
  echo "--------------------------------------------"
  echo "下一步："
  echo "  1. 关掉所有 kitty 窗口，从 xfce4-panel 重开 -> 方式一立即生效"
  echo "  2. 重连 xrdp 会话 -> 方式二 + fcitx5 自启生效"
  echo "  3. kitty 里 Ctrl+Space 切换 fcitx5 验证中文输入"
  echo "--------------------------------------------"
}

# ==============================================================================
# 主流程
# ==============================================================================
OS="$(detect_os)"
case "$OS" in
  macos)
    warn "macOS 不支持 fcitx5（macOS 用系统输入法）。退出。"
    exit 0
    ;;
  unknown)
    error "不支持的系统"
    exit 1
    ;;
esac

resolve_user

if [ -n "${XDG_SESSION_TYPE:-}" ] && [ "$XDG_SESSION_TYPE" != "x11" ]; then
  info "检测到 XDG_SESSION_TYPE=$XDG_SESSION_TYPE（本脚本面向 X11；Wayland 下 fcitx5 由 start_sway.sh 管理，.xsessionrc 部署无害）"
fi

info "目标用户: $REAL_USER  家目录: $REAL_HOME  系统: $OS"
echo ""

install_fcitx5_packages
deploy_desktop_override
deploy_xsessionrc
deploy_fcitx5_autostart
configure_im_framework
verify
