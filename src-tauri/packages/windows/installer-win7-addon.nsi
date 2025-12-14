; ============================================================================
; Clash Verge Win7 - VxKex 自动安装和配置扩展
; ============================================================================
; 此文件包含 VxKex 安装和配置的 NSIS 代码段
; 需要插入到 installer.nsi 的适当位置
; ============================================================================

; ============================================================================
; 变量定义（添加到文件开头）
; ============================================================================
!define VXKEX_INSTALLER "vxkex\KexSetup.exe"
!define VXKEX_CONFIG_SCRIPT "vxkex\configure-vxkex.ps1"
!define VXKEX_INSTALL_DIR "$PROGRAMFILES\VxKex"

Var VxKexInstallNeeded
Var VxKexInstallSuccess

; ============================================================================
; 检测系统版本函数
; ============================================================================
Function CheckWindowsVersion
    ${If} ${IsWin7}
        StrCpy $VxKexInstallNeeded "1"
        DetailPrint "检测到 Windows 7 系统，将自动安装 VxKex"
    ${ElseIf} ${IsWin8}
        StrCpy $VxKexInstallNeeded "0"
        DetailPrint "检测到 Windows 8/8.1 系统，无需安装 VxKex"
    ${ElseIf} ${IsWin10}
        StrCpy $VxKexInstallNeeded "0"
        DetailPrint "检测到 Windows 10+ 系统，无需安装 VxKex"
    ${Else}
        StrCpy $VxKexInstallNeeded "0"
        DetailPrint "未知系统版本"
    ${EndIf}
FunctionEnd

; ============================================================================
; 安装 VxKex
; ============================================================================
Function InstallVxKex
    ${If} $VxKexInstallNeeded == "1"
        DetailPrint "正在安装 VxKex 兼容层..."

        ; 检查 VxKex 安装程序是否存在
        ${If} ${FileExists} "$INSTDIR\${VXKEX_INSTALLER}"
            ; 静默安装 VxKex
            ; /S = 静默模式
            ; /D = 安装目录（必须是最后一个参数）
            ExecWait '"$INSTDIR\${VXKEX_INSTALLER}" /S /D=${VXKEX_INSTALL_DIR}' $0

            ${If} $0 == 0
                DetailPrint "VxKex 安装成功"
                StrCpy $VxKexInstallSuccess "1"
            ${Else}
                DetailPrint "VxKex 安装失败，错误代码: $0"
                StrCpy $VxKexInstallSuccess "0"
                MessageBox MB_ICONEXCLAMATION|MB_OK "VxKex 安装失败（错误代码: $0）$\n$\n这可能导致程序无法在 Windows 7 上正常运行。$\n$\n请手动安装 VxKex 或访问项目文档查看详细说明。"
            ${EndIf}
        ${Else}
            DetailPrint "错误：未找到 VxKex 安装程序"
            StrCpy $VxKexInstallSuccess "0"
            MessageBox MB_ICONEXCLAMATION|MB_OK "安装包缺少 VxKex 组件$\n$\n请重新下载完整的安装包。"
        ${EndIf}
    ${Else}
        DetailPrint "跳过 VxKex 安装（非 Windows 7 系统）"
        StrCpy $VxKexInstallSuccess "0"
    ${EndIf}
FunctionEnd

; ============================================================================
; 配置 VxKex
; ============================================================================
Function ConfigureVxKex
    ${If} $VxKexInstallSuccess == "1"
        DetailPrint "正在配置 VxKex..."

        ; 检查 PowerShell 配置脚本是否存在
        ${If} ${FileExists} "$INSTDIR\${VXKEX_CONFIG_SCRIPT}"
            ; 运行 PowerShell 配置脚本
            ; -ExecutionPolicy Bypass = 绕过执行策略
            ; -NoProfile = 不加载用户配置文件
            ; -NonInteractive = 非交互模式
            ; -WindowStyle Hidden = 隐藏窗口
            nsExec::ExecToLog 'powershell.exe -ExecutionPolicy Bypass -NoProfile -NonInteractive -WindowStyle Hidden -File "$INSTDIR\${VXKEX_CONFIG_SCRIPT}" -InstallDir "$INSTDIR"'
            Pop $0

            ${If} $0 == 0
                DetailPrint "VxKex 配置成功"
            ${Else}
                DetailPrint "VxKex 配置失败，错误代码: $0"
                ; 配置失败不是致命错误，用户可以手动配置
            ${EndIf}
        ${Else}
            DetailPrint "警告：未找到 VxKex 配置脚本"
        ${EndIf}
    ${EndIf}
FunctionEnd

; ============================================================================
; 卸载 VxKex 配置
; ============================================================================
Function un.RemoveVxKexConfig
    DetailPrint "正在移除 VxKex 配置..."

    ; 移除注册表配置
    DeleteRegKey HKLM "SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\Clash Verge Win7.exe"
    DeleteRegKey HKLM "SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\clash-verge-service.exe"
    DeleteRegKey HKLM "SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\install-service.exe"
    DeleteRegKey HKLM "SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\uninstall-service.exe"

    DetailPrint "VxKex 配置已移除"
    DetailPrint "注意：VxKex 程序本身未被卸载，如需完全删除请手动卸载"
FunctionEnd

; ============================================================================
; 安装部分集成说明
; ============================================================================
; 需要在主安装段 (Section "install") 中添加以下调用：
;
; 1. 在文件复制之前调用：
;    Call CheckWindowsVersion
;
; 2. 在所有文件复制完成后调用：
;    Call InstallVxKex
;    Call ConfigureVxKex
;
; 3. 在卸载段 (Section "Uninstall") 中添加：
;    Call un.RemoveVxKexConfig

; ============================================================================
; 完成页面自定义消息
; ============================================================================
!define MUI_FINISHPAGE_RUN_TEXT "立即运行 Clash Verge Win7"
!define MUI_FINISHPAGE_SHOWREADME
!define MUI_FINISHPAGE_SHOWREADME_TEXT "查看 Windows 7 使用说明"
!define MUI_FINISHPAGE_SHOWREADME_FUNCTION ShowWin7Readme

Function ShowWin7Readme
    ${If} ${FileExists} "$INSTDIR\WIN7_README.txt"
        ExecShell "open" "$INSTDIR\WIN7_README.txt"
    ${EndIf}
FunctionEnd
