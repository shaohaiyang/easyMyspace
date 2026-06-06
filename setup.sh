#!/usr/bin/env bash
# ==============================================================================
# easyMyspace — 一键安装 & 配置脚本
# 用法:
#   ./setup.sh           完整安装 + 配置
#   ./setup.sh --dry-run 只预览，不做任何修改
#   ./setup.sh --tools   只安装工具，不部署配置
#   ./setup.sh --config  只部署配置，不安装工具
# ==============================================================================
set -euo pipefail

REPO_URL="https://github.com/shaohaiyang/easyMyspace.git"
REPO_BRANCH="main"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="$SCRIPT_DIR/configs"

# 如果 configs/ 不存在（pipe 模式），自动 clone 到临时目录
if [ ! -d "$CONFIG_DIR" ]; then
  TMP_DIR="/tmp/easyMyspace-$$"
  echo ""
  echo "  ╔══════════════════════════════════════════╗"
  echo "  ║   Detected piped execution               ║"
  echo "  ║   Cloning repo to $TMP_DIR               ║"
  echo "  ╚══════════════════════════════════════════╝"
  echo ""
  git clone --depth 1 --branch "$REPO_BRANCH" "$REPO_URL" "$TMP_DIR"
  exec "$TMP_DIR/setup.sh" "$@"
fi

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'
info()  { printf "${CYAN}[INFO]${NC}  %s\n" "$*"; }
ok()    { printf "${GREEN}[OK]${NC}    %s\n" "$*"; }
warn()  { printf "${YELLOW}[WARN]${NC}  %s\n" "$*"; }
error() { printf "${RED}[ERROR]${NC} %s\n" "$*"; }

# --- 解析参数 ---
DRY_RUN=false
DO_TOOLS=true
DO_CONFIG=true

for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=true ;;
    --tools)   DO_CONFIG=false ;;
    --config)  DO_TOOLS=false ;;
    --help|-h)
      echo "用法: ./setup.sh [--dry-run] [--tools] [--config]"
      echo "  --dry-run  预览操作，不执行"
      echo "  --tools    仅安装工具"
      echo "  --config   仅部署配置"
      exit 0
      ;;
  esac
done

# --- Header ---
echo ""
echo "  ╔══════════════════════════════════════════╗"
echo "  ║      easyMyspace — Setup & Config        ║"
echo "  ║     Catppuccin Mocha · Ctrl+Z Prefix     ║"
echo "  ╚══════════════════════════════════════════╝"
echo ""

if [ "$EUID" -ne 0 ]; then
  if ! sudo -n true 2>/dev/null && ! sudo -v 2>/dev/null; then
    error "当前用户没有 sudo 权限，无法执行安装"
    echo ""
    echo "  请先以 root 身份将当前用户加入 sudoers："
    echo "    usermod -aG sudo $USER   # Debian/Ubuntu"
    echo "    usermod -aG wheel $USER  # RHEL/Fedora"
    echo ""
    echo "  加入 sudo 组后，需要重新登录（logout 再 login）才能生效"
    echo ""
    echo "  或者直接以 root 运行："
    echo "    sudo ./setup.sh"
    echo ""
    exit 1
  fi
fi
# ==============================================================================
# 前置检查：curl
# ==============================================================================
if ! command -v curl &>/dev/null; then
  error "curl 未找到，无法继续安装"
  echo ""
  echo "  请先安装 curl："
  echo "    macOS:   brew install curl"
  echo "    Debian:  sudo apt install curl"
  echo "    RHEL:    sudo dnf install curl"
  echo ""
  exit 1
fi

# ==============================================================================
# Phase 1: 安装工具
# ==============================================================================
if $DO_TOOLS; then
  echo "━━━━━━━ Phase 1: 安装核心工具 ━━━━━━━"
  source "$CONFIG_DIR/install_tools.sh"

  if $DRY_RUN; then
    info "[DRY RUN] 跳过实际安装"
  else
    install_packages
    ensure_fonts
  fi
fi

# ==============================================================================
# Phase 1.5: 安装 Sway 桌面环境（仅 Linux）
# ==============================================================================
if $DO_TOOLS && [[ "$(uname -s)" != "Darwin" ]] && [ -f "$CONFIG_DIR/install_sway.sh" ]; then
  echo ""
  echo "━━━━━━━ Phase 1.5: 安装 Sway 桌面环境 ━━━━━━━"

  if $DRY_RUN; then
    info "[DRY RUN] 将执行: bash $CONFIG_DIR/install_sway.sh"
  else
    bash "$CONFIG_DIR/install_sway.sh"
  fi
fi

# ==============================================================================
# Phase 2: 部署配置文件
# ==============================================================================
if $DO_CONFIG; then
  echo ""
  echo "━━━━━━━ Phase 2: 部署配置文件 ━━━━━━━"

  # 配置文件映射: 使用两个平行数组（兼容 bash 3）
  CONFIG_SRCS=(
    "kitty.conf"
    "tmux.conf"
    "starship.toml"
    "yazi.toml"
    "theme.toml"
    "lazygit.yml"
    "gitconfig"
    "opencode.json"
    "sync-omp-providers.sh"
    "sway/config"
    "sway/start_sway.sh"
    "sway/waybar/config.jsonc"
    "sway/waybar/style.css"
    "sway/wofi/style.css"
    "sway/mako/config"
  )
  CONFIG_DSTS=(
    "$HOME/.config/kitty/kitty.conf"
    "$HOME/.tmux.conf"
    "$HOME/.config/starship.toml"
    "$HOME/.config/yazi/yazi.toml"
    "$HOME/.config/yazi/theme.toml"
    "$HOME/.config/lazygit/config.yml"
    "$HOME/.gitconfig"
    "$HOME/.config/opencode/opencode.json"
    "$HOME/.local/bin/sync-omp-providers"
    "$HOME/.config/sway/config"
    "$HOME/.local/bin/start-sway"
    "$HOME/.config/waybar/config.jsonc"
    "$HOME/.config/waybar/style.css"
    "$HOME/.config/wofi/style.css"
    "$HOME/.config/mako/config"
  )

  for i in "${!CONFIG_SRCS[@]}"; do
    src_rel="${CONFIG_SRCS[$i]}"
    src="$CONFIG_DIR/$src_rel"
    dst="${CONFIG_DSTS[$i]}"
    dst_dir=$(dirname "$dst")

    if [ ! -f "$src" ]; then
      warn "源文件不存在: $src，跳过"
      continue
    fi

    if $DRY_RUN; then
      info "[DRY RUN] 将部署: $src → $dst"
      continue
    fi

    # 创建目标目录
    mkdir -p "$dst_dir"

    # 备份已有配置
    if [ -f "$dst" ]; then
      bak="$dst.bak.$(date +%Y%m%d%H%M%S)"
      cp "$dst" "$bak"
      info "已备份: $dst → $bak"
    fi

    # 复制新配置
    cp "$src" "$dst"
    ok "部署: $src_rel → $dst"
  done

  # --- 部署 Kitty kittens ---
  KITTY_KITTEN_SRC="$CONFIG_DIR/kittens"
  KITTY_KITTEN_DST="$HOME/.config/kitty/kittens"
  if [ -d "$KITTY_KITTEN_SRC" ]; then
    if $DRY_RUN; then
      info "[DRY RUN] 将部署 kittens: $KITTY_KITTEN_SRC → $KITTY_KITTEN_DST"
    else
      mkdir -p "$KITTY_KITTEN_DST"
      cp -r "$KITTY_KITTEN_SRC"/* "$KITTY_KITTEN_DST"/
      chmod +x "$KITTY_KITTEN_DST"/*.py 2>/dev/null || true
      ok "部署: kittens → $KITTY_KITTEN_DST"
    fi
  fi

  if ! $DRY_RUN; then
    start_sway_dst="$HOME/.local/bin/start-sway"
    if [ -f "$start_sway_dst" ]; then
      chmod +x "$start_sway_dst"
      ok "添加执行权限: start-sway"
    fi
    sync_omp_dst="$HOME/.local/bin/sync-omp-providers"
    if [ -f "$sync_omp_dst" ]; then
      chmod +x "$sync_omp_dst"
      ok "添加执行权限: sync-omp-providers"
    fi
  fi

  # --- shell 配置注入 ---
  if ! $DRY_RUN; then
    MARKER_START="# >>> easyMyspace injected >>>"
    MARKER_END="# <<< easyMyspace injected <<<"

    if [[ "$(uname -s)" == "Darwin" ]]; then
      RC_SRC="$CONFIG_DIR/zshrc.sh"
      ALIAS_SRC="$CONFIG_DIR/aliases.sh"
      RC_DST="$HOME/.zshrc"
    else
      RC_SRC="$CONFIG_DIR/bashrc.sh"
      RC_DST="$HOME/.bashrc"
    fi

    [ -f "$RC_DST" ] && cp "$RC_DST" "$RC_DST.bak.$(date +%Y%m%d%H%M%S)"

    if grep -q "$MARKER_START" "$RC_DST" 2>/dev/null; then
      if [[ "$(uname -s)" == "Darwin" ]]; then
        sed -i '' "/$MARKER_START/,/$MARKER_END/d" "$RC_DST"
      else
        sed -i "/$MARKER_START/,/$MARKER_END/d" "$RC_DST"
      fi
      ok "已移除旧注入块"
    fi

    {
      echo ""
      echo "$MARKER_START"
      echo "# 由 easyMyspace/setup.sh 自动生成 — $(date +%Y-%m-%d)"
      echo ""
      if [[ "$(uname -s)" == "Darwin" ]]; then
        cat "$RC_SRC" "$ALIAS_SRC"
      else
        cat "$RC_SRC"
      fi
      echo ""
      echo "$MARKER_END"
    } >> "$RC_DST"
     ok "已注入配置 → $RC_DST"
  fi

fi

# ==============================================================================
# Phase 3: 完成提示
# ==============================================================================
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
if $DRY_RUN; then
  printf "${YELLOW}  DRY RUN 完成 — 未做任何修改${NC}\n"
  echo ""
  echo "  运行 ./setup.sh 来实际执行"
else
  printf "${GREEN}  ✨ 配置完成！${NC}\n"
  echo ""
  echo "  请执行以下操作使配置生效："
  echo ""
  if [[ "$(uname -s)" == "Darwin" ]]; then
    echo "  • Shell:  source ~/.zshrc"
  else
    echo "  • Shell:  source ~/.bashrc"
  fi
  echo "  • Kitty:  重新打开 Kitty 终端"
  echo "  • Tmux:   运行 tmux，然后按 Prefix + I 安装插件"
  echo "  • Sway:   在 TTY 中执行 start-sway 启动（Linux）"
  echo "  • Oh-my-Pi: 运行 sync-omp-providers 同步 AI provider 配置"
  echo ""
  echo "  Catppuccin Mocha 主题已统一部署至："
  echo "    Kitty · Tmux · Starship · Zed · Yazi"
  echo "    Lazygit · Git Delta · Sway · Waybar · Wofi"
  echo ""
   echo "  💡 需要帮助？查看 configs/ 下的说明注释"
fi
echo ""
