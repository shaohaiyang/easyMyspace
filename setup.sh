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

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="$SCRIPT_DIR/configs"

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
echo "  ║      easyMyspace — Setup & Config       ║"
echo "  ║     Catppuccin Mocha · Ctrl+Z Prefix    ║"
echo "  ╚══════════════════════════════════════════╝"
echo ""

# ==============================================================================
# Phase 1: 安装工具
# ==============================================================================
if $DO_TOOLS; then
  echo "━━━━━━━ Phase 1: 安装核心工具 ━━━━━━━"
  source "$CONFIG_DIR/install_tools.sh"

  OS=$(detect_os)
  info "检测到系统: $OS"

  if $DRY_RUN; then
    info "[DRY RUN] 跳过实际安装"
  else
    case "$OS" in
      macos) install_packages_macos ;;
      linux) install_packages_linux ;;
      *)     error "不支持的系统: $OS"; exit 1 ;;
    esac
    ensure_fonts
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
    "zed_settings.json"
    "zed_keymap.json"
    "yazi.toml"
    "lazygit.yml"
    "gitconfig"
    "opencode.json"
    "i3wm/config"
    "i3wm/polybar.ini"
    "i3wm/rofi.rasi"
  )
  CONFIG_DSTS=(
    "$HOME/.config/kitty/kitty.conf"
    "$HOME/.tmux.conf"
    "$HOME/.config/starship.toml"
    "$HOME/.config/zed/settings.json"
    "$HOME/.config/zed/keymap.json"
    "$HOME/.config/yazi/yazi.toml"
    "$HOME/.config/lazygit/config.yml"
    "$HOME/.gitconfig"
    "$HOME/.config/opencode/opencode.json"
    "$HOME/.config/i3/config"
    "$HOME/.config/polybar/config.ini"
    "$HOME/.config/rofi/config.rasi"
  )

  # Zshrc 注入标记
  ZSHRC_MARKER_START="# >>> easyMyspace injected >>>"
  ZSHRC_MARKER_END="# <<< easyMyspace injected <<<"

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

  # --- 注入 .zshrc ---
  ZSHRC_SRC="$CONFIG_DIR/zshrc.sh"
  ALIAS_SRC="$CONFIG_DIR/aliases.sh"
  ZSHRC_DST="$HOME/.zshrc"

  if $DRY_RUN; then
    info "[DRY RUN] 将注入 zshrc.sh + aliases.sh → $ZSHRC_DST"
  else
    if [ -f "$ZSHRC_DST" ]; then
      # 先备份
      cp "$ZSHRC_DST" "$ZSHRC_DST.bak.$(date +%Y%m%d%H%M%S)"

      # 检查是否已注入，如果是则先移除旧注入
      if grep -q "$ZSHRC_MARKER_START" "$ZSHRC_DST" 2>/dev/null; then
        info "检测到旧注入，正在更新..."
        # 使用 sed 移除旧的注入块
        if [[ "$(uname -s)" == "Darwin" ]]; then
          sed -i '' "/$ZSHRC_MARKER_START/,/$ZSHRC_MARKER_END/d" "$ZSHRC_DST"
        else
          sed -i "/$ZSHRC_MARKER_START/,/$ZSHRC_MARKER_END/d" "$ZSHRC_DST"
        fi
        ok "已移除旧注入块"
      fi

      # 追加新的注入块
      {
        echo ""
        echo "$ZSHRC_MARKER_START"
        echo "# 由 easyMyspace/setup.sh 自动生成 — $(date +%Y-%m-%d)"
        echo ""
        cat "$ZSHRC_SRC"
        echo ""
        cat "$ALIAS_SRC"
        echo ""
        echo "$ZSHRC_MARKER_END"
      } >> "$ZSHRC_DST"
      ok "已注入 zsh 增强配置 → $ZSHRC_DST"
    else
      warn "$ZSHRC_DST 不存在，跳过注入"
    fi
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
  echo "  • Shell:  source ~/.zshrc"
  echo "  • Kitty:  重新打开 Kitty 终端"
  echo "  • Tmux:   运行 tmux，然后按 Prefix + I 安装插件"
  echo "  • i3wm:   按 Mod+Shift+R 重新加载（Linux）"
  echo ""
  echo "  Catppuccin Mocha 主题已统一部署至："
  echo "    Kitty · Tmux · Starship · Zed · Yazi"
  echo "    Lazygit · Git Delta · i3wm · Polybar · Rofi"
  echo ""
  echo "  💡 需要帮助？查看 configs/ 下的说明注释"
fi
echo ""
