@echo off
setlocal EnableDelayedExpansion

REM Check for administrator privileges
net session >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo Please right-click on install.bat and select "Run as administrator"
    pause
    exit /b 1
)

REM Define installation path
set INSTALL_DIR=C:\Program Files\cvcli

echo Installing cvcli to %INSTALL_DIR%...

REM Create target directory
if not exist "%INSTALL_DIR%" (
    mkdir "%INSTALL_DIR%"
    if !ERRORLEVEL! NEQ 0 (
        echo Failed to create directory: %INSTALL_DIR%
        pause
        exit /b 1
    )
)

REM Copy files
echo Copying files...
copy /Y "cvcli.exe" "%INSTALL_DIR%"
if not exist "%INSTALL_DIR%\cvcli.yml" (
    copy /Y "cvcli.yml" "%INSTALL_DIR%"
) else (
    echo cvcli.yml already exists, keeping the current configuration file...
)

REM Set environment variable
echo Configuring environment variables...
setx PATH "%PATH%;%INSTALL_DIR%" /M
if %ERRORLEVEL% NEQ 0 (
    echo Failed to set environment variable
    pause
    exit /b 1
)

echo.
echo Installation complete!
echo cvcli has been installed to %INSTALL_DIR%
echo Added to the system PATH environment variable
echo.
echo Please reopen the Command Prompt or PowerShell window to apply the environment variable
echo.
echo Usage examples:
echo   cvcli -w mykey "some text"  Add or update a key-value pair
echo   cvcli mykey                 Read a value and copy it to the clipboard
echo   cvcli -l                    Read the last used value
echo.

pause