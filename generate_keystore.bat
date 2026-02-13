@echo off
setlocal
cd /d "%~dp0"

echo ==========================================
echo IT Passport App - Key Generation (Updated)
echo ==========================================

REM Defines possible paths for keytool
set "KT_PATH_1=C:\Program Files\Android\Android Studio\jbr\bin\keytool.exe"
set "KT_PATH_2=C:\Program Files\Android\Android Studio\jre\bin\keytool.exe"
set "KT_PATH_3=C:\Program Files\Java\jdk-17\bin\keytool.exe"
set "KT_PATH_4=C:\Program Files\Eclipse Adoptium\jdk-17.0.8.7-hotspot\bin\keytool.exe"

echo Checking for keytool...

if exist "%KT_PATH_1%" (
    set "KEYTOOL=%KT_PATH_1%"
    goto Found
)
if exist "%KT_PATH_2%" (
    set "KEYTOOL=%KT_PATH_2%"
    goto Found
)
if exist "%KT_PATH_3%" (
    set "KEYTOOL=%KT_PATH_3%"
    goto Found
)

REM Check PATH
where keytool >nul 2>&1
if %errorlevel% equ 0 (
    set "KEYTOOL=keytool"
    goto Found
)

echo.
echo [ERROR] Could not find keytool automatically.
echo Please locate 'keytool.exe' manually.
echo It is usually in "C:\Program Files\Android\Android Studio\jbr\bin"
echo or inside a JDK "bin" folder.
echo.
set /p KEYTOOL="Enter full path to keytool.exe (or drag and drop here): "

:Found
echo Using: "%KEYTOOL%"

set "KEYSTORE_PATH=android\app\upload-keystore.jks"
set "KEY_PROPERTIES_PATH=android\key.properties"

if not exist "android\app" mkdir "android\app"

if exist "%KEYSTORE_PATH%" (
    echo.
    echo [WARNING] Keystore already exists.
    goto CreateProperties
)

echo.
echo Generating keystore...
"%KEYTOOL%" -genkey -v -keystore "%KEYSTORE_PATH%" ^
    -storepass android -keypass android ^
    -alias upload -keyalg RSA -keysize 2048 -validity 10000 ^
    -dname "CN=IT Passport App, OU=Development, O=Personal, L=Tokyo, S=Tokyo, C=JP"

if %errorlevel% neq 0 (
    echo [ERROR] Generation failed.
    pause
    exit /b 1
)

:CreateProperties
echo.
echo Creating key.properties...
(
echo storePassword=android
echo keyPassword=android
echo keyAlias=upload
echo storeFile=upload-keystore.jks
) > "%KEY_PROPERTIES_PATH%"

echo.
echo Success!
pause
