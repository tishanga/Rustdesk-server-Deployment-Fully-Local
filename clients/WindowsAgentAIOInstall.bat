:: ========IMPORATANT THIS BAT FILE DOES NOT SUPPORT WIN 7  DONWLOAD THE 32bit EXE FROM RUSTDESK WEBISTE ANN PACKAGE IT WITH THIS IF WIN7 THEN RUSTDESK 32BIT WILL INSTALL AUTOMATICALLY=================
@echo off
title RustDesk Easy Installer
setlocal EnableDelayedExpansion

:: ================= USER CONFIG =================
set RUSTDESK_CFG="REPLACE THE CONFIGRATION KEY HERE"
:: ===============================================

:: Get the script directory
set "SCRIPT_DIR=%~dp0"

:: Run as Administrator
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo Requesting Administrator privileges...
    powershell -Command "Start-Process '%~f0' -Verb RunAs"
    exit /b
)

echo Generating random password...
for /f %%P in ('powershell -NoProfile -Command "$pw=(-join ((65..90)+(97..122)|Get-Random -Count 12|%%{[char]$_})); Write-Output $pw"') do set RUSTDESK_PW=%%P

echo Fetching latest RustDesk version...
for /f %%V in ('powershell -NoProfile -Command "(Invoke-WebRequest https://github.com/rustdesk/rustdesk/releases/latest -MaximumRedirection 0 -ErrorAction SilentlyContinue).Headers.Location.Split('/')[-1].Trim('v')"') do set RDLATEST=%%V

echo Latest version: %RDLATEST%

:: Check if installed
for /f "tokens=2,*" %%A in ('reg query "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\RustDesk" /v Version 2^>nul') do set RDVER=%%B

if "%RDVER%"=="%RDLATEST%" (
    echo RustDesk already installed.
    goto CONFIGURE
)

if not exist C:\Temp mkdir C:\Temp
cd /d C:\Temp

echo Downloading RustDesk...
powershell -NoProfile -Command "Invoke-WebRequest https://github.com/rustdesk/rustdesk/releases/download/%RDLATEST%/rustdesk-%RDLATEST%-x86_64.exe -OutFile rustdesk.exe"

:: CHECK IF DOWNLOAD FAILED - LOOK IN SCRIPT FOLDER
if not exist "rustdesk.exe" (
    echo.
    echo WARNING: Automatic download failed!
    echo Checking for RustDesk installer in script folder...
    
    :: Check in script folder for 64-bit installer (rename your file to: rustdesk-64bit.exe)
    if exist "%SCRIPT_DIR%rustdesk-64bit.exe" (
        echo Found 64-bit installer in script folder: rustdesk-64bit.exe
        copy /y "%SCRIPT_DIR%rustdesk-64bit.exe" "rustdesk.exe"
        echo Using pre-downloaded 64-bit installer...
    ) else (
        :: Check for 32-bit installer (rename your file to: rustdesk-32bit.exe)
        if exist "%SCRIPT_DIR%rustdesk-32bit.exe" (
            echo Found 32-bit installer in script folder: rustdesk-32bit.exe
            copy /y "%SCRIPT_DIR%rustdesk-32bit.exe" "rustdesk.exe"
            echo Using pre-downloaded 32-bit installer...
        ) else (
            :: Check for generic installer (rename your file to: rustdesk-setup.exe)
            if exist "%SCRIPT_DIR%rustdesk-setup.exe" (
                echo Found generic installer in script folder: rustdesk-setup.exe
                copy /y "%SCRIPT_DIR%rustdesk-setup.exe" "rustdesk.exe"
                echo Using pre-downloaded generic installer...
            ) else (
                :: Check for any rustdesk*.exe in script folder
                for /r "%SCRIPT_DIR%" %%f in (rustdesk*.exe) do (
                    if exist "%%f" (
                        echo Found RustDesk installer: %%~nxf
                        copy /y "%%f" "rustdesk.exe"
                        echo Using found installer...
                        goto INSTALL_NOW
                    )
                )
                
                echo.
                echo ERROR: No RustDesk installer found!
                echo.
                echo Please place RustDesk installer in the same folder as this script.
                echo Rename it to one of these names:
                echo   - rustdesk-64bit.exe (for 64-bit)
                echo   - rustdesk-32bit.exe (for 32-bit)
                echo   - rustdesk-setup.exe (any version)
                echo   - Or any file starting with 'rustdesk' and ending with '.exe'
                echo.
                echo Then run this script again.
                echo.
                pause
                exit /b 1
            )
        )
    )
)

:INSTALL_NOW
echo Installing RustDesk...
start /wait rustdesk.exe --silent-install
timeout /t 10 >nul

:: Install service
cd /d "%ProgramFiles%\RustDesk"
rustdesk.exe --install-service
timeout /t 10 >nul

:CONFIGURE
cd /d "%ProgramFiles%\RustDesk"

echo Applying configuration...
rustdesk.exe --config %RUSTDESK_CFG%
rustdesk.exe --password %RUSTDESK_PW%

for /f %%I in ('rustdesk.exe --get-id') do set RDID=%%I

echo.
echo =====================================
echo RustDesk ID  : %RDID%
echo Password    : %RUSTDESK_PW%
echo =====================================
echo.

pause
start rustdesk.exe
exit