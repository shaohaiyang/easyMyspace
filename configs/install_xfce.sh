#!/usr/bin/env bash
# ==============================================================================
# install_xfce.sh - XFCE4 + xrdp 远程桌面安装脚本（Debian / Devuan / RHEL）
# 适用场景：无显示器服务器，通过 RDP 远程访问桌面
# 用法:
#   sudo bash install_xfce.sh             完整安装（含 xrdp）
#   sudo bash install_xfce.sh --no-xrdp   仅装 XFCE，不装 xrdp（本地有显示器）
#   sudo bash install_xfce.sh --force     跳过已装 DE 检测，强制安装
# ==============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'
info()  { printf "${CYAN}[INFO]${NC}  %s\n" "$*"; }
ok()    { printf "${GREEN}[OK]${NC}    %s\n" "$*"; }
warn()  { printf "${YELLOW}[WARN]${NC}  %s\n" "$*"; }
error() { printf "${RED}[ERROR]${NC} %s\n" "$*"; }

FORCE=false
INSTALL_XRDP=true
for arg in "$@"; do
  case "$arg" in
    --force)    FORCE=true ;;
    --no-xrdp)  INSTALL_XRDP=false ;;
    --help|-h)
      echo "用法: sudo bash install_xfce.sh [--force] [--no-xrdp]"
      echo "  --force    跳过已装桌面环境检测，强制安装"
      echo "  --no-xrdp  不安装 xrdp（本地有显示器时使用）"
      exit 0
      ;;
  esac
done

# ==============================================================================
# OS 检测
# ==============================================================================
detect_os() {
  if [ -f /etc/os-release ]; then
    . /etc/os-release
    case "$(echo "$ID" | tr '[:upper:]' '[:lower:]')" in
      devuan)            echo "devuan" ;;
      debian|ubuntu|linuxmint|pop|elementary|zorin|kali) echo "debian" ;;
      rhel|centos|almalinux|rocky|fedora|ol)             echo "redhat" ;;
      *) echo "unknown" ;;
    esac
  elif [ -f /etc/debian_version ]; then
    echo "debian"
  elif [ -f /etc/redhat-release ]; then
    echo "redhat"
  else
    echo "unknown"
  fi
}

OS="$(detect_os)"
if [ "$OS" = "unknown" ]; then
  error "不支持的系统"
  exit 1
fi

# ==============================================================================
# 检测已安装的桌面环境
# ==============================================================================
xfce_already_installed() {
  if command -v dpkg &>/dev/null; then
    dpkg -l xfce4-session &>/dev/null 2>&1
  elif command -v rpm &>/dev/null; then
    rpm -q xfce4-session &>/dev/null 2>&1
  else
    command -v xfce4-session &>/dev/null
  fi
}

detect_existing_de() {
  local found=()

  local running=(
    "gnome-shell:GNOME"
    "plasmashell:KDE Plasma"
    "xfce4-session:Xfce"
    "cinnamon-session:Cinnamon"
    "budgie-wm:Budgie"
    "mate-session:MATE"
    "lxqt-session:LXQt"
    "lxsession:LXDE"
    "deepin-wm:Deepin"
    "ukui-session:UKUI"
  )
  for entry in "${running[@]}"; do
    local proc="${entry%%:*}" name="${entry##*:}"
    if pgrep -x "$proc" &>/dev/null 2>&1; then
      found+=("$name (正在运行)")
    fi
  done

  if command -v dpkg &>/dev/null; then
    local deb_pkgs=(
      "gnome-session:GNOME"
      "plasma-desktop:KDE Plasma"
      "xfce4-session:Xfce"
      "cinnamon-desktop-data:Cinnamon"
      "budgie-desktop:Budgie"
      "mate-desktop-environment:MATE"
      "lxde-core:LXDE"
      "lxqt-core:LXQt"
      "dde-desktop:Deepin"
    )
    for entry in "${deb_pkgs[@]}"; do
      local pkg="${entry%%:*}" name="${entry##*:}"
      if dpkg -l "$pkg" &>/dev/null 2>&1; then
        found+=("$name (已安装: $pkg)")
      fi
    done
  elif command -v rpm &>/dev/null; then
    local rpm_pkgs=(
      "gnome-session:GNOME"
      "plasma-desktop:KDE Plasma"
      "xfce4-session:Xfce"
      "cinnamon-desktop:Cinnamon"
      "budgie-desktop:Budgie"
      "mate-desktop:MATE"
      "lxde-common:LXDE"
      "lxqt:LXQt"
      "deepin-desktop:Deepin"
    )
    for entry in "${rpm_pkgs[@]}"; do
      local pkg="${entry%%:*}" name="${entry##*:}"
      if rpm -q "$pkg" &>/dev/null 2>&1; then
        found+=("$name (已安装: $pkg)")
      fi
    done
  fi

  if [ ${#found[@]} -gt 0 ]; then
    printf '%s\n' "${found[@]}" | sort -u
    return 0
  fi
  return 1
}

# ==============================================================================
# 装包决策：XFCE 已装则只刷新配置；其他 DE 已装则需 --force
# ==============================================================================
SKIP_PACKAGES=false
info "检测已安装的桌面环境..."
if xfce_already_installed; then
  ok "XFCE 已安装，跳过装包步骤，仅刷新配置"
  SKIP_PACKAGES=true
elif ! $FORCE && detected=$(detect_existing_de); then
  echo ""
  warn "========================================================"
  warn "  检测到已有桌面环境，跳过 XFCE 安装"
  warn "========================================================"
  echo ""
  while IFS= read -r line; do
    warn "  - $line"
  done <<< "$detected"
  echo ""
  info "如需强制安装，请使用 --force 参数："
  info "  sudo bash $0 --force"
  echo ""
  exit 0
else
  ok "未检测到现有桌面环境，继续安装 XFCE"
fi

# ==============================================================================
# SUDO & 真实用户
# ==============================================================================
SUDO=""
[ "$EUID" -ne 0 ] && SUDO="sudo"

if [ "$EUID" -eq 0 ] && [ -n "${SUDO_USER:-}" ]; then
  REAL_HOME="$(getent passwd "$SUDO_USER" | cut -d: -f6)"
  REAL_USER="$SUDO_USER"
else
  REAL_HOME="$HOME"
  REAL_USER="${USER:-$(whoami)}"
fi

# ==============================================================================
# 包管理器 & 包名映射
# ==============================================================================
ENABLE_REPO=""
case "$OS" in
  devuan|debian)
    UPDATE_CMD="apt update -qq"
    INSTALL_CMD="apt install -y"
    core_pkgs=(xfce4 xfce4-goodies dbus-x11)
    ;;
  redhat)
    ENABLE_REPO="dnf install -y epel-release"
    UPDATE_CMD="dnf check-update -qq || true"
    INSTALL_CMD="dnf install -y"
    core_pkgs=(xfce4-session xfce4-panel xfwm4 xfdesktop xfce4-terminal thunar xfce4-settings dbus-x11)
    ;;
esac

# ==============================================================================
# 安装
# ==============================================================================
if ! $SKIP_PACKAGES; then
  if [ -n "$ENABLE_REPO" ]; then
    info "启用 EPEL 仓库..."
    $SUDO $ENABLE_REPO &>/dev/null || true
  fi

  info "更新包索引..."
  $SUDO $UPDATE_CMD

  info "安装 XFCE 核心组件..."
  $SUDO $INSTALL_CMD "${core_pkgs[@]}"
fi

# xrdp 独立处理：即使 XFCE 已装，缺 xrdp 时也补装
if $INSTALL_XRDP; then
  if ! command -v xrdp &>/dev/null; then
    info "安装 xrdp..."
    $SUDO $INSTALL_CMD xrdp
  else
    ok "xrdp 已安装"
  fi
fi

# ==============================================================================
# xrdp 服务 & 用户组
# ==============================================================================
if $INSTALL_XRDP; then
  if command -v systemctl &>/dev/null; then
    systemctl enable --now xrdp 2>/dev/null && ok "xrdp 已启用并启动" || warn "xrdp 启用失败（请检查是否已安装）"
  fi

  # 加入 ssl-cert 组（xrdp 访问 TLS 证书）
  if getent group ssl-cert &>/dev/null; then
    if id "$REAL_USER" | grep -qw ssl-cert; then
      ok "用户 $REAL_USER 已在 ssl-cert 组"
    else
      $SUDO usermod -aG ssl-cert "$REAL_USER"
      ok "已将 $REAL_USER 加入 ssl-cert 组（需重新登录生效）"
    fi
  fi
fi

# ==============================================================================
# 默认终端设为 kitty
# ==============================================================================
set_default_terminal_kitty() {
  if ! command -v kitty &>/dev/null; then
    warn "kitty 未安装，跳过默认终端设置（请先运行 setup.sh 安装 kitty）"
    return
  fi

  # 优先用 Debian 的 x-terminal-emulator alternative 机制（XFCE helpers.rc 默认即走此机制）
  if command -v update-alternatives &>/dev/null && \
     update-alternatives --list x-terminal-emulator 2>/dev/null | grep -qx "/usr/bin/kitty"; then
    $SUDO update-alternatives --set x-terminal-emulator /usr/bin/kitty
    ok "默认终端已设为 kitty (x-terminal-emulator)"
  else
    # 回退：直接写 XFCE helpers.rc
    local helpers="$REAL_HOME/.config/xfce4/helpers.rc"
    mkdir -p "$(dirname "$helpers")"
    cat > "$helpers" << 'EOF'
TerminalEmulator=kitty
EOF
    if [ "$EUID" -eq 0 ] && [ -n "${REAL_USER:-}" ]; then
      chown "$REAL_USER:" "$helpers"
    fi
    ok "默认终端已写入 $helpers（如不生效请运行 exo-preferred-applications 手动设置）"
  fi
}
set_default_terminal_kitty

# ==============================================================================
# 部署配置文件
# ==============================================================================
CONFIG_SRC="$SCRIPT_DIR/xfce"

declare -A CONFIG_MAP=(
  ["xsession"]="$REAL_HOME/.xsession"
  ["xsessionrc"]="$REAL_HOME/.xsessionrc"
  ["autostart/fcitx5.desktop"]="$REAL_HOME/.config/autostart/fcitx5.desktop"
)

for src_rel in "${!CONFIG_MAP[@]}"; do
  src="$CONFIG_SRC/$src_rel"
  dst="${CONFIG_MAP[$src_rel]}"
  if [ ! -f "$src" ]; then
    warn "配置文件不存在: $src"
    continue
  fi
  mkdir -p "$(dirname "$dst")"

  # 备份已有配置
  if [ -f "$dst" ]; then
    bak="$dst.bak.$(date +%Y%m%d%H%M%S)"
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
  ok "已部署: $src_rel -> $dst"
done

# .xsession 添加执行权限
if [ -f "$REAL_HOME/.xsession" ]; then
  chmod 755 "$REAL_HOME/.xsession"
  ok "添加执行权限: .xsession"
fi

# ==============================================================================
# 完成提示
# ==============================================================================
echo ""
echo "============================================"
printf "${GREEN}  XFCE4 远程桌面安装完成！${NC}\n"
echo "============================================"
echo ""
if $INSTALL_XRDP; then
  echo "  连接方式：用 RDP 客户端连接本机 3389 端口"
  echo "  （已为用户 $REAL_USER 配置 XFCE 会话）"
  echo ""
  echo "  ⚠️  若之前用过 sway，请先结束旧 sway 会话再重连"
  echo "  ⚠️  加入 ssl-cert 组后需重新登录生效"
else
  echo "  启动：在显示管理器选择 XFCE 会话登录"
fi
echo ""
echo "  默认终端：kitty"
echo "  输入法：fcitx5（已配置 X11 自启）"
echo ""
