@echo off

rem Set paths
set SRLUA=srglue.exe
set SRLUA_MAIN=srlua.exe
set LUA_FILE=..\code\cvcli.lua
set OUTPUT=cvcli.exe

rem Check if srglue.exe exists
if not exist "%SRLUA%" (
    echo Error: %SRLUA% not found.
    exit /b 1
)

rem Check if srlua.exe exists
if not exist "%SRLUA_MAIN%" (
    echo Error: %SRLUA_MAIN% not found.
    exit /b 1
)

rem Check if Lua file exists
if not exist "%LUA_FILE%" (
    echo Error: Lua file %LUA_FILE% not found.
    exit /b 1
)

rem Build the executable
echo Generating %OUTPUT%...
"%SRLUA%" "%SRLUA_MAIN%" "%LUA_FILE%" "%OUTPUT%"

if %errorlevel% neq 0 (
    echo Error: Build failed.
    exit /b 1
)

echo Build complete: %OUTPUT%