# easyMyspace

一键安装 & 配置高效美观的开发环境。Catppuccin Mocha 主题，`Ctrl+Z` 前缀键体系。

## 一行命令安装

**Debian / Ubuntu (Linux 桌面)**

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/shaohaiyang/easyMyspace/main/setup.sh)
```

**macOS**

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/shaohaiyang/easyMyspace/main/setup.sh)
```

脚本会自动检测操作系统，安装对应工具包并部署全部配置。

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

## 配置总览

| 工具 | 说明 |
|------|------|
| **Kitty** | 终端模拟器，保留 `Ctrl+Z` 键位体系，Catppuccin Mocha 主题 |
| **Tmux** | 终端复用器，tpm 插件体系 + resurrect/continuum 会话持久化 |
| **Zsh** | 语法高亮、自动建议、fzf 集成、zoxide 智能跳转 |
| **Starship** | 极简提示符，Catppuccin 配色 |
| **Zed** | AI 编辑器，内联补全 + Assistant Panel，适配 Ctrl+Z 键位 |
| **Yazi** | 终端文件管理器 |
| **Lazygit** | Git TUI 客户端，Catppuccin 主题 |
| **Git** | 别名集 + delta 彩色 diff |
| **opencode** | AI 编程助手，多 Provider 配置 |
| **i3wm** | 平铺窗口管理器（Linux），Polybar + Rofi 主题化 |

## 主题配色

全部工具统一使用 [Catppuccin Mocha](https://github.com/catppuccin/catppuccin) 配色方案：

- 背景 `#1e1e2e` · 前景 `#cdd6f4`
- 蓝色 `#89b4fa` · 红色 `#f38ba8` · 绿色 `#a6e3a1` · 黄色 `#f9e2af`

## 键位特色

- **前缀键**: `Ctrl+Z`（tmux / kitty / zed 统一）
- **分屏**: `u` 水平拆分 · `v` 垂直拆分
- **导航**: `h/j/k/l` Vim 风格方向键
- **应用**: `]` htop · `/` opencode · `\` lazygit · `e` yazi
