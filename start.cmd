@echo off
setlocal EnableExtensions EnableDelayedExpansion
title Driver Export Utility Menu v1.0.0
color 0A
mode con: cols=90 lines=32

:: =======================
:: ExportDriversMenu.cmd
:: Volá PS1 skripty zo Scripts\
:: =======================

:: --- Admin check ---
>nul 2>&1 net session || (
  echo.
  echo [!] Please run this CMD as Administrator.
  echo.
  pause
  exit /b 1
)

:: --- Cesty ---
set "ROOT=%~dp0"
set "ROOT=%ROOT:~,-1%"
set "SCRIPTS=%ROOT%\Scripts"

if not exist "%SCRIPTS%\Export_ByClass.ps1" (
  echo [!] Nenajdeny priecinok "Scripts" alebo PS1 skripty. Ocakavane: %SCRIPTS%
  pause
  exit /b 1
)

:: --- Predvolené hodnoty ---
set "OUTBASE=C:\DriverExports"
set "ZIP=1"

:MENU
cls
echo ============================================================
echo                 DRIVER EXPORT MENU (CMD)
echo ============================================================
echo   Base folder (OutBase): %OUTBASE%
echo   Zip after export     : %ZIP%
echo ------------------------------------------------------------
echo   1) Export ALL (3rd-party)
echo   2) Export NON-Microsoft (alias ALL)
echo   3) Export BY CLASS (choose from menu)
echo   4) Export SPECIFIC (INF alebo HWID)
echo   5) Toggle ZIP (0/1)
echo   6) Change destination folder
echo   7) Open destination folder in Explorer
echo   0) Exit
echo ------------------------------------------------------------
echo.
choice /c 12345670 /n /m "Choose option: "
set "CH=%ERRORLEVEL%"

if "%CH%"=="1" call :RUN_ALL & goto MENU
if "%CH%"=="2" call :RUN_NONMS & goto MENU
if "%CH%"=="3" call :RUN_BYCLASS_MENU & goto MENU
if "%CH%"=="4" call :RUN_SPECIFIC & goto MENU
if "%CH%"=="5" if "%ZIP%"=="0" (set "ZIP=1") else (set "ZIP=0") & goto MENU
if "%CH%"=="6" call :SET_OUTBASE & goto MENU
if "%CH%"=="7" if exist "%OUTBASE%" start "" explorer "%OUTBASE%" & goto MENU
if "%CH%"=="8" goto END
goto MENU

:: ---------------------------
:: Bežné volanie PowerShellu
:: ---------------------------
:PSCALL
set "ZIPSWITCH="
if "%ZIP%"=="1" set "ZIPSWITCH=-Zip"
powershell -NoProfile -ExecutionPolicy Bypass %*
set "ERR=%ERRORLEVEL%"
if not "%ERR%"=="0" (
  echo.
  echo [!] Skript skoncil s chybou (exitcode %ERR%).
  pause
) else (
  echo.
  echo [+] Hotovo.
  echo     (Pozn.: PS skript vytvoril casovo-oznaceny priecinok v %OUTBASE%)
  pause
)
exit /b

:: ---------------------------
:: Akcie menu
:: ---------------------------
:RUN_ALL
if exist "%SCRIPTS%\Export_All.ps1" (
  call :PSCALL -File "%SCRIPTS%\Export_All.ps1" -OutBase "%OUTBASE%" %ZIPSWITCH%
) else (
  echo [!] Export_All.ps1 not found
  pause
)
exit /b

:RUN_NONMS
if exist "%SCRIPTS%\Export_NonMS.ps1" (
  call :PSCALL -File "%SCRIPTS%\Export_NonMS.ps1" -OutBase "%OUTBASE%" %ZIPSWITCH%
) else (
  echo [!] Export_NonMS.ps1 not found
  pause
)
exit /b

:RUN_BYCLASS_MENU
cls
echo ================= Select categories ======================
echo   Select category (press number or letter)
echo.
echo   1) Mouse           8) Printer        E) Sensors
echo   2) Keyboard        9) Chipset        F) System
echo   3) Display         A) Storage        
echo   4) Network         B) USB            X) EXPORT selected
echo   5) Audio           C) HID            0) Back to main menu
echo   6) Bluetooth       D) Battery        
echo   7) Camera          
echo =========================================================
echo.

set "CLS="
set "NAMES="

:CLASS_SELECT_LOOP
choice /c 123456789ABCDEFX0 /n /m "Choose category (X=export, 0=back): "
set "SEL=%ERRORLEVEL%"

:: 0 = spat do menu
if "%SEL%"=="18" (
  echo.
  echo [i] Back to main menu...
  timeout /t 1 >nul
  exit /b
)

:: X = finish and export
if "%SEL%"=="17" goto CLASS_EXPORT

:: Mapovanie choice cisiel na triedy
if "%SEL%"=="1" call :ADD_TO_CLS "Mouse,HIDClass" "Mouse"
if "%SEL%"=="2" call :ADD_TO_CLS "Keyboard,HIDClass" "Keyboard"
if "%SEL%"=="3" call :ADD_TO_CLS "Display" "Display"
if "%SEL%"=="4" call :ADD_TO_CLS "Net" "Network"
if "%SEL%"=="5" call :ADD_TO_CLS "Media" "Audio"
if "%SEL%"=="6" call :ADD_TO_CLS "Bluetooth" "Bluetooth"
if "%SEL%"=="7" call :ADD_TO_CLS "Camera,Image" "Camera"
if "%SEL%"=="8" call :ADD_TO_CLS "Printer" "Printer"
if "%SEL%"=="9" call :ADD_TO_CLS "System,HDC,SoftwareDevice" "Chipset"
if "%SEL%"=="10" call :ADD_TO_CLS "SCSIAdapter,DiskDrive,StorageVolume" "Storage"
if "%SEL%"=="11" call :ADD_TO_CLS "USB" "USB"
if "%SEL%"=="12" call :ADD_TO_CLS "HIDClass" "HID"
if "%SEL%"=="13" call :ADD_TO_CLS "Battery" "Battery"
if "%SEL%"=="14" call :ADD_TO_CLS "Sensor" "Sensors"
if "%SEL%"=="15" call :ADD_TO_CLS "System" "System"

echo   Current: %NAMES%
echo.
goto CLASS_SELECT_LOOP

:CLASS_EXPORT
if not defined CLS (
  echo.
  echo [!] No category selected.
  timeout /t 2 >nul
  exit /b
)

:: Vytvor názov priečinka na základe vybraných kategórií
set "FOLDERNAME=%NAMES:+=-%"

echo.
echo Export category: %NAMES%
echo Folder name: %FOLDERNAME%
call :PSCALL -File "%SCRIPTS%\Export_ByClass.ps1" -Classes "%CLS%" -CategoryName "%FOLDERNAME%" -OutBase "%OUTBASE%" %ZIPSWITCH%
exit /b

:ADD_TO_CLS
set "CLASSES=%~1"
set "NAME=%~2"
if defined CLS (
  set "CLS=%CLS%,%CLASSES%"
  set "NAMES=%NAMES%+%NAME%"
) else (
  set "CLS=%CLASSES%"
  set "NAMES=%NAME%"
)
echo   [+] Added: %NAME%
exit /b

:RUN_SPECIFIC
set "INF="
set "HWID="
echo.
set /p "INF=INF name (optional, e.g. oem42.inf or synmous.inf): " <con
set /p "HWID=HardwareId fragment (optional, e.g. VID_046D or PCI\VEN_8086): " <con
if "%INF%%HWID%"=="" (
  echo [!] Enter at least INF or HWID.
  timeout /t 2 >nul
  exit /b
)
if exist "%SCRIPTS%\Export_Specific.ps1" (
  call :PSCALL -File "%SCRIPTS%\Export_Specific.ps1" -InfName "%INF%" -HardwareId "%HWID%" -OutBase "%OUTBASE%" %ZIPSWITCH%
) else (
  echo [!] Export_Specific.ps1 not found
  pause
)
exit /b

:SET_OUTBASE
echo.
echo Current OutBase: %OUTBASE%
set /p "NEWBASE=Enter new destination folder (e.g. D:\DriverExports): " <con
if "%NEWBASE%"=="" (
  echo [!] Unchanged.
  timeout /t 1 >nul
  exit /b
)
set "OUTBASE=%NEWBASE%"
echo [+] New OutBase: %OUTBASE%
timeout /t 2 >nul
exit /b

:END
cls
echo Exiting...
timeout /t 1 >nul
exit