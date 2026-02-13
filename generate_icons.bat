@echo off
cd /d "%~dp0"
echo ==========================================
echo IT Passport App - Generate Icons
echo ==========================================

REM Attempt to add local Desktop flutter path
set "FLUTTER_PATH=%~dp0..\flutter\bin"
if exist "%FLUTTER_PATH%\flutter.bat" (
    echo Found Flutter on Desktop. Adding to PATH temporarily...
    set "PATH=%FLUTTER_PATH%;%PATH%"
)

echo.
echo Running flutter_launcher_icons...
call flutter pub run flutter_launcher_icons

if %errorlevel% neq 0 (
    echo.
    echo [ERROR] Icon generation failed.
    pause
    exit /b %errorlevel%
)

echo.
echo Icons generated successfully!
pause
