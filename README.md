# easyMyspace

一键安装 & 配置高效美观的开发环境。Catppuccin Mocha 主题，`Ctrl+Z` 前缀键体系。

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
└── sway/                 ← Sway 配置文件
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
| **基础工具** | Debian / RHEL | tmux、neovim、fzf、bat、ripgrep、git、openssh-server 等 |
| **macOS 工具** | macOS | 同上 via Homebrew + gitu、btop、tealdeer |
| **Sway 桌面** | Linux | sway、waybar、wofi、mako、kitty、Thunar、PipeWire 等 |
| **开发运行时** | 全平台 | Node.js 22.x（NodeSource）、Rust、uv、Go |
| **AI 工具** | 全平台 | opencode（AI 编程）、oh-my-pi（via bun） |

## 配置总览

| 工具 | 说明 |
|------|------|
| **Kitty** | 终端模拟器，`Ctrl+Z` 前缀键，Catppuccin Mocha 主题 |
| **Tmux** | 终端复用器，tpm 插件 + resurrect/continuum 会话持久化 |
| **Starship** | 极简提示符，Catppuccin 配色 |
| **Neovim** | AI 编辑器，内联补全 + Assistant Panel |
| **Yazi** | 终端文件管理器 |
| **Lazygit** | Git TUI 客户端 |
| **Git** | 别名集 + delta 彩色 diff |
| **opencode** | AI 编程助手，多 Provider 配置 |
| **Oh-my-Pi** | AI 编码 agent（via bun） |
| **Sway** | 平铺窗口管理器（Linux），Waybar + Wofi 主题化 |

## 主题配色

全部工具统一使用 [Catppuccin Mocha](https://github.com/catppuccin/catppuccin) 配色方案：

- 背景 `#1e1e2e` · 前景 `#cdd6f4`
- 蓝色 `#89b4fa` · 红色 `#f38ba8` · 绿色 `#a6e3a1` · 黄色 `#f9e2af`

## 键位特色

- **前缀键**: `Ctrl+Z`（tmux / kitty 统一）
- **分屏**: `u` 水平拆分 · `v` 垂直拆分
- **导航**: `h/j/k/l` Vim 风格方向键
- **应用**: `]` htop · `/` opencode · `\` lazygit · `e` yazi
