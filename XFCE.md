# XFCE + xrdp 远程桌面

无显示器服务器上通过 RDP 远程访问 XFCE 桌面的一键安装方案。属于 easyMyspace 的可选模块，与 [Sway](README.md) 桌面二选一。

## 背景与选型

easyMyspace 默认桌面是 **Sway（Wayland）**，适合有物理显示器的本地机器。但在**无头云服务器**上通过 RDP 远程访问时，Sway 会遇到根本性问题：

- xrdp 提供的是 **X11 会话**（`Xorg :10`），不是 Wayland
- 任何 Wayland 合成器（sway / weston / labwc）跑在 xrdp 的 X 会话里，都会被 wlroots **自动回退到 X11 后端**，变成嵌套在 RDP 桌面里的一个小窗口（输出名 `X11-1`），无法接管整个 RDP 屏幕
- 即使 `nvidia-drm` 开启 modeset，无物理显示器的算力卡（如 RTX 4090）也无法作为 DRM 输出

因此无头服务器远程桌面的正确选择是 **XFCE on X11 via xrdp**：xrdp 的 Xorg 直接作为 X server，XFCE 作为其会话，RDP 客户端连进来就是完整的 XFCE 桌面。本仓库仍保留 Sway 配置，供本地有显示器的机器使用。

## 前置要求

- Debian/Ubuntu/Devuan 或 RHEL/CentOS/Alma/Rocky/Fedora
- root 或 sudo 权限
- 已通过 `setup.sh` 安装基础工具（含 **kitty**，将作为 XFCE 默认终端）
- 网络可达发行版官方仓库（RHEL 系需 EPEL）

## 一键安装

```bash
# 完整安装（XFCE + xrdp），适用于无头服务器
sudo bash configs/install_xfce.sh

# 仅装 XFCE，不装 xrdp（本地有显示器、用显示管理器登录时）
sudo bash configs/install_xfce.sh --no-xrdp

# 已有其他桌面环境，强制安装
sudo bash configs/install_xfce.sh --force
```

脚本幂等：若 XFCE 已装，再次运行只刷新配置文件（自动备份旧文件为 `*.bak.时间戳`）。

## 脚本做了什么

| 步骤 | 说明 |
|------|------|
| **OS 检测** | 识别 Debian/Redhat 系，选择对应包名 |
| **DE 检测** | XFCE 已装则跳过装包；其他 DE 已装则需 `--force` |
| **装包** | Debian：`xfce4 xfce4-goodies dbus-x11`；RHEL：`xfce4-session xfwm4 xfdesktop ...`（走 EPEL） |
| **xrdp** | 默认一并安装并 `systemctl enable --now xrdp`，`--no-xrdp` 跳过 |
| **用户组** | 将当前用户加入 `ssl-cert` 组（xrdp 访问 TLS 证书，需重新登录生效） |
| **默认终端** | 通过 `update-alternatives` 把 `x-terminal-emulator` 指向 kitty；无此机制时回退写 XFCE `helpers.rc` |
| **会话入口** | 部署 `~/.xsession` → `exec startxfce4`，xrdp 新会话自动进 XFCE |
| **环境变量** | 部署 `~/.xsessionrc`，强制 X11 后端 + fcitx5 输入法变量 |
| **输入法自启** | 部署 `~/.config/autostart/fcitx5.desktop`，XFCE 会话自启 fcitx5 |

### 配置文件映射

| 源文件 | 目标 |
|--------|------|
| `configs/xfce/xsession` | `~/.xsession` |
| `configs/xfce/xsessionrc` | `~/.xsessionrc` |
| `configs/xfce/autostart/fcitx5.desktop` | `~/.config/autostart/fcitx5.desktop` |

## 手动步骤复现

以下是我们实际在 Debian 13 服务器上从 Sway 切到 XFCE 执行的命令，供参考与排障：

```bash
# 1. 安装 XFCE + dbus-x11（提供 dbus-launch）
apt install -y xfce4 xfce4-goodies dbus-x11

# 2. 会话入口（xrdp 新会话读 ~/.xsession）
cat > ~/.xsession << 'EOF'
#!/bin/sh
exec startxfce4
EOF
chmod +x ~/.xsession

# 3. X11 后端 + fcitx5 输入法环境变量
cat > ~/.xsessionrc << 'EOF'
unset GDK_BACKEND QT_QPA_PLATFORM SDL_VIDEODRIVER CLUTTER_BACKEND
export GDK_BACKEND=x11
export QT_QPA_PLATFORM=xcb
export GTK_IM_MODULE=fcitx
export QT_IM_MODULE=fcitx
export XMODIFIERS="@im=fcitx"
export SDL_IM_MODULE=fcitx
export GLFW_IM_MODULE=ibus
EOF

# 4. XFCE 自启 fcitx5（fcitx5 默认未注册到 /etc/xdg/autostart）
mkdir -p ~/.config/autostart
cat > ~/.config/autostart/fcitx5.desktop << 'EOF'
[Desktop Entry]
Type=Application
Name=Fcitx 5
Exec=fcitx5 -d
Icon=fcitx
Terminal=false
X-GNOME-Autostart-Phase=Applications
EOF

# 5. 默认终端设为 kitty
update-alternatives --set x-terminal-emulator /usr/bin/kitty

# 6. 结束旧 sway 会话（如有）
pkill -u "$USER" -f "sway|swaybg|swaybar" || true
```

## 连接方式

1. 确认 xrdp 在监听：`ss -tlnp | grep 3389`
2. 用 RDP 客户端（Windows 远程桌面 / macOS Microsoft Remote Desktop / Remmina）连接服务器 IP，端口 3389
3. 输入 Linux 用户名密码
4. **若之前用过 sway**：先彻底断开旧 RDP 会话再重连，新会话才会读取 `~/.xsession` 进入 XFCE

> xrdp 默认每个连接开新会话。若想复用会话，需配置 xrdp-sesman 的 `Session` 与端口，超出本脚本范围。

## 故障排查

### 重连后仍是黑屏 / 看不到桌面
- 确认 `~/.xsession` 存在且可执行：`ls -l ~/.xsession`
- 查看会话错误日志：`cat ~/.xsession-errors`
- 确认 `startxfce4` 已安装：`command -v startxfce4`（属于 `xfce4-session` 包）
- 确认 `dbus-x11` 已装（提供 `dbus-launch`，XFCE 启动依赖）

### 仍有 sway 窗口残留
```bash
pkill -u "$USER" -f "sway|swaybg|swaybar"
```
然后断开 RDP 重连。

### 中文输入法不工作
- 确认 fcitx5 进程在跑：`pgrep -a fcitx5`
- 确认环境变量已注入：`cat ~/.xsessionrc | grep IM_MODULE`
- kitty 下需 `GLFW_IM_MODULE=ibus`（已在 `.xsessionrc` 中设置，详见 [README - Kitty 输入法配置](README.md#kitty-输入法---fcitx5-配置)）

### 终端不是 kitty
```bash
update-alternatives --set x-terminal-emulator /usr/bin/kitty
# 或在 XFCE 里运行
exo-preferred-applications
```

### 字体显示异常
确保已通过 `setup.sh` 安装 JetBrainsMono Nerd Font 与 Noto CJK：
```bash
fc-list | grep -i "JetBrainsMono Nerd"
fc-list :lang=zh | head
```

### 为什么不用 XFCE on Wayland
XFCE 的 Wayland 支持仍不完整（4.20 起部分支持），且在 xrdp 的 X 会话里跑 Wayland 合成器会遇到与 sway 相同的嵌套问题。X11 是 xrdp 远程桌面的原生搭配，最稳定。
