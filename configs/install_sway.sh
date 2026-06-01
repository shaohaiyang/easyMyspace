#!/usr/bin/env bash
# ==============================================================================
# install_sway.sh — 跨平台 Sway 桌面环境安装脚本（Debian / RHEL）
# 用法:
#   sudo bash install_sway.sh           完整安装
#   sudo bash install_sway.sh --minimal  仅核心组件
# ==============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'
info()  { printf "${CYAN}[INFO]${NC}  %s\n" "$*"; }
ok()    { printf "${GREEN}[OK]${NC}    %s\n" "$*"; }
warn()  { printf "${YELLOW}[WARN]${NC}  %s\n" "$*"; }

MINIMAL=false
[[ "${1:-}" == "--minimal" ]] && MINIMAL=true

# ==============================================================================
# OS 检测
# ==============================================================================
detect_os() {
  if [ -f /etc/os-release ]; then
    . /etc/os-release
    case "$(echo "$ID" | tr '[:upper:]' '[:lower:]')" in
      debian|devuan|ubuntu|linuxmint|pop|elementary|zorin|kali) echo "debian" ;;
      rhel|centos|almalinux|rocky|fedora|ol)            echo "redhat" ;;
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
  echo "不支持的系统" >&2
  exit 1
fi

# ==============================================================================
# 包管理器 & 包名映射
# ==============================================================================
case "$OS" in
  debian)
    ENABLE_REPO=""
    UPDATE_CMD="apt update -qq"
    INSTALL_CMD="apt install -y"

    # Debian 系包名（不含跨发行版有差异的系统包）
    core_pkgs=(
      sway swaybg swayidle swaylock
      waybar wofi mako-notifier wl-clipboard wlr-randr
      kitty foot
      fonts-noto fonts-noto-cjk fonts-noto-color-emoji fonts-liberation
      xwayland
    )

    optional_pkgs=(
      grim slurp wf-recorder
      pipewire pipewire-pulse wireplumber pavucontrol
      brightnessctl
      network-manager-gnome
      thunar thunar-archive-plugin thunar-volman file-roller gvfs
      imv mpv
      gammastep
      upower lxappearance mousepad viewnior
    )
    ;;

  redhat)
    ENABLE_REPO="dnf install -y epel-release"
    UPDATE_CMD="dnf check-update -qq || true"
    INSTALL_CMD="dnf install -y"

    core_pkgs=(
      sway swaybg swayidle sway-lock
      waybar wofi wl-clipboard mako wlr-randr
      kitty foot
      google-noto-fonts google-noto-cjk-fonts
      google-noto-emoji-fonts liberation-fonts
      xwayland systemd dbus
    )

    optional_pkgs=(
      grim slurp wf-recorder
      pipewire pipewire-pulse wireplumber pavucontrol
      brightnessctl
      network-manager-gnome
      thunar thunar-archive-plugin thunar-volman file-roller gvfs
      imv mpv
      gammastep
      upower lxappearance mousepad viewnior
    )
    ;;
esac

# ==============================================================================
# 安装
# ==============================================================================
if [ "$EUID" -eq 0 ]; then
  SUDO=""
else
  SUDO="sudo"
fi

if [ -n "$ENABLE_REPO" ]; then
  info "启用仓库..."
  $SUDO $ENABLE_REPO &>/dev/null || true
fi

info "更新包索引..."
$SUDO $UPDATE_CMD

info "安装核心组件..."
$SUDO $INSTALL_CMD "${core_pkgs[@]}"

if ! $MINIMAL; then
  info "安装可选组件..."
  for pkg in "${optional_pkgs[@]}"; do
    if $SUDO $INSTALL_CMD "$pkg" &>/dev/null 2>&1; then
      ok "  $pkg 安装成功"
    else
      warn "  $pkg 安装失败（可能不在仓库中）"
    fi
  done
fi

# ==============================================================================
# 确定真实用户（处理 sudo 场景）
# ==============================================================================
if [ "$EUID" -eq 0 ] && [ -n "${SUDO_USER:-}" ]; then
  REAL_HOME="$(getent passwd "$SUDO_USER" | cut -d: -f6)"
  REAL_USER="$SUDO_USER"
else
  REAL_HOME="$HOME"
  REAL_USER="$USER"
fi

# ==============================================================================
# JetBrains Mono Nerd Font
# ==============================================================================
fd="$REAL_HOME/.local/share/fonts"
mkdir -p "$fd"

if [ "$EUID" -eq 0 ] && [ -n "${SUDO_USER:-}" ]; then
  chown "$REAL_USER:" "$fd"
fi

if ls "$fd"/JetBrains* &>/dev/null 2>&1; then
  ok "JetBrains Mono Nerd Font 已存在"
elif fc-list | grep -qi "JetBrainsMonoNLNerd" &>/dev/null 2>&1; then
  ok "JetBrains Mono Nerd Font 已存在（系统级）"
else
  info "下载 JetBrains Mono Nerd Font..."
  url="https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip"
  wget -q "$url" -O /tmp/jetbrains.zip \
    && unzip -q /tmp/jetbrains.zip -d "$fd" \
    && fc-cache -fv "$fd" \
    && ok "JetBrains Mono Nerd Font 安装完成" \
    || warn "字体安装失败，请手动下载: $url"
fi

# ==============================================================================
# 用户组
# ==============================================================================
for grp in video input; do
  if groups "$REAL_USER" | grep -qw "$grp"; then
    ok "用户 $REAL_USER 已在 $grp 组"
  else
    $SUDO usermod -aG "$grp" "$REAL_USER"
    ok "已将 $REAL_USER 加入 $grp 组（需重新登录生效）"
  fi
done

# ==============================================================================
# 部署配置文件 & start-sway 启动脚本
# ==============================================================================

CONFIG_SRC="$SCRIPT_DIR/sway"

declare -A CONFIG_MAP=(
  ["config"]="$REAL_HOME/.config/sway/config"
  ["start_sway.sh"]="/usr/local/bin/start-sway"
  ["waybar/config.jsonc"]="$REAL_HOME/.config/waybar/config.jsonc"
  ["waybar/style.css"]="$REAL_HOME/.config/waybar/style.css"
  ["wofi/style.css"]="$REAL_HOME/.config/wofi/style.css"
  ["mako/config"]="$REAL_HOME/.config/mako/config"
)

for src_rel in "${!CONFIG_MAP[@]}"; do
  src="$CONFIG_SRC/$src_rel"
  dst="${CONFIG_MAP[$src_rel]}"
  if [ ! -f "$src" ]; then
    warn "配置文件不存在: $src"
    continue
  fi
  mkdir -p "$(dirname "$dst")"
  cp "$src" "$dst"
  if [ "$EUID" -eq 0 ] && [ -n "${SUDO_USER:-}" ]; then
    chown "$REAL_USER:" "$dst"
  fi
  ok "已部署: $src_rel → $dst"
done

# start-sway 添加执行权限
if [ -f "/usr/local/bin/start-sway" ]; then
  chmod +x "/usr/local/bin/start-sway"
  ok "添加执行权限: /usr/local/bin/start-sway"
fi

# ==============================================================================
# 完成提示
# ==============================================================================
echo ""
echo "============================================"
printf "${GREEN}  Sway 桌面环境安装完成！${NC}\n"
echo "============================================"
echo ""
echo "  启动 Sway（在 TTY 中执行）："
echo "    start-sway"
echo ""
echo "  或手动执行："
echo "    export XDG_SESSION_TYPE=wayland"
echo "    export XDG_CURRENT_DESKTOP=sway"
echo "    exec sway"
echo ""
echo "  快捷键："
echo "    Mod+Return  打开 Kitty 终端"
echo "    Mod+Space   Wofi 应用启动器"
echo "    Mod+Shift+q 关闭窗口"
echo "    Mod+f       切换全屏"
echo "    Mod+Shift+r 重载 Sway 配置"
echo ""
echo "  需要重新登录以使用户组权限生效"
echo ""
