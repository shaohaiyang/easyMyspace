# 后续研究

需要进一步评估是否纳入 easyMyspace 的工具清单。

## jcode

| 项目 | 说明 |
|---|---|
| 仓库 | [1jehuang/jcode](https://github.com/1jehuang/jcode) |
| 语言 | Rust |
| Star | ~7k |
| 定位 | TUI 编程助手，30+ 内置工具，swarm 多 agent 协作，持久内存 |
| 安装 | `cargo install jcode` 或预构建二进制 |
| 对比 | 类似 opencode 但功能更重（swarm、OAuth、server/client 模式），纯 Rust 单二进制 |
| 关注点 | 与 opencode 定位重叠，评估是否可替代或互补 |

## omp (oh-my-pi)

| 项目 | 说明 |
|---|---|
| 仓库 | [oh-my-pi/pi-coding-agent](https://github.com/oh-my-pi/pi-coding-agent) |
| 语言 | Node.js |
| 定位 | 轻量 AI 编码助手，npm 全局安装 |
| 状态 | ✅ 已安装 (v15.7.2)，provider 配置已迁移，待实际使用评估 |
| 关注点 | 稳定性和与 opencode 的协同工作流 |

## opencode

| 项目 | 说明 |
|---|---|
| 仓库 | [opencode-ai/opencode](https://github.com/opencode-ai/opencode) |
| 语言 | Go |
| 定位 | 主力 AI 编程助手，多 provider 配置，CLI 集成 |
| 状态 | ✅ 已配置，provider 含 upai-router / local-omlx / volcengine-ark |
| 关注点 | 持续跟踪更新，与 omp 对比决定最终方案 |

## rmux

| 项目 | 说明 |
|---|---|
| 仓库 | [Helvesec/rmux](https://github.com/Helvesec/rmux) |
| 语言 | Rust |
| 版本 | v0.3.1 (2026-05-25)，公开预览 |
| 定位 | Rust 终端复用器，兼容 tmux CLI（90+ 命令），Rust SDK + Ratatui 集成 |
| 与 tmux 关系 | CLI 命令兼容，**配置语法不兼容**（需写 `.rmux.conf`） |
| 迁移回退 | 找不到 `.rmux.conf` 时可读取过滤后的 `tmux.conf`，但跳过按键绑定/插件/hooks/shell 命令 |
| 关注点 | 等 v1.0 后再评估，当前版本尚不稳定；若稳定性达标，可替代 tmux |
