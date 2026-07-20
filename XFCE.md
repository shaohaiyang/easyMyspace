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

### 中文输入法不工作 / 重启后输入法配置丢失

**典型症状**：重启或重连后无法切换出中文输入法，之前配置过的 fcitx5 似乎"还原"了。

**根因**：fcitx5 进程未随会话启动 + 输入法环境变量未持久化。注意 fcitx5 自身的输入法列表（拼音/五笔等）保存在 `~/.config/fcitx5/profile/defaultprofile`，通常不会丢；丢的是「让程序知道用 fcitx」的环境变量和「让 fcitx5 跑起来」的自启条目。

**诊断**：
```bash
# 1. fcitx5 是否在运行（最常见失败点：根本没启动）
pgrep -a fcitx5

# 2. 环境变量是否持久化（Debian X 会话会 source ~/.xsessionrc）
grep IM_MODULE ~/.xsessionrc 2>/dev/null
# 或查看当前会话实际值
echo "GTK=$GTK_IM_MODULE QT=$QT_IM_MODULE XMOD=$XMODIFIERS"

# 3. 自启条目是否存在
ls ~/.config/autostart/fcitx5.desktop 2>/dev/null || echo "缺失！"

# 4. im-config 是否指向 fcitx5
im-config -m 2>/dev/null

# 5. 输入法列表是否还在（确认 profile 没丢，丢的是上面的环境/自启）
cat ~/.config/fcitx5/profile/defaultprofile 2>/dev/null
```

**修复**：最省事的方式是重跑安装脚本（幂等，会自动备份旧文件）：
```bash
sudo bash configs/install_xfce.sh
```

或手动补齐两块缺失项：
```bash
# 1. 环境变量 -> ~/.xsessionrc
#    Debian 的 /etc/X11/Xsession.d/40x11-common_xsessionrc 会在会话启动前 source 它
#    （若用 GDM/LightDM 直接登录而非 xrdp，也可改用 ~/.xprofile，二者等价）
cat > ~/.xsessionrc << 'EOF'
export GTK_IM_MODULE=fcitx
export QT_IM_MODULE=fcitx
export XMODIFIERS="@im=fcitx"
export SDL_IM_MODULE=fcitx
export GLFW_IM_MODULE=ibus
EOF

# 2. 自启条目（fcitx5 默认未注册到 /etc/xdg/autostart）
mkdir -p ~/.config/autostart
cp /usr/share/applications/org.fcitx.Fcitx5.desktop ~/.config/autostart/

# 3. 声明系统输入法框架为 fcitx5
im-config -n fcitx5
```

改完**注销重登**即可生效（无需重启系统）。重登后验证：
```bash
echo $GTK_IM_MODULE     # 应输出 fcitx
pgrep -a fcitx5         # 应看到 fcitx5 进程
```
然后用 `Ctrl+Space` 切换输入法。

> kitty 下需 `GLFW_IM_MODULE=ibus`（已在 `.xsessionrc` 中设置，详见 [README - Kitty 输入法配置](README.md#kitty-输入法---fcitx5-配置)）

### kitty 进程没有 GLFW_IM_MODULE（验证命令返回空）

**典型症状**：`cat /proc/$(pidof kitty)/environ | tr '\0' '\n' | grep GLFW_IM_MODULE` 输出为空；kitty 里 Shift 切不出中文，但浏览器、VSCode 等其它应用切换正常。

**根因**：kitty 从 xfce4-panel 启动时继承的是 XFCE 会话环境，而该环境里没有 `GLFW_IM_MODULE`。最常见于**只跑了 `setup.sh`、没跑 `install_xfce.sh`**——`setup.sh` 装了 kitty 并部署 `kitty.conf`，但不会部署 `~/.xsessionrc`。结合 [README - Kitty 输入法配置](README.md#kitty-输入法---fcitx5-配置) 的三方式，关键认知：

- 方式三（`kitty.conf` 里 `env GLFW_IM_MODULE=ibus`）**只对 kitty 的子进程生效**，kitty 自身进程读不到——这是最常踩的坑。
- kitty 自身要拿到该变量，必须在**启动前**由方式一（`.desktop` 的 `Exec=env ...`）或方式二（`.xsessionrc` 的 `export`）注入。

**诊断**：
```bash
# 1. 当前会话类型（确认是 XFCE/x11，而非 Sway）
echo "$XDG_CURRENT_DESKTOP $XDG_SESSION_TYPE"

# 2. kitty 是怎么启动的——父进程链是否经过 xfce4-panel
pid=$(pidof kitty | awk '{print $1}')
ps -o pid,ppid,cmd -p "$pid"
ppid=$(awk '/^PPid:/{print $2}' /proc/$pid/status)
ps -o pid,cmd -p "$ppid"

# 3. 三种方式各部署了没
ls ~/.local/share/applications/kitty.desktop 2>/dev/null   # 方式一
grep GLFW_IM_MODULE ~/.xsessionrc 2>/dev/null              # 方式二
grep GLFW_IM_MODULE ~/.config/kitty/kitty.conf 2>/dev/null # 方式三（仅子进程）

# 4. 直接看 kitty 进程环境里有没有
cat /proc/$(pidof kitty)/environ 2>/dev/null | tr '\0' '\n' | grep GLFW_IM_MODULE
```

若 1 显示 XFCE、2 显示 kitty 由 xfce4-panel 启动、3 中方式一/二都缺失、4 为空——即本故障。

**修复**（A 即时 + B 彻底，建议都做）：

A. **即时**（README 推荐方式一）——部署用户级 `.desktop` 覆盖，让面板启动的 kitty 自带变量，**无需重登**：
```bash
mkdir -p ~/.local/share/applications
cp /usr/share/applications/kitty.desktop ~/.local/share/applications/
sed -i 's|^Exec=kitty$|Exec=env GLFW_IM_MODULE=ibus kitty|' ~/.local/share/applications/kitty.desktop
```
关掉所有旧 kitty 窗口，从面板重开即生效。

B. **彻底**——跑安装脚本部署 `.xsessionrc` + `.xsession` + fcitx5 自启：
```bash
sudo bash configs/install_xfce.sh
```
重连 xrdp 会话后，所有 X11 应用都拿到 `*_IM_MODULE` 变量 + fcitx5 开机自启。

**验证**：重开 kitty 后再跑一次诊断第 4 步，应输出 `GLFW_IM_MODULE=ibus`。

> 注：`install_xfce.sh` 部署的 `.xsessionrc`（方式二）在**重登后**已能让 kitty 拿到 `GLFW_IM_MODULE`，方式一（`.desktop`）只是免重登的即时补救。脚本目前未自动化方式一，需要即时生效时按上面 A 手动建一次即可。

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
