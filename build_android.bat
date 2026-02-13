@echo off
cd /d "%~dp0"
echo ==========================================
echo Quiz App Template - Build Android Release
echo ==========================================

REM Attempt to add local Desktop flutter path
set "FLUTTER_PATH=%~dp0..\flutter\bin"
if exist "%FLUTTER_PATH%\flutter.bat" (
    echo Found Flutter on Desktop. Adding to PATH temporarily...
    set "PATH=%FLUTTER_PATH%;%PATH%"
)

echo.
echo Building App Bundle (AAB)...
echo This may take a few minutes.
echo.

call flutter build appbundle

if %errorlevel% neq 0 (
    echo.
    echo [ERROR] Build failed.
    pause
    exit /b %errorlevel%
)

echo.
echo Build Successful!
echo File located at: build\app\outputs\bundle\release\app-release.aab
echo.
echo This file is ready to be uploaded to Google Play Console.
pause
