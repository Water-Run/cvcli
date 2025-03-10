@echo off
setlocal EnableDelayedExpansion

REM 以管理员权限检查
net session >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo 请右键点击install.bat并选择"以管理员身份运行"
    pause
    exit /b 1
)

REM 定义安装路径
set INSTALL_DIR=C:\Program Files\cvcli

echo 正在安装 cvcli 到 %INSTALL_DIR%...

REM 创建目标目录
if not exist "%INSTALL_DIR%" (
    mkdir "%INSTALL_DIR%"
    if !ERRORLEVEL! NEQ 0 (
        echo 创建目录失败: %INSTALL_DIR%
        pause
        exit /b 1
    )
)

REM 拷贝文件
echo 正在复制文件...
copy /Y "cvcli.exe" "%INSTALL_DIR%"
if not exist "%INSTALL_DIR%\cvcli.yml" (
    copy /Y "cvcli.yml" "%INSTALL_DIR%"
) else (
    echo cvcli.yml已存在，保留现有配置文件...
)

REM 设置环境变量
echo 正在配置环境变量...
setx PATH "%PATH%;%INSTALL_DIR%" /M
if %ERRORLEVEL% NEQ 0 (
    echo 环境变量设置失败
    pause
    exit /b 1
)

echo.
echo 安装完成！
echo cvcli已安装至 %INSTALL_DIR%
echo 已添加到系统PATH环境变量
echo.
echo 请重新打开命令提示符或PowerShell窗口以使环境变量生效
echo.
echo 使用示例:
echo   cvcli -w mykey "some text"  添加或更新一个键值对
echo   cvcli mykey                 读取键值并复制到剪贴板
echo   cvcli -l                    读取上次使用的键值
echo.

pause