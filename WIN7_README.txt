========================================
  Clash Verge Win7 - Windows 7 专版
========================================

欢迎使用 Clash Verge Win7！

本版本专为 Windows 7 系统优化，包含以下特性：

✅ 完整的 Windows 7 兼容性支持
✅ 自动安装和配置 VxKex 兼容层
✅ 内置 WebView2 运行时（无需联网下载）
✅ 独立版本标识（不与主版本冲突）

========================================
  首次启动指南
========================================

1. 如果安装在 Windows 7 系统上：
   - VxKex 已自动安装到 C:\Program Files\VxKex\
   - 所有必要的配置已自动完成
   - 您可以直接运行程序

2. 如果程序无法启动：
   - 确认您以管理员身份运行了安装程序
   - 查看 WIN7_VXKEX_README.md 获取详细故障排除指南
   - 尝试手动运行配置脚本（见下方）

========================================
  手动配置 VxKex（仅在需要时使用）
========================================

如果自动配置失败，请按以下步骤操作：

1. 右键点击"开始"→"所有程序"→"附件"→"Windows PowerShell"
2. 选择"以管理员身份运行"
3. 执行以下命令：

   cd "C:\Program Files\Clash Verge Win7\vxkex"
   Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
   .\configure-vxkex.ps1

4. 等待脚本完成，重启程序

========================================
  重要提示
========================================

⚠️ 此版本不包含自动更新功能
   - 请定期访问项目页面检查更新
   - 手动下载新版本并重新安装

⚠️ 仅适用于 Windows 7 系统
   - Windows 8/10/11 用户请使用标准版本

⚠️ 需要管理员权限
   - VxKex 配置需要管理员权限
   - 部分功能（如系统代理）需要管理员权限

========================================
  获取帮助
========================================

📖 详细文档: 查看 WIN7_VXKEX_README.md
🐛 问题反馈: https://github.com/clash-verge-rev/clash-verge-rev/issues
💬 社区讨论: https://github.com/clash-verge-rev/clash-verge-rev/discussions

========================================
  技术说明
========================================

本版本使用以下技术实现 Windows 7 兼容性：

• VxKex (VxKextended Kernel Extensions)
  - GitHub: https://github.com/i486/VxKex
  - 作用: 为 Windows 7 提供 Windows 8+ API 支持

• WebView2 运行时 109.0.1518.78
  - 最后支持 Windows 7 的版本
  - 固定版本，内置于安装包

感谢使用 Clash Verge Win7！
