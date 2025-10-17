@echo off
setlocal EnableDelayedExpansion

:: =============================================
:: 🧰 Universal CMD Launcher for PowerShell Script
:: =============================================

:: Get script directory (works anywhere)
set "ScriptDir=%~dp0"
set "PS1File=%ScriptDir%Export_drivers_zip.ps1"

:: Check if PowerShell script exists
if not exist "%PS1File%" (
    echo ❌ PowerShell script not found: "%PS1File%"
    echo Make sure the file Export_drivers_zip.ps1 is in the same folder as this CMD file.
    pause
    exit /b 1
)

:: Check if running as Administrator
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo 🔒 Requesting Administrator privileges...
    powershell -Command "Start-Process '%~f0' -Verb RunAs"
    exit /b
)

:: Run PowerShell script with unrestricted execution policy
echo 🚀 Running PowerShell script: Export_drivers_zip.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File "%PS1File%"

echo.
echo ✅ Script finished successfully.
pause
