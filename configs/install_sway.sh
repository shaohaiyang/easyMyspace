#!/usr/bin/env bash
# ==============================================================================
# install_sway.sh — 跨平台 Sway 桌面环境安装脚本（Debian / Devuan / RHEL）
# 用法:
#   sudo bash install_sway.sh             完整安装
#   sudo bash install_sway.sh --minimal    仅核心组件
#   sudo bash install_sway.sh --force      跳过 DE 检测，强制安装
# ==============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'
info()  { printf "${CYAN}[INFO]${NC}  %s\n" "$*"; }
ok()    { printf "${GREEN}[OK]${NC}    %s\n" "$*"; }
warn()  { printf "${YELLOW}[WARN]${NC}  %s\n" "$*"; }

MINIMAL=false
FORCE=false
for arg in "$@"; do
  case "$arg" in
    --minimal) MINIMAL=true ;;
    --force)   FORCE=true ;;
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
  echo "不支持的系统" >&2
  exit 1
fi

# ==============================================================================
# Devuan 特殊处理：修复 sources.list（避免 Debian 镜像导致包版本冲突）
# ==============================================================================
is_devuan_sources_fixed() {
  [ -f /etc/apt/sources.list ] || return 1
  grep -q 'deb.devuan.org' /etc/apt/sources.list 2>/dev/null
}

fix_devuan_sources() {
  . /etc/os-release
  local codename="${VERSION_CODENAME:-}"
  [ -z "$codename" ] && codename="excalibur"

  info "检测到 Devuan 系统使用了非 Devuan 镜像，正在修复 sources.list..."
  local sources_bak="/etc/apt/sources.list.bak.$(date +%Y%m%d%H%M%S)"
  cp /etc/apt/sources.list "$sources_bak"
  cat > /etc/apt/sources.list << EOF
deb http://deb.devuan.org/merged ${codename} main
deb http://deb.devuan.org/merged ${codename}-updates main
deb http://deb.devuan.org/merged ${codename}-security main
EOF
  ok "sources.list 已修复（备份: $sources_bak）"
}

if [ "$OS" = "devuan" ] && ! is_devuan_sources_fixed; then
  fix_devuan_sources
fi

# ==============================================================================
# 检测已安装的桌面环境
# ==============================================================================
detect_existing_de() {
  local found=()

  # 1. 正在运行的桌面环境进程
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

  # 2. XDG_CURRENT_DESKTOP 环境变量
  if [ -n "${XDG_CURRENT_DESKTOP:-}" ] && [ "$XDG_CURRENT_DESKTOP" != "sway" ]; then
    found+=("${XDG_CURRENT_DESKTOP} (XDG_CURRENT_DESKTOP)")
  fi

  # 3. 包管理器检测已安装的 DE
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

  # 4. 非 sway 的会话文件
  for dir in "/usr/share/xsessions" "/usr/share/wayland-sessions"; do
    [ -d "$dir" ] || continue
    for f in "$dir"/*.desktop; do
      [ -f "$f" ] || continue
      local base
      base="$(basename "$f" .desktop)"
      [ "$base" = "sway" ] && continue
      found+=("${base^} (会话文件: $f)")
    done
  done

  if [ ${#found[@]} -gt 0 ]; then
    printf '%s\n' "${found[@]}" | sort -u
    return 0
  fi
  return 1
}

info "检测已安装的桌面环境..."
if ! $FORCE && detected=$(detect_existing_de); then
  echo ""
  warn "========================================================"
  warn "  检测到已有桌面环境，跳过 Sway 安装"
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
fi
ok "未检测到现有桌面环境，继续安装 Sway"

# ==============================================================================
# 前置检查：curl
# ==============================================================================
if ! command -v curl &>/dev/null; then
  warn "curl 未找到，无法继续安装"
  echo ""
  echo "  请先安装 curl："
  echo "    Debian:  sudo apt install curl"
  echo "    RHEL:    sudo dnf install curl"
  echo ""
  exit 1
fi

# ==============================================================================
# 包管理器 & 包名映射
# ==============================================================================
case "$OS" in
  devuan|debian)
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
      # 输入法
      fcitx5 fcitx5-chinese-addons fcitx5-table-wubi98-pinyin fcitx5-frontend-gtk3 fcitx5-frontend-gtk4 fcitx5-frontend-qt5
      # locale（neovim 等工具需要 UTF-8）
      locales
    )

    optional_pkgs=(
      grim slurp wf-recorder
      pipewire pipewire-pulse wireplumber pavucontrol
      brightnessctl
      network-manager-gnome
      thunar thunar-archive-plugin thunar-volman file-roller gvfs
      imv mpv
      gammastep
      upower lxappearance
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
      fcitx5 fcitx5-configtool
    )

    optional_pkgs=(
      grim slurp wf-recorder
      pipewire pipewire-pulse wireplumber pavucontrol
      brightnessctl
      network-manager-gnome
      thunar thunar-archive-plugin thunar-volman file-roller gvfs
      imv mpv
      gammastep
      upower lxappearance
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
   url="https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.tar.xz"
   curl -fsSL "$url" -o /tmp/jetbrains.tar.xz \
     && tar xf /tmp/jetbrains.tar.xz -C "$fd" \
     && fc-cache -fv "$fd" \
     && ok "JetBrains Mono Nerd Font 安装完成" \
     || warn "字体安装失败，请手动下载: $url"
fi

# ==============================================================================
# locale
# ==============================================================================
if command -v locale-gen &>/dev/null; then
  for loc in en_US.UTF-8 zh_CN.UTF-8; do
    if ! locale -a 2>/dev/null | grep -qi "^${loc%.*}"; then
      $SUDO sed -i "s/^#${loc}/$loc/" /etc/locale.gen 2>/dev/null || \
        echo "$loc UTF-8" >> /etc/locale.gen
      $SUDO locale-gen "$loc" &>/dev/null && ok "$loc locale 已生成" || warn "$loc locale 生成失败"
    else
      ok "$loc locale 已存在"
    fi
  done
else
  warn "locale-gen 不可用，跳过 locale 生成"
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
  ["fcitx5/config"]="$REAL_HOME/.config/fcitx5/config"
  ["fcitx5/profile/defaultprofile"]="$REAL_HOME/.config/fcitx5/profile/defaultprofile"
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
echo "    Mod+grave   fcitx5 输入法设置"
echo ""
echo "  需要重新登录以使用户组权限生效"
echo ""
