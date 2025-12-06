# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 项目概述

Clash Verge Rev 是基于 Tauri 2 框架的 Clash Meta GUI 应用程序。这是 [Clash Verge](https://github.com/zzzgydi/clash-verge) 的延续项目。

### 技术栈
- **前端**: React 18 + TypeScript + Vite + Material-UI (MUI)
- **后端**: Rust + Tauri 2.x
- **核心**: 内置 Clash.Meta(mihomo) 内核
- **包管理器**: pnpm (v9.13.2)

## 开发环境设置

### 前置要求
1. 安装 Rust 和 Node.js - 参考 [Tauri 前置条件](https://tauri.app/v1/guides/getting-started/prerequisites)
2. 安装 pnpm: `npm install pnpm -g`

### Windows 特定要求
- 必须使用 `x86_64-pc-windows-msvc` 工具链:
  ```shell
  rustup target add x86_64-pc-windows-msvc
  rustup set default-host x86_64-pc-windows-msvc
  ```
- 需要安装 GNU `patch` 工具

### 初始化项目
```shell
# 安装依赖
pnpm install

# 下载 Mihomo 内核二进制文件（必须在首次开发前执行）
pnpm run check
# 使用 --force 强制更新到最新版本
# pnpm run check --force
```

## 常用命令

### 开发
```shell
# 启动开发服务器
pnpm dev

# 如果已有实例运行，使用不同的命令
pnpm dev:diff

# 仅启动前端开发服务器（不启动 Tauri）
pnpm web:dev
```

### 构建
```shell
# 标准构建（优化版本）
pnpm build

# 快速构建（用于测试，禁用优化和 LTO）
pnpm build:fast

# 仅构建前端
pnpm web:build
```

### 代码质量
```shell
# Rust 代码检查
pnpm clippy

# 等同于:
cargo clippy --manifest-path ./src-tauri/Cargo.toml
```

### 其他工具
```shell
# 清理 Rust 构建产物
pnpm clean

# 生成便携版本（仅 Windows）
pnpm portable

# 生成更新器包
pnpm updater
```

## 架构概览

### 前端架构 (src/)

#### 核心结构
- **pages/**: 应用页面组件
  - `home.tsx` - 主页（流量统计、系统信息）
  - `proxies.tsx` - 代理节点管理
  - `profiles.tsx` - 配置文件管理
  - `rules.tsx` - 规则管理
  - `connections.tsx` - 连接监控
  - `logs.tsx` - 日志查看
  - `settings.tsx` - 应用设置
  - `test.tsx` - 延迟测试
  - `unlock.tsx` - 流媒体解锁检测
  - `_layout.tsx` - 布局组件
  - `_routers.tsx` - 路由定义
  - `_theme.tsx` - 主题配置

- **components/**: 可复用组件，按功能模块组织
  - `home/` - 主页相关组件（流量图表、系统信息卡片）
  - `proxy/` - 代理相关组件（节点列表、分组渲染）
  - `profile/` - 配置文件相关（编辑器、查看器）
  - `connection/` - 连接监控组件
  - `rule/` - 规则管理组件
  - `setting/` - 设置页面组件
  - `layout/` - 布局组件（流量显示、托盘控制）
  - `base/` - 基础组件

- **services/**: 服务层
  - `cmds.ts` - Tauri 命令调用封装（前端调用后端 Rust 函数）
  - `api.ts` - Clash API 调用
  - `states.ts` - 全局状态管理
  - `delay.ts` - 延迟测试服务
  - `i18n.ts` - 国际化服务

- **providers/**: React Context 提供者
  - `app-data-provider.tsx` - 应用数据提供者

- **utils/**: 工具函数
  - `websocket.ts` - WebSocket 连接管理
  - `parse-traffic.ts` - 流量数据解析
  - `parse-hotkey.ts` - 快捷键解析

- **locales/**: 国际化翻译文件（JSON）
  - 支持语言: zh, en, ru, tt, fa, id, ar

#### 前端与后端通信
- 使用 `@tauri-apps/api/core` 的 `invoke` 函数调用后端命令
- 所有命令封装在 `src/services/cmds.ts` 中
- 命令示例: `getProfiles()`, `patchClashConfig()`, `getVergeConfig()`

### 后端架构 (src-tauri/src/)

#### 核心模块
- **cmd/**: Tauri 命令处理器（前端可调用的函数）
  - `profile.rs` - 配置文件操作
  - `clash.rs` - Clash 配置管理
  - `verge.rs` - Verge 配置管理
  - `runtime.rs` - 运行时配置
  - `proxy.rs` - 代理操作
  - `service.rs` - 系统服务管理
  - `system.rs` - 系统信息
  - `network.rs` - 网络接口
  - `webdav.rs` - WebDAV 备份
  - `uwp.rs` - UWP 应用（Windows）
  - `validate.rs` - 配置验证
  - `app.rs` - 应用相关
  - `lightweight.rs` - 轻量模式
  - `media_unlock_checker.rs` - 流媒体解锁检测

- **config/**: 配置管理
  - `profiles.rs` - 配置文件列表管理
  - `prfitem.rs` - 配置文件项
  - `clash.rs` - Clash 配置
  - `verge.rs` - Verge（应用）配置
  - `runtime.rs` - 运行时配置
  - `draft.rs` - 草稿配置
  - `encrypt.rs` - 加密功能

- **core/**: 核心功能
  - `core.rs` - 核心逻辑（Mihomo 进程管理）
  - `handle.rs` - 全局句柄管理
  - `sysopt.rs` - 系统选项（代理设置、TUN 模式）
  - `service.rs` - 系统服务安装/卸载
  - `tray/` - 系统托盘管理
  - `hotkey.rs` - 全局快捷键
  - `timer.rs` - 定时任务（配置更新、延迟测试）
  - `backup.rs` - 备份管理
  - `win_uwp.rs` - Windows UWP 应用管理

- **enhance/**: 配置增强功能
  - `mod.rs` - 增强模式主逻辑（合并配置、执行脚本）
  - `merge.rs` - 配置合并
  - `script.rs` - JavaScript 脚本执行（使用 boa_engine）
  - `chain.rs` - 配置链处理
  - `field.rs` - 字段处理
  - `seq.rs` - 序列操作（Rules、Proxies、Groups）
  - `tun.rs` - TUN 模式配置

- **feat/**: 功能层（协调 core 和 cmd）
  - `profile.rs` - 配置文件管理功能
  - `clash.rs` - Clash 核心功能
  - `config.rs` - 配置处理
  - `window.rs` - 窗口管理
  - `backup.rs` - 备份功能
  - `proxy.rs` - 代理功能

- **module/**: 外部模块封装
  - `mihomo.rs` - Mihomo 进程管理
  - `sysinfo.rs` - 系统信息收集
  - `lightweight.rs` - 轻量模式模块

- **utils/**: 工具函数
  - `dirs.rs` - 目录管理
  - `help.rs` - 辅助函数
  - `init.rs` - 初始化
  - `logging.rs` - 日志系统
  - `resolve.rs` - 配置解析
  - `server.rs` - 单例检测服务器
  - `i18n.rs` - 国际化

- **error/**: 错误处理
  - `mod.rs` - 错误定义
  - `service.rs` - 服务错误

#### 配置增强系统
配置增强是 Clash Verge Rev 的核心特性，允许用户通过以下方式自定义配置:
1. **Merge**: YAML 映射合并
2. **Script**: JavaScript 脚本处理（支持 `main(config)` 函数）
3. **Rules/Proxies/Groups**: 序列化编辑器

增强流程（`src-tauri/src/enhance/mod.rs`）:
1. 加载基础配置文件
2. 应用全局 Merge 和 Script
3. 应用配置文件关联的 Rules、Proxies、Groups
4. 应用配置文件关联的 Merge 和 Script
5. 合并默认 Clash 配置
6. 运行内置脚本（如果启用）
7. 处理 TUN 模式配置
8. 应用独立 DNS 配置（如果启用）

### Vite 配置优化
- **代码分割**: Monaco Editor、React、MUI、Tauri 插件等分别打包
- **构建目标**: ES2020，使用 Terser 压缩
- **路径别名**:
  - `@` -> `./src`
  - `@root` -> `.`

## 测试

### 运行单个测试
```shell
# Rust 测试示例
cargo test --manifest-path ./src-tauri/Cargo.toml test_name

# Mihomo API 测试
cargo test --manifest-path ./src-tauri/Cargo.toml --package crate_mihomo_api
```

## 调试技巧

### 前端调试
- 开发模式下使用浏览器开发者工具
- 检查 `src/services/cmds.ts` 中的命令调用
- WebSocket 连接在 `src/utils/websocket.ts` 中管理

### 后端调试
- 使用 `log::debug!`, `log::info!`, `log::error!` 宏
- 日志配置在 `src-tauri/src/utils/logging.rs`
- 开发模式设置 `RUST_BACKTRACE=1` 环境变量

### 配置文件位置
- **应用配置目录**:
  - Windows: `%APPDATA%/io.github.clash-verge-rev.clash-verge-rev/`
  - macOS: `~/Library/Application Support/io.github.clash-verge-rev.clash-verge-rev/`
  - Linux: `~/.config/io.github.clash-verge-rev.clash-verge-rev/`
- **配置文件**:
  - `profiles.yaml` - 配置文件列表
  - `verge.yaml` - 应用配置
  - `clash.yaml` - Clash 默认配置
  - `profiles/` - 配置文件存储目录

## 关键依赖

### 前端
- `@tauri-apps/api` - Tauri API 绑定
- `@mui/material` - Material-UI 组件库
- `react-router-dom` - 路由
- `monaco-editor` - 代码编辑器
- `recharts` - 图表库
- `zustand` - 轻量状态管理
- `swr` - 数据获取和缓存
- `i18next` - 国际化

### 后端
- `tauri` - 应用框架
- `tokio` - 异步运行时
- `serde` / `serde_yaml` / `serde_json` - 序列化
- `reqwest` - HTTP 客户端
- `sysproxy` - 系统代理设置（自定义 fork）
- `boa_engine` - JavaScript 引擎（用于配置脚本）
- `log4rs` - 日志框架
- `sysinfo` - 系统信息
- `delay_timer` - 定时任务

## 代码风格

### 前端
- 使用 Prettier 格式化（配置在 package.json 中）
- 缩进: 2 空格
- 分号: 使用
- 引号: 双引号
- 换行符: LF
- 使用 Husky 和 pretty-quick 进行提交前格式化

### 后端
- 遵循 Rust 标准风格
- 使用 `cargo clippy` 进行代码检查
- 模块组织: 功能优先，避免深层嵌套

## 特殊注意事项

### 平台差异处理
- Windows: 支持 UWP 应用管理、系统服务安装
- macOS: 支持激活策略设置（Regular/Accessory/Prohibited）
- Linux: 设置 `WEBKIT_DISABLE_DMABUF_RENDERER=1` 环境变量

### Mihomo 内核管理
- 内核二进制文件通过 `pnpm run check` 下载
- 支持切换 Alpha 版本内核
- 进程管理在 `src-tauri/src/module/mihomo.rs`
- Sidecar 配置在 `src-tauri/tauri.conf.json`

### 单例模式
- 应用通过 WebSocket 服务器检测单例（`src-tauri/src/utils/server.rs`）
- 如果已有实例运行，新实例会自动退出

### 深度链接
- 支持 `clash://` 协议处理（导入配置文件）
- 处理逻辑在 `src-tauri/src/utils/resolve.rs`
