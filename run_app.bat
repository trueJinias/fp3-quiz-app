@echo off
cd /d "%~dp0"
echo ==========================================
echo IT Passport App - Launching...
echo ==========================================

REM Attempt to add local Desktop flutter path
set "FLUTTER_PATH=%~dp0..\flutter\bin"
if exist "%FLUTTER_PATH%\flutter.bat" (
    echo Found Flutter on Desktop. Adding to PATH temporarily...
    set "PATH=%FLUTTER_PATH%;%PATH%"
)

echo.
echo Select a device when prompted (or it will auto-select Windows/Chrome).
call flutter run
pause
