# install_kitty_fcitx5.sh 设计文档

**日期**: 2026-07-20
**状态**: 已批准（待实现）
**关联**: [README - Kitty 输入法配置](../../../README.md#kitty-输入法---fcitx5-配置) · [XFCE.md - kitty 进程没有 GLFW_IM_MODULE](../../../XFCE.md#kitty-进程没有-glfw_im_module验证命令返回空)

## 背景与问题

kitty 在 X11 下用 GLFW 作为输入后端，GLFW 只认 IBus 协议，因此 fcitx5 必须通过 `GLFW_IM_MODULE=ibus` 走 IBus 兼容层与 kitty 通信。该变量必须在 kitty **启动前**注入，`kitty.conf` 里的 `env` 只对子进程生效（救不了 kitty 自身）。

实际诊断发现：用户只跑了 `setup.sh`（装 kitty + 部署 `kitty.conf`），没跑 `install_xfce.sh`，导致 `~/.xsessionrc`、`~/.local/share/applications/kitty.desktop`、fcitx5 自启都缺失。从 xfce4-panel 启动的 kitty 进程 environ 中 `GLFW_IM_MODULE` 为空，中文输入法在 kitty 里失效。

仓库当前没有任何脚本自动化 README 标注「推荐」的**方式一**（`.desktop` 覆盖）。本脚本补齐这个缺口。

## 范围

### In scope
- 检测并补装 fcitx5 包（Debian/RHEL）
- 方式一：部署 `~/.local/share/applications/kitty.desktop`（`Exec=env GLFW_IM_MODULE=ibus kitty`）
- 方式二：部署 `~/.xsessionrc`（5 个 `*_IM_MODULE` export + 强制 X11 后端）
- fcitx5 自启：部署 `~/.config/autostart/fcitx5.desktop`
- `im-config -n fcitx5`（Debian 专有，声明系统 IM 框架）
- 内置验证状态报告

### Out of scope
- 不修改 `setup.sh` / `install_xfce.sh`（纯独立运行）
- 不动 `kitty.conf`（`setup.sh` 已部署）
- 不动 fcitx5 profile / defaultprofile（`install_sway.sh` 已管）
- 不管 Wayland/Sway（Wayland 下 kitty 走 text-input 协议，无需 `GLFW_IM_MODULE`；`.xsessionrc` 是 X11 专属）
- 不装 xrdp / XFCE（`install_xfce.sh` 的职责）

## 设计决策

| 决策 | 选择 | 理由 |
|------|------|------|
| `.desktop` 来源策略 | **运行时从系统 .desktop 打补丁** | `cp /usr/share/applications/kitty.desktop` + `sed` 改 `Exec=`。永远匹配已装 kitty 版本的字段，跨发行版稳健；不新增静态源文件 |
| 会话覆盖 | 仅 X11 | Wayland 由 `start_sway.sh` 管；`.xsessionrc` 在 Wayland 下不被 source，部署无害但无意义 |
| 集成方式 | 纯独立 | 不改 `setup.sh`/`install_xfce.sh`；用户手动 `bash configs/install_kitty_fcitx5.sh` |
| 源文件复用 | `.xsessionrc` 和 fcitx5 自启复用 `configs/xfce/` 下现有文件 | 与 `install_xfce.sh` 同源，零漂移 |
| `im-config` | 包含 | Debian 专有，`XFCE.md` 手动步骤里有而 `install_xfce.sh` 未做；补上更完整 |

## 脚本结构

**文件**: `configs/install_kitty_fcitx5.sh`
**shebang**: `#!/usr/bin/env bash`，`set -euo pipefail`

### 函数划分（每函数单一职责）

| # | 函数 | 职责 | 失败行为 |
|---|------|------|----------|
| 1 | `detect_os` | 识别 debian/redhat/macOS；macOS 直接 warn+exit 0 | 不支持系统 exit 1 |
| 2 | `resolve_user` | 镜像 `install_xfce.sh:174-180`，处理 sudo 与 `REAL_HOME`/`REAL_USER` | - |
| 3 | `install_fcitx5_packages` | Debian: `fcitx5 fcitx5-chinese-addons fcitx5-frontend-gtk3 fcitx5-frontend-gtk4 fcitx5-frontend-qt5`；RHEL(EPEL): `fcitx5 fcitx5-configtool`。已装则跳过 | 装包失败 exit（set -e） |
| 4 | `deploy_desktop_override` | 方式一：`cp` 系统 .desktop -> `~/.local/share/applications/kitty.desktop`，`sed 's|^Exec=kitty$\|Exec=env GLFW_IM_MODULE=ibus kitty|'` | 系统 .desktop 缺失则 warn+跳过（方式二重登兜底） |
| 5 | `deploy_xsessionrc` | 方式二：`cp configs/xfce/xsessionrc` -> `~/.xsessionrc` | 源文件缺失 warn 不退出 |
| 6 | `deploy_fcitx5_autostart` | `cp configs/xfce/autostart/fcitx5.desktop` -> `~/.config/autostart/` | 源文件缺失 warn 不退出 |
| 7 | `configure_im_framework` | Debian: `im-config -n fcitx5`；RHEL 无此工具跳过 | - |
| 8 | `verify` | 打印状态表 + 提示下一步 | - |

### 执行顺序
`detect_os` -> `resolve_user` -> `install_fcitx5_packages` -> `deploy_desktop_override` -> `deploy_xsessionrc` -> `deploy_fcitx5_autostart` -> `configure_im_framework` -> `verify`

## 关键实现细节

### 方式一的 sed（精确匹配，不误伤 TryExec）
系统 .desktop 含 `TryExec=kitty` 和 `Exec=kitty` 两行。用行锚定：
```bash
sed -i 's|^Exec=kitty$|Exec=env GLFW_IM_MODULE=ibus kitty|' "$dst"
```
`^Exec=kitty$` 的 `^` 确保 `TryExec=kitty` 不被匹配，`$` 确保带参数的 `Exec=kitty --foo` 不被误改。

### 幂等与备份（镜像 install_xfce.sh:294-302）
每个 deploy 前若目标已存在，备份为 `*.bak.$(date +%Y%m%d%H%M%S)` 再覆盖。可安全反复跑。

### REAL_HOME / sudo 处理（镜像 install_xfce.sh:171-180）
```bash
SUDO=""
[ "$EUID" -ne 0 ] && SUDO="sudo"
if [ "$EUID" -eq 0 ] && [ -n "${SUDO_USER:-}" ]; then
  REAL_HOME="$(getent passwd "$SUDO_USER" | cut -d: -f6)"
  REAL_USER="$SUDO_USER"
else
  REAL_HOME="$HOME"
  REAL_USER="${USER:-$(whoami)}"
fi
```

### verify() 输出
状态表包含：
- `~/.local/share/applications/kitty.desktop` 是否存在 + `Exec=` 行内容
- `~/.xsessionrc` 是否存在 + `GLFW_IM_MODULE` 行
- `~/.config/autostart/fcitx5.desktop` 是否存在
- fcitx5 是否已安装 / 是否在跑（`pgrep -a fcitx5`）
- 若 kitty 在跑：`/proc/$(pidof kitty)/environ` 中 `GLFW_IM_MODULE` 值（当前 kitty 是否已生效）
- 末尾提示：「关掉所有 kitty 从面板重开生效方式一；重连 xrdp 会话生效方式二」

## 源文件依赖（零新增静态文件）

| 源 | 目标 | 说明 |
|----|------|------|
| `/usr/share/applications/kitty.desktop`（系统） | `~/.local/share/applications/kitty.desktop` | 运行时读取并打补丁 |
| `configs/xfce/xsessionrc`（已有） | `~/.xsessionrc` | 与 install_xfce.sh 同源 |
| `configs/xfce/autostart/fcitx5.desktop`（已有） | `~/.config/autostart/fcitx5.desktop` | 与 install_xfce.sh 同源 |

## 验证

### 脚本内建（verify 函数）
跑完即打印状态表，无需用户额外操作。

### 端到端手动验证
1. `bash configs/install_kitty_fcitx5.sh`
2. 关掉所有 kitty 窗口，从 xfce4-panel 重开
3. `cat /proc/$(pidof kitty)/environ 2>/dev/null | tr '\0' '\n' | grep GLFW_IM_MODULE` 应输出 `GLFW_IM_MODULE=ibus`
4. 在 kitty 里用 `Ctrl+Space` / Shift 切换 fcitx5，确认能输入中文

### 回归
重连 xrdp 会话后，`echo $GTK_IM_MODULE` 应输出 `fcitx`，fcitx5 自启。

## 非目标 / 已知限制

- **macOS 不支持**：fcitx5 是 Linux 输入法，macOS 直接 warn+exit。
- **Wayland 不处理**：脚本面向 X11；Wayland 下 fcitx5 由 `install_sway.sh` / `start_sway.sh` 管。在 Wayland 会话里跑本脚本只会装包（.xsessionrc 不被 source，部署无害）。
- **不自动化到 setup.sh**：按用户选择保持纯独立；后续若想让所有 `setup.sh` 用户自动获得，可再单独提一个改动让 setup.sh 调用它。
- **fcitx5 profile 不配置**：拼音/五笔等输入法列表由 `install_sway.sh` 或用户手动通过 `fcitx5-configtool` 添加，本脚本不碰。
