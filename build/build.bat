@echo off
echo 开始构建 cvcli.exe...

REM 使用luastatic编译
luastatic cvcli.lua -o cvcli.exe

REM 检查编译是否成功
if %ERRORLEVEL% NEQ 0 (
    echo 编译失败，请确认luastatic和GCC已正确安装
    exit /b 1
)

echo 构建成功！

REM 创建ZIP包
echo 正在创建release_win64.zip...
if exist release_win64.zip del release_win64.zip
powershell -Command "Compress-Archive -Path cvcli.exe, install.bat, cvcli.yml -DestinationPath release_win64.zip -Force"

echo 完成！release_win64.zip已创建