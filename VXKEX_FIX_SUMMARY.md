# VxKex 配置问题修复总结

## 修复日期
2025-12-31

## 问题描述

Win7 Legacy v2.2.3 安装程序存在以下关键问题导致 Clash Verge 无法在 Windows 7 上运行：

### 1. **VxKex 文件未被复制到安装目录**
- NSIS 安装脚本中缺少复制 VxKex 相关文件的指令
- 导致 `$INSTDIR\vxkex\KexSetup.exe` 和 `configure-vxkex.ps1` 不存在
- VxKex 安装步骤失败

### 2. **可执行文件名不匹配**
- Tauri 实际编译输出: `clash-verge.exe`
- 配置脚本中使用: `Clash Verge Win7.exe`
- 注册表 VxKex 配置针对错误的文件名

### 3. **VxKex 未安装到系统**
- 由于问题 1，VxKex 安装程序未执行
- `C:\Program Files\VxKex` 不存在

## 已实施的修复

### 修复 1: NSIS 安装脚本 (`installer-win7.nsi`)

**位置**: Line 885-888

**修改内容**:
```nsis
; VxKex: 复制 VxKex 文件到安装目录 - Win7 Legacy
CreateDirectory "$INSTDIR\vxkex"
File "/oname=$INSTDIR\vxkex\KexSetup.exe" "vxkex\KexSetup.exe"
File "/oname=$INSTDIR\vxkex\configure-vxkex.ps1" "vxkex\configure-vxkex.ps1"
```

**效果**:
- 在安装时创建 `vxkex` 子目录
- 复制 VxKex 安装程序到安装目录
- 复制 PowerShell 配置脚本到安装目录

### 修复 2: PowerShell 配置脚本 (`configure-vxkex.ps1`)

**位置**: Line 136-142

**修改前**:
```powershell
$executables = @(
    @{Name = "Clash Verge Win7.exe"; Path = $InstallDir},
    ...
)
```

**修改后**:
```powershell
# 注意: Tauri 编译出的主程序名称是 clash-verge.exe (小写,无空格)
$executables = @(
    @{Name = "clash-verge.exe"; Path = $InstallDir},
    @{Name = "clash-verge-service.exe"; Path = Join-Path $InstallDir "resources"},
    @{Name = "install-service.exe"; Path = Join-Path $InstallDir "resources"},
    @{Name = "uninstall-service.exe"; Path = Join-Path $InstallDir "resources"}
)
```

**效果**:
- VxKex 配置针对正确的可执行文件名
- 注册表键名匹配实际文件

### 修复 3: NSIS 卸载脚本 (`installer-win7.nsi`)

**位置**: Line 1001-1004

**修改前**:
```nsis
DeleteRegKey HKLM "...\Clash Verge Win7.exe"
```

**修改后**:
```nsis
DeleteRegKey HKLM "...\clash-verge.exe"
```

**效果**:
- 卸载时正确清理 VxKex 注册表配置

### 修复 4: 参考文档 (`installer-win7-addon.nsi`)

**位置**: Line 107-110

**修改内容**:
- 同步更新文档中的文件名
- 添加注释说明实际文件名

## 修复验证

### 已验证项
- ✅ VxKex 文件存在: `src-tauri/vxkex/KexSetup.exe` (3.9MB)
- ✅ 配置脚本存在: `src-tauri/vxkex/configure-vxkex.ps1` (5.8KB)
- ✅ 所有文件名引用已统一为 `clash-verge.exe`
- ✅ NSIS 脚本包含文件复制指令

### 预期效果

重新构建后的安装程序将：

1. **安装时**:
   - 检测 Windows 7 系统
   - 复制 VxKex 文件到 `$INSTDIR\vxkex\`
   - 静默安装 VxKex 到 `C:\Program Files\VxKex`
   - 运行 PowerShell 脚本配置注册表
   - 为以下文件启用 VxKex:
     - `clash-verge.exe`
     - `clash-verge-service.exe`
     - `install-service.exe`
     - `uninstall-service.exe`

2. **VxKex 配置**:
   - 注册表路径: `HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\`
   - 每个可执行文件设置:
     - `VerifierDlls` = `KexDll.dll`
     - `VxKexFlags` = `0x00000300`
     - `VxKexDisableChildProcesses` = `1`

3. **卸载时**:
   - 清理所有 VxKex 注册表配置
   - VxKex 程序本身保留（用户可手动卸载）

## 下一步操作

### 1. 重新构建安装包

```bash
# 在项目根目录执行
pnpm prebuild:win7
pnpm build:win7
```

### 2. 测试安装包

在 Windows 7 SP1 x64 系统上：

1. 以管理员身份运行安装程序
2. 观察安装日志中的 VxKex 相关信息
3. 检查安装后的文件结构:
   ```
   C:\Program Files\Clash Verge Win7\
   ├── clash-verge.exe
   ├── vxkex\
   │   ├── KexSetup.exe
   │   └── configure-vxkex.ps1
   └── resources\
   ```
4. 检查 VxKex 安装:
   ```
   C:\Program Files\VxKex\
   └── KexDll.dll
   ```
5. 检查注册表配置:
   ```
   HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\clash-verge.exe
   ```
6. 运行 `clash-verge.exe` 验证程序启动

### 3. 推送修复到仓库

```bash
git add src-tauri/packages/windows/installer-win7.nsi
git add src-tauri/packages/windows/installer-win7-addon.nsi
git add src-tauri/vxkex/configure-vxkex.ps1
git commit -m "fix: 修复 VxKex 配置问题 - 文件名不匹配和文件未复制"
git push origin win7-legacy
```

## 相关文件清单

### 已修改文件
1. `src-tauri/packages/windows/installer-win7.nsi` (主安装脚本)
2. `src-tauri/packages/windows/installer-win7-addon.nsi` (参考文档)
3. `src-tauri/vxkex/configure-vxkex.ps1` (配置脚本)

### VxKex 资源文件
1. `src-tauri/vxkex/KexSetup.exe` (3.9MB) - VxKex 安装程序
2. `src-tauri/vxkex/configure-vxkex.ps1` (5.8KB) - 配置脚本

## 技术说明

### Tauri 产品名称处理
- `tauri.conf.json` 中 `productName`: "Clash Verge Win7"
- Tauri 编译器将其转换为: `clash-verge.exe`
- 规则: 转小写，移除空格，保留连字符

### VxKex 工作原理
- 通过 IFEO (Image File Execution Options) 注入 `KexDll.dll`
- 拦截 Windows API 调用并提供兼容性垫片
- 使 Windows 7 支持 Windows 8+ 的 API

### 为什么需要 VxKex
- Tauri 2.x 使用 WebView2
- WebView2 依赖 Windows 8.1+ API
- VxKex 提供必要的 API 兼容层

## 参考资源
- VxKex 项目: https://github.com/i486/VxKex
- Tauri 文档: https://tauri.app/
- NSIS 文档: https://nsis.sourceforge.io/

---

**修复者**: Claude Code (AI Assistant)
**测试状态**: 待测试
**版本**: Win7 Legacy v2.2.3 (修复版)
