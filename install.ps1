# ==========================================
# Kanata 便携版自动注册脚本 (防多开 + 最高权限版)
# ==========================================

# --- 1. 自动获取管理员权限 ---
$CurrentIdentity = [Security.Principal.WindowsIdentity]::GetCurrent()
$CurrentPrincipal = [Security.Principal.WindowsPrincipal]$CurrentIdentity
if (-not $CurrentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "正在请求管理员权限..." -ForegroundColor Yellow
    $ProcessInfo = New-Object System.Diagnostics.ProcessStartInfo
    $ProcessInfo.FileName = "powershell.exe"
    $ProcessInfo.Arguments = "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`""
    $ProcessInfo.Verb = "RunAs"
    try { [System.Diagnostics.Process]::Start($ProcessInfo) } catch { Write-Error "拒绝权限，退出。" }
    exit
}

# --- 2. 修正工作目录 ---
$CurrentDir = $PSScriptRoot
if (-not $CurrentDir) { $CurrentDir = Split-Path -Parent $MyInvocation.MyCommand.Definition }
Set-Location $CurrentDir

Write-Host "当前工作目录: $CurrentDir" -ForegroundColor Cyan

# --- 3. 自动寻找 Kanata ---
$KanataExe = Get-ChildItem -Path $CurrentDir -Filter "kanata*.exe" | Select-Object -First 1
if (-not $KanataExe) {
    Write-Error "❌ 未找到 Kanata exe 文件！"
    Start-Sleep -Seconds 5; exit
}
Write-Host "✅ Kanata: $($KanataExe.Name)" -ForegroundColor Green

# --- 4. 自动寻找 Config ---
$ConfigFile = Get-ChildItem -Path $CurrentDir -Filter "*.kbd" | Select-Object -First 1
if (-not $ConfigFile) { $ConfigName = "kanata.kbd" } else { $ConfigName = $ConfigFile.Name }
Write-Host "✅ Config: $ConfigName" -ForegroundColor Green

# --- 5. 动态生成 VBS (加入杀进程逻辑) ---
$VbsPath = Join-Path $CurrentDir "start_hidden.vbs"

# VBS 逻辑：
# 1. 遍历进程列表，找到名字包含 "kanata" 的进程并终止它
# 2. 启动新的 Kanata
$VbsContent = @"
Set WshShell = CreateObject("WScript.Shell")
Set objWMIService = GetObject("winmgmts:\\.\root\cimv2")

' --- 1. 杀死旧进程 ---
' 查找所有名字里包含 kanata 的进程 (模糊匹配以防万一)
Set colItems = objWMIService.ExecQuery("Select * from Win32_Process Where Name Like '%kanata%'")
For Each objItem in colItems
    ' 强制终止
    objItem.Terminate()
Next

' 等待 0.5 秒确保进程完全释放
WScript.Sleep 500

' --- 2. 启动新进程 ---
strCmd = Chr(34) & "$($KanataExe.Name)" & Chr(34) & " --cfg " & Chr(34) & "$ConfigName" & Chr(34)
WshShell.Run strCmd, 0, False
"@

Set-Content -Path $VbsPath -Value $VbsContent -Encoding Ascii
Write-Host "✅ VBS 脚本已生成 (包含防重启动逻辑)" -ForegroundColor Green

# --- 6. 注册计划任务 ---
$TaskName = "KanataAutoStart_Portable"
$ActionExe = "wscript.exe"
$ActionArg = "`"$VbsPath`""
$Trigger = New-ScheduledTaskTrigger -AtLogOn
$Action = New-ScheduledTaskAction -Execute $ActionExe -Argument $ActionArg -WorkingDirectory $CurrentDir
# 最高权限
$Principal = New-ScheduledTaskPrincipal -UserId $env:USERNAME -LogonType Interactive -RunLevel Highest
$Settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -ExecutionTimeLimit 0

Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false -ErrorAction SilentlyContinue
Register-ScheduledTask -TaskName $TaskName -Trigger $Trigger -Action $Action -Principal $Principal -Settings $Settings -Force | Out-Null

Write-Host "`n🎉 完美版安装完成！" -ForegroundColor Yellow
Write-Host "-------------------------------------"
Write-Host "1. 每次启动前会自动清理旧的 Kanata 进程。"
Write-Host "2. 拥有最高权限，可操作任务管理器。"
Write-Host "3. 无黑框静默运行。"
Write-Host "-------------------------------------"
Write-Host "👉 你现在可以多次双击 start_hidden.vbs 测试，系统中始终只会有一个 Kanata 在运行。"
Start-Sleep -Seconds 5
