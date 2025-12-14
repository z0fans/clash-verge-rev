# Clash Verge Win7 - VxKex 集成说明

## 📋 概述

Clash Verge Win7 版本通过集成 **VxKex (VxKextended Kernel Extensions)** 实现在 Windows 7 系统上的完整兼容性。

## ❓ 什么是 VxKex

VxKex 是一个 Windows 7 API 扩展层，允许原本仅支持 Windows 8/10/11 的应用程序在 Windows 7 上运行。

- **项目地址**: https://github.com/i486/VxKex
- **工作原理**: 通过注入兼容性 DLL，为应用程序提供缺失的 API 函数
- **使用场景**: 运行使用了 Windows 8+ API 的现代应用程序

## 🚀 自动安装流程

Clash Verge Win7 安装程序会自动处理 VxKex 的安装和配置：

### 1. 系统检测
安装程序会自动检测您的 Windows 版本：
- **Windows 7**: 自动安装并配置 VxKex
- **Windows 8/8.1/10/11**: 跳过 VxKex 安装

### 2. VxKex 安装
如果检测到 Windows 7，安装程序将：
- 静默安装 VxKex 到 `C:\Program Files\VxKex\`
- 无需用户干预
- 安装过程约需 5-10 秒

### 3. 自动配置
VxKex 安装成功后，将自动配置以下可执行文件：
- `Clash Verge Win7.exe` - 主程序
- `clash-verge-service.exe` - 系统服务
- `install-service.exe` - 服务安装工具
- `uninstall-service.exe` - 服务卸载工具

### 4. 注册表配置
配置过程会在注册表中创建 IFEO (Image File Execution Options) 条目：

```
HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\<exe名称>
  ├─ VerifierDlls = "KexDll.dll"
  ├─ VxKexFlags = 0x00000300
  └─ VxKexDisableChildProcesses = 1
```

## 📦 安装包内容

VxKex 相关文件包含在安装包中：

```
安装包/
├─ vxkex/
│  ├─ KexSetup.exe                  # VxKex 安装程序
│  └─ configure-vxkex.ps1           # PowerShell 配置脚本
└─ Microsoft.WebView2.FixedVersionRuntime.109.0.1518.78.x64/
   └─ ...                            # 固定版本 WebView2 运行时
```

## ✅ 验证安装

安装完成后，您可以验证 VxKex 是否正确安装：

### 方法 1: 检查 VxKex 安装
1. 打开文件资源管理器
2. 导航到 `C:\Program Files\VxKex\`
3. 确认存在 `KexDll.dll` 文件

### 方法 2: 检查注册表配置
1. 按 `Win+R`，输入 `regedit`，回车
2. 导航到: `HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\`
3. 确认存在 `Clash Verge Win7.exe` 子项
4. 检查其中的 `VerifierDlls` 值是否为 `KexDll.dll`

### 方法 3: 运行应用程序
1. 启动 Clash Verge Win7
2. 如果程序正常运行，说明 VxKex 工作正常
3. 如果出现 `GetSystemTimePreciseAsFileTime` 错误，说明 VxKex 未正确配置

## 🔧 手动配置（仅在自动配置失败时使用）

如果自动配置失败，您可以手动配置 VxKex：

### 步骤 1: 手动安装 VxKex

1. 打开安装目录（默认: `C:\Program Files\Clash Verge Win7\`）
2. 进入 `vxkex` 子目录
3. 以管理员身份运行 `KexSetup.exe`
4. 按照安装向导完成安装

### 步骤 2: 手动运行配置脚本

1. 右键点击"开始"菜单，选择"Windows PowerShell (管理员)"
2. 执行以下命令：

```powershell
cd "C:\Program Files\Clash Verge Win7\vxkex"
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
.\configure-vxkex.ps1 -InstallDir "C:\Program Files\Clash Verge Win7"
```

3. 等待脚本完成，确认所有 4 个可执行文件配置成功

### 步骤 3: 手动注册表配置（高级用户）

如果 PowerShell 脚本无法运行，您可以手动编辑注册表：

1. 以管理员身份运行 `regedit`
2. 对于每个可执行文件，创建以下注册表项：

**主程序配置:**
```
路径: HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\Clash Verge Win7.exe

创建字符串值:
  名称: VerifierDlls
  数据: KexDll.dll

创建 DWORD (32位) 值:
  名称: VxKexFlags
  数据: 0x00000300

创建 DWORD (32位) 值:
  名称: VxKexDisableChildProcesses
  数据: 0x00000001
```

**重复以上步骤配置以下可执行文件:**
- `clash-verge-service.exe`
- `install-service.exe`
- `uninstall-service.exe`

## 🗑️ 卸载说明

卸载 Clash Verge Win7 时：

### 自动清理
卸载程序会自动：
- 删除所有 IFEO 注册表配置
- 保留 VxKex 程序本身（可能被其他应用使用）

### 完全卸载 VxKex
如果您想完全删除 VxKex：

1. 卸载 Clash Verge Win7
2. 打开"控制面板" → "程序和功能"
3. 找到"VxKex"并卸载
4. 或者直接删除 `C:\Program Files\VxKex\` 目录（需要管理员权限）

## 🐛 故障排除

### 问题 1: 程序无法启动，提示找不到 API
**错误示例**: "无法定位程序输入点 GetSystemTimePreciseAsFileTime 于动态链接库 kernel32.dll 上"

**解决方法**:
1. 确认 VxKex 已正确安装（检查 `C:\Program Files\VxKex\KexDll.dll`）
2. 确认注册表配置存在（参考"验证安装"部分）
3. 尝试手动运行配置脚本（参考"手动配置"部分）
4. 重启计算机后再次尝试

### 问题 2: VxKex 安装失败
**可能原因**:
- 权限不足
- 杀毒软件拦截
- 磁盘空间不足

**解决方法**:
1. 以管理员身份重新运行安装程序
2. 临时禁用杀毒软件
3. 清理磁盘空间
4. 手动安装 VxKex（参考"手动配置"部分）

### 问题 3: PowerShell 脚本无法运行
**错误示例**: "无法加载文件，因为在此系统上禁止运行脚本"

**解决方法**:
```powershell
# 以管理员身份运行 PowerShell，然后执行：
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass

# 再次运行配置脚本
cd "C:\Program Files\Clash Verge Win7\vxkex"
.\configure-vxkex.ps1
```

### 问题 4: 程序运行缓慢或崩溃
**可能原因**: VxKex 配置冲突

**解决方法**:
1. 检查是否有多个应用配置了 VxKex
2. 尝试禁用子进程继承：确认 `VxKexDisableChildProcesses` 设置为 `1`
3. 重新安装 VxKex
4. 更新到最新版本的 VxKex

## 📝 技术细节

### VxKex 配置参数说明

- **VerifierDlls = "KexDll.dll"**
  - 指定要注入的 DLL 文件
  - VxKex 的核心兼容性模块

- **VxKexFlags = 0x00000300**
  - `0x00000100`: 启用 VxKex
  - `0x00000200`: 禁用子进程继承
  - 组合值 `0x00000300`: 同时启用以上两个标志

- **VxKexDisableChildProcesses = 1**
  - 防止 VxKex 配置继承到子进程
  - 避免不必要的兼容性问题

### 为什么需要固定版本 WebView2

- **WebView2 版本**: 109.0.1518.78
- **原因**: 这是最后一个支持 Windows 7 的 WebView2 版本
- **安装方式**: 固定运行时（Fixed Runtime），内置于安装包
- **好处**: 无需联网下载，确保兼容性

## 🔗 相关链接

- **VxKex 项目**: https://github.com/i486/VxKex
- **相关 Issue**: https://github.com/clash-verge-rev/clash-verge-rev/issues/1041
- **Clash Verge Rev 主项目**: https://github.com/clash-verge-rev/clash-verge-rev

## ⚠️ 重要提示

1. **管理员权限**: VxKex 配置需要管理员权限，安装时请以管理员身份运行
2. **杀毒软件**: 部分杀毒软件可能会误报 VxKex，请添加信任
3. **仅 Windows 7**: 此版本专为 Windows 7 设计，不建议在 Windows 8+ 系统使用
4. **无自动更新**: Win7 版本不包含自动更新功能，请手动检查更新
5. **单独版本**: Win7 版本与主版本使用不同的标识符，不会互相影响

## 💡 常见问题

**Q: 我可以在 Windows 10 上使用 Win7 版本吗？**
A: 技术上可以，但不推荐。请使用主版本（标准版）以获得最佳性能和功能。

**Q: VxKex 会影响系统稳定性吗？**
A: VxKex 是成熟的兼容层项目，经过广泛测试。仅影响配置的应用程序，不会影响系统其他部分。

**Q: 卸载 Clash Verge 后需要手动删除 VxKex 吗？**
A: 不需要，除非您确定没有其他应用程序使用 VxKex。VxKex 可以被多个应用共享。

**Q: 如何更新到新版本？**
A: 手动下载新版本安装包并安装。安装程序会自动覆盖旧版本，VxKex 配置会保留。

**Q: 为什么安装后看不到 VxKex 窗口？**
A: VxKex 是后台兼容层，没有用户界面。您只需正常使用 Clash Verge Win7 即可。

---

**版本**: 1.0.0
**最后更新**: 2025-12-14
**维护**: Clash Verge Rev 社区
