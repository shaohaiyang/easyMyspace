#!/usr/bin/env bash
# Waybar 自定义模块 — 显示当前 fcitx5 输入法
exec 2>/dev/null

command -v fcitx5-remote &>/dev/null || { echo ""; exit 0; }

name=$(fcitx5-remote -n) || { echo ""; exit 0; }

case "$name" in
  keyboard-us|keyboard-us-intl) echo 'US'   ;;
  pinyin)                       echo '拼'   ;;
  wubi*|wbx*)                   echo '五'   ;;
  *)                            echo "$name" ;;
esac
