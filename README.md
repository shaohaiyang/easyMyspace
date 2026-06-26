# easyMyspace

一键安装 & 配置高效美观的开发环境。Catppuccin Mocha 主题，`Ctrl+Z` 前缀键体系。

## 前置要求

运行 `setup.sh` 前，系统需已安装以下软件：

- **git** — 克隆仓库
- **curl** — 在线安装方式
- **sudo** — 权限提升

Debian/Ubuntu 系安装命令：

```bash
apt update && apt install -y git curl sudo
```

RHEL/Fedora 系安装命令：

```bash
dnf install -y git curl sudo
```

## 一行命令安装

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/shaohaiyang/easyMyspace/main/setup.sh)
```

脚本会自动检测操作系统并安装对应工具。

## 本地运行

```bash
git clone --depth 1 https://github.com/shaohaiyang/easyMyspace.git
cd easyMyspace
./setup.sh
```

## 可用参数

| 参数 | 说明 |
|------|------|
| `--dry-run` | 预览模式，只显示将执行的操作，不做任何修改 |
| `--tools` | 仅安装系统工具，跳过配置文件部署 |
| `--config` | 仅部署配置文件，跳过工具安装 |

## 脚本架构

```
configs/
├── install_tools.sh      ← 调度器（入口，自动检测 OS）
├── install_mac.sh        ← macOS（Homebrew）
├── install_debian.sh     ← Debian/Ubuntu/Devuan（apt）
├── install_redhat.sh     ← RHEL/CentOS/Alma/Rocky（dnf）
├── install_sway.sh       ← Sway 桌面（跨平台，独立运行）
├── bashrc.sh             ← Bash 配置（Linux 注入 ~/.bashrc）
├── zshrc.sh              ← Zsh 配置（macOS 注入 ~/.zshrc）
├── aliases.sh             ← 别名集（配合 shell rc）
└── sway/                 ← Sway 配置文件（含 swaylock 锁屏主题）
```

子脚本可独立运行，安装指定平台的工具：

```bash
# Debian 基础工具
source configs/install_debian.sh && install_packages

# Sway 桌面（跨平台）
sudo bash configs/install_sway.sh
sudo bash configs/install_sway.sh --minimal   # 仅核心组件
```

## 安装内容

| 模块 | 平台 | 说明 |
|------|------|------|
| **基础工具** | Debian / RHEL | tmux、neovim、fzf、bat、ripgrep、git、openssh-server、btop、tealdeer、glow、gitu、gonzo 等 |
| **macOS 工具** | macOS | 同上 via Homebrew |
| **Sway 桌面** | Linux | sway、waybar、wofi、mako、kitty、Thunar、PipeWire 等 |
| **开发运行时** | 全平台 | Node.js 22.x（NodeSource）、Rust、uv、Go |
| **AI 工具** | 全平台 | opencode（AI 编程）、oh-my-pi（via bun） |
| **日志分析** | 全平台 | gonzo（Go TUI 日志分析工具） |
| **终端增强** | 全平台 | herdr（终端复用器，tmux 替代） |

## 配置总览

| 工具 | 说明 |
|------|------|
| **Kitty** | 终端模拟器，`Ctrl+Z` 前缀键，Catppuccin Mocha 主题 |
| **Tmux** | 终端复用器，tpm 插件 + resurrect/continuum 会话持久化 |
| **Starship** | 极简提示符，Catppuccin 配色 |
| **Shell** | macOS 用 zsh+aliases，Linux 用 bash+fzf+zoxide |
| **Yazi** | 终端文件管理器 |
| **Lazygit** | Git TUI 客户端 |
| **Git** | 别名集（g=gitu gi=gitu）+ delta 彩色 diff |
| **opencode** | AI 编程助手，多 Provider 配置 |
| **Oh-my-Pi** | AI 编码 agent（via bun） |
| **herdr** | 终端复用器（tmux 替代），`Ctrl+B` 前缀，支持 AI agent 管理、会话持久化、远程连接 |
| **gonzo** | 日志分析 TUI，支持实时流、K8s 集成、AI 分析、OTLP 协议 |
| **Sway** | 平铺窗口管理器（Linux），Waybar + Wofi + Mako 主题化，swaylock 锁屏 + swayidle 自动息屏，截图快捷键 |

## 主题配色

全部工具统一使用 [Catppuccin Mocha](https://github.com/catppuccin/catppuccin) 配色方案：

- 背景 `#1e1e2e` · 前景 `#cdd6f4`
- 蓝色 `#89b4fa` · 红色 `#f38ba8` · 绿色 `#a6e3a1` · 黄色 `#f9e2af`

## 键位特色（Kitty + Tmux 统一 Ctrl+Z 体系）

### Kitty 键位

| 功能 | 快捷键 |
|------|--------|
| **前缀键** | `Ctrl+Z` |
| **分屏** | `Ctrl+Z` + `u`（水平）· `v`（垂直）· `/`（新标签页） |
| **窗口焦点** | `Ctrl+Z` + `h`（左）· `j`（下）· `k`（上）· `l`（右） |
| **调整大小** | `Ctrl+Z` + `Ctrl+h/j/k/l`（缩窄/缩短/加高/加宽） |
| **Tab 切换** | `Ctrl+Z` + `b`（上一页）· `a`（下一页）|
| **布局切换** | `Ctrl+Z` + `m`（下一布局）· `z`（堆叠）· `=`（重置） |
| **快捷应用** | `Ctrl+Z` + `]`（htop）· `o`（opencode）· `g`（lazygit）· `e`（yazi） |
| **Tmux 透传** | `Ctrl+Z` + `c`（发送 `Ctrl+Z` 给 tmux） |

### Tmux 键位

| 功能 | 快捷键 |
|------|--------|
| **前缀键** | `Ctrl+Z` |
| **分屏** | `u`（水平）· `v`（垂直） |
| **窗口焦点** | `h/j/k/l` Vim 风格 |
| **缩放** | `z` 全屏 · `Ctrl+z` 恢复 |
| **复制模式** | `[` 进入 · 空格 选择 · `y` 复制 |
| **插件管理** | `Ctrl+Z` + `I`（安装）

### Herdr 键位

| 功能 | 快捷键 |
|------|--------|
| **前缀键** | `Ctrl+B`（避免与 Kitty `Ctrl+Z` 冲突） |
| **左右分屏** | `prefix+-` |
| **分屏交换** | `prefix+h/j/k/l`（Vim 风格） |
| **分屏循环** | `prefix+.`（下一个）· `prefix+Shift+Tab`（上一个） |
| **缩放分屏** | `prefix+Shift+z` |
| **关闭分屏** | `prefix+x` |
| **调整大小** | `prefix+r`（进入调整模式后 hjkl） |
| **Tab 管理** | `prefix+c`（新建）· `n`（下一个）· `p`（上一个）· `comma`（重命名）· `Shift+x`（关闭） |
| **工作区管理** | `prefix+Shift+n`（新建）· `Shift+d`（关闭）· `Shift+w`（重命名）· `w`（选择器） |
| **复制模式** | `prefix+Shift+c` |
| **侧边栏** | `prefix+b` |
| **分离** | `prefix+d` |
| **快捷应用** | `prefix+o`（opencode）· `g`（lazygit）· `e`（yazi）· `\`（htop）——继承当前 pane 目录 |
| **重载配置** | `prefix+Shift+r` |

### Sway 键位

| 功能 | 快捷键 |
|------|--------|
| **启动终端** | `Super+Enter` |
| **应用启动器** | `Super+Space`（drun）· `Super+Shift+Space`（run） |
| **工作区** | `Super+1~5` 切换 · `Super+Shift+1~5` 移动窗口 |
| **窗口焦点** | `Super+h/j/k/l` Vim 风格 |
| **全屏** | `Super+f` |
| **锁屏** | `Super+Shift+L` 手动锁屏 |
| **截全屏 → 剪贴板** | `Print` |
| **选区截图 → 剪贴板** | `Shift+Print` |
| **截全屏 → 文件** | `Ctrl+Print` |
| **选区截图 → 文件** | `Ctrl+Shift+Print` |
| **自动锁屏** | 闲置 5 分钟自动锁屏 |
| **自动息屏** | 闲置 10 分钟关闭显示器，活动后恢复 |

截图保存至 `~/Pictures/Screenshots/` 目录，配合 `Mod+Shift+R` 重启 Sway 使配置生效。
