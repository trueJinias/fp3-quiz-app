@echo off
cd /d "%~dp0"
echo ==========================================
echo Quiz App Template - Project Setup
echo ==========================================

REM Attempt to add local Desktop flutter path
set "FLUTTER_PATH=%~dp0..\flutter\bin"
if exist "%FLUTTER_PATH%\flutter.bat" (
    echo Found Flutter on Desktop. Adding to PATH temporarily...
    set "PATH=%FLUTTER_PATH%;%PATH%"
) else (
    echo Flutter not found in %FLUTTER_PATH%
    echo Assuming Flutter is in global PATH...
)

echo.
echo [1/2] Generating platform files (Android/iOS/Web)...
call flutter create . --project-name=quiz_app_template
if %errorlevel% neq 0 (
    echo.
    echo [ERROR] Failed to run 'flutter create'. 
    echo Please make sure Flutter is installed.
    pause
    exit /b %errorlevel%
)

echo.
echo [2/2] Installing dependencies...
call flutter pub get
if %errorlevel% neq 0 (
    echo.
    echo [ERROR] Failed to run 'flutter pub get'.
    pause
    exit /b %errorlevel%
)

echo.
echo ==========================================
echo Setup completed successfully!
echo You can now run the app using 'flutter run'.
echo ==========================================
pause
