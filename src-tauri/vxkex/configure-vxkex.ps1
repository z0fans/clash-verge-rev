# ============================================================================
# VxKex 自动配置脚本 - Clash Verge Win7
# ============================================================================
# 功能：为 Clash Verge Win7 的所有可执行文件自动配置 VxKex
# 要求：需要管理员权限运行
# ============================================================================

param(
    [string]$InstallDir = $PSScriptRoot
)

# 设置错误处理
$ErrorActionPreference = "Stop"

# 输出函数
function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $color = switch ($Level) {
        "ERROR" { "Red" }
        "SUCCESS" { "Green" }
        "WARNING" { "Yellow" }
        default { "White" }
    }
    Write-Host "[$timestamp] [$Level] $Message" -ForegroundColor $color
}

# 检查管理员权限
function Test-Administrator {
    $currentUser = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    return $currentUser.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# 检查 VxKex 是否已安装
function Test-VxKexInstalled {
    $vxkexPath = "C:\Program Files\VxKex"
    $vxkexDll = Join-Path $vxkexPath "KexDll.dll"
    return (Test-Path $vxkexDll)
}

# 为指定的 exe 配置 VxKex
function Enable-VxKexForExecutable {
    param(
        [string]$ExeName,
        [string]$ExePath
    )

    try {
        Write-Log "正在为 $ExeName 配置 VxKex..."

        # 注册表路径
        $ifeoPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\$ExeName"

        # 创建或打开注册表项
        if (-not (Test-Path $ifeoPath)) {
            New-Item -Path $ifeoPath -Force | Out-Null
        }

        # 设置 VerifierDlls
        Set-ItemProperty -Path $ifeoPath -Name "VerifierDlls" -Value "KexDll.dll" -Type String -Force

        # 设置 VxKexFlags
        # 0x00000300 = Enable VxKex + Disable for child processes
        Set-ItemProperty -Path $ifeoPath -Name "VxKexFlags" -Value 0x00000300 -Type DWord -Force

        # 设置 VxKexDisableChildProcesses
        Set-ItemProperty -Path $ifeoPath -Name "VxKexDisableChildProcesses" -Value 1 -Type DWord -Force

        Write-Log "$ExeName 配置成功" "SUCCESS"
        return $true
    }
    catch {
        Write-Log "配置 $ExeName 失败: $_" "ERROR"
        return $false
    }
}

# 禁用指定 exe 的 VxKex
function Disable-VxKexForExecutable {
    param([string]$ExeName)

    try {
        $ifeoPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\$ExeName"
        if (Test-Path $ifeoPath) {
            Remove-Item -Path $ifeoPath -Recurse -Force
            Write-Log "$ExeName VxKex 配置已移除" "SUCCESS"
        }
        return $true
    }
    catch {
        Write-Log "移除 $ExeName VxKex 配置失败: $_" "ERROR"
        return $false
    }
}

# ============================================================================
# 主程序
# ============================================================================

Write-Log "==================================================="
Write-Log "Clash Verge Win7 - VxKex 自动配置工具"
Write-Log "==================================================="

# 检查管理员权限
if (-not (Test-Administrator)) {
    Write-Log "错误：此脚本需要管理员权限运行" "ERROR"
    Write-Log "请右键点击 PowerShell 并选择 '以管理员身份运行'" "ERROR"
    Read-Host "按 Enter 键退出..."
    exit 1
}

# 检查 VxKex 是否已安装
Write-Log "检查 VxKex 安装状态..."
if (-not (Test-VxKexInstalled)) {
    Write-Log "警告：未检测到 VxKex 安装" "WARNING"
    Write-Log "VxKex 应该已经通过安装程序自动安装" "WARNING"
    Write-Log "如果您看到此消息，请检查 VxKex 安装状态" "WARNING"
    $continue = Read-Host "是否继续配置? (Y/N)"
    if ($continue -ne "Y" -and $continue -ne "y") {
        exit 0
    }
}
else {
    Write-Log "VxKex 已安装" "SUCCESS"
}

# 获取安装目录（如果未指定）
if ($InstallDir -eq $PSScriptRoot) {
    # 脚本在 vxkex 子目录中，需要上移一级
    $InstallDir = Split-Path -Parent $PSScriptRoot
}

Write-Log "安装目录: $InstallDir"

# 需要配置 VxKex 的可执行文件列表
$executables = @(
    @{Name = "Clash Verge Win7.exe"; Path = $InstallDir},
    @{Name = "clash-verge-service.exe"; Path = Join-Path $InstallDir "resources"},
    @{Name = "install-service.exe"; Path = Join-Path $InstallDir "resources"},
    @{Name = "uninstall-service.exe"; Path = Join-Path $InstallDir "resources"}
)

# 配置计数
$successCount = 0
$failCount = 0

# 为每个可执行文件配置 VxKex
Write-Log ""
Write-Log "开始配置 VxKex..."
Write-Log ""

foreach ($exe in $executables) {
    $exeName = $exe.Name
    $exePath = Join-Path $exe.Path $exeName

    # 检查文件是否存在
    if (Test-Path $exePath) {
        if (Enable-VxKexForExecutable -ExeName $exeName -ExePath $exePath) {
            $successCount++
        }
        else {
            $failCount++
        }
    }
    else {
        Write-Log "警告：文件不存在 - $exePath" "WARNING"
        $failCount++
    }
}

# 输出结果
Write-Log ""
Write-Log "==================================================="
Write-Log "配置完成！"
Write-Log "成功: $successCount | 失败: $failCount"
Write-Log "==================================================="

if ($failCount -eq 0) {
    Write-Log "所有文件已成功配置 VxKex" "SUCCESS"
    Write-Log "您现在可以正常运行 Clash Verge Win7 了！" "SUCCESS"
}
else {
    Write-Log "部分文件配置失败，请检查错误信息" "WARNING"
}

Write-Log ""
Read-Host "按 Enter 键退出..."
exit 0
