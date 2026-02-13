@echo off
cd /d "%~dp0"
echo ==========================================
echo IT Passport App - Update Dependencies
echo ==========================================

REM Attempt to add local Desktop flutter path
set "FLUTTER_PATH=%~dp0..\flutter\bin"
if exist "%FLUTTER_PATH%\flutter.bat" (
    echo Found Flutter on Desktop. Adding to PATH temporarily...
    set "PATH=%FLUTTER_PATH%;%PATH%"
)

echo.
echo Installing dependencies (shared_preferences, etc.)...
call flutter pub get
if %errorlevel% neq 0 (
    echo.
    echo [ERROR] Failed to run 'flutter pub get'.
    pause
    exit /b %errorlevel%
)

echo.
echo Dependencies updated!
pause
