#!/usr/bin/env bash
# ==============================================================================
# 启动 Sway 会话（在 TTY 中运行）
# 用法: ./start_sway.sh
# ==============================================================================
set -e

# Wayland 环境变量
export XDG_SESSION_TYPE=wayland
export XDG_CURRENT_DESKTOP=sway
export XDG_SESSION_DESKTOP=sway
export WLR_NO_HARDWARE_CURSORS=1

# GTK/Qt 强制走 Wayland 后端
export GDK_BACKEND=wayland
export QT_QPA_PLATFORM=wayland
export SDL_VIDEODRIVER=wayland
export CLUTTER_BACKEND=wayland
export _JAVA_AWT_WM_NONREPARENTING=1

# 输入法 (fcitx5)
export GTK_IM_MODULE=fcitx
export QT_IM_MODULE=fcitx
export SDL_IM_MODULE=fcitx
export XMODIFIERS="@im=fcitx"
export GLFW_IM_MODULE=ibus
exec sway "$@"
