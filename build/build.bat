@echo off
echo Starting to build cvcli.exe...

REM Compile using luastatic
luastatic cvcli.lua -o cvcli.exe

REM Check if the compilation was successful
if %ERRORLEVEL% NEQ 0 (
    echo Compilation failed. Please ensure luastatic and GCC are installed correctly.
    exit /b 1
)

echo Build successful!

REM Create ZIP package
echo Creating release_win64.zip...
if exist release_win64.zip del release_win64.zip
powershell -Command "Compress-Archive -Path cvcli.exe, install.bat, cvcli.yml -DestinationPath release_win64.zip -Force"

echo Done! release_win64.zip has been created.