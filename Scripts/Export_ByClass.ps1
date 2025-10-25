<# 
  Export_ByClass.ps1
  Exportuje ovládače pre zadané PnP triedy
  Použitie: .\Export_ByClass.ps1 -Classes "Mouse,HIDClass" -CategoryName "Mouse" -OutBase "C:\DriverExports" [-Zip]
#>
[CmdletBinding()]
param(
  [Parameter(Mandatory=$true)]
  [string]$Classes,           # Čiarkou oddelené triedy napr. "Mouse,HIDClass"
  
  [Parameter(Mandatory=$true)]
  [string]$CategoryName,      # Názov kategórie pre výstup napr. "Mouse"
  
  [Parameter(Mandatory=$false)]
  [string]$OutBase = "C:\DriverExports",
  
  [Parameter(Mandatory=$false)]
  [switch]$Zip
)

$ErrorActionPreference = 'Stop'

function Require-Admin {
  $id = [Security.Principal.WindowsIdentity]::GetCurrent()
  $p  = New-Object Security.Principal.WindowsPrincipal($id)
  if (-not $p.IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)) {
    throw "❌ Run PowerShell as Admin."
  }
}

Require-Admin

# Parsovanie tried
$ClassList = $Classes -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ }

if ($ClassList.Count -eq 0) {
  throw "❌ Neboli zadané žiadne triedy."
}

# GUID mapovanie pre známe triedy
$ClassGuidMap = @{
  'Mouse'          = '{4d36e96f-e325-11ce-bfc1-08002be10318}'
  'Keyboard'       = '{4d36e96b-e325-11ce-bfc1-08002be10318}'
  'HIDClass'       = '{745a17a0-74d3-11d0-b6fe-00a0c90f57da}'
  'Display'        = '{4d36e968-e325-11ce-bfc1-08002be10318}'
  'Net'            = '{4d36e972-e325-11ce-bfc1-08002be10318}'
  'Media'          = '{4d36e96c-e325-11ce-bfc1-08002be10318}'
  'Bluetooth'      = '{e0cbf06c-cd8b-4647-bb8a-263b43f0f974}'
  'Camera'         = '{ca3e7ab9-b4c3-4ae6-8251-579ef933890f}'
  'Image'          = '{6bdd1fc6-810f-11d0-bec7-08002be2092f}'
  'Printer'        = '{4d36e979-e325-11ce-bfc1-08002be10318}'
  'System'         = '{4d36e97d-e325-11ce-bfc1-08002be10318}'
  'HDC'            = '{4d36e96a-e325-11ce-bfc1-08002be10318}'
  'SoftwareDevice' = '{62f9c741-b25a-46ce-b54c-9bccce08b6f2}'
  'SCSIAdapter'    = '{4d36e97b-e325-11ce-bfc1-08002be10318}'
  'DiskDrive'      = '{4d36e967-e325-11ce-bfc1-08002be10318}'
  'StorageVolume'  = '{71a27cdd-812a-11d0-bec7-08002be2092f}'
  'USB'            = '{36fc9e60-c465-11cf-8056-444553540000}'
  'Battery'        = '{72631e54-78a4-11d0-bcf7-00aa00b7b32a}'
  'Sensor'         = '{5175d334-c371-4806-b3ba-71fd53c9258d}'
}

# Vytvor výstupný priečinok
$Timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$OutDir = Join-Path $OutBase "${CategoryName}_$Timestamp"
New-Item -ItemType Directory -Force -Path $OutDir | Out-Null
$Log = Join-Path $OutDir "Export_${CategoryName}.log"

Write-Host "==> Export drivers for: $CategoryName ($($ClassList -join ', '))" -ForegroundColor Cyan
Write-Host "==> Destination: $OutDir" -ForegroundColor Cyan

"=== Export_${CategoryName} $(Get-Date) ===" | Out-File -FilePath $Log -Encoding UTF8
"Classes: $($ClassList -join ', ')" | Out-File -FilePath $Log -Append -Encoding UTF8

# Zbierame zariadenia pre všetky triedy
$allDrivers = @()

foreach ($className in $ClassList) {
  Write-Host "==> Searching for class: $className" -ForegroundColor Yellow
  
  $guid = $ClassGuidMap[$className]
  
  if ($guid) {
    # Vyhľadaj podľa GUID
    $drivers = Get-CimInstance Win32_PnPSignedDriver -Filter "ClassGuid='$guid'"
  } else {
    # Vyhľadaj podľa názvu triedy
    $drivers = Get-CimInstance Win32_PnPSignedDriver -Filter "DeviceClass='$className'"
  }
  
  if ($drivers) {
    $allDrivers += $drivers
    Write-Host "   Found $($drivers.Count) devices in class $className" -ForegroundColor Green
  }
}

if (-not $allDrivers -or $allDrivers.Count -eq 0) {
  throw "❌ Nenašli sa žiadne zariadenia pre zadané triedy."
}

# Unikátne INF mená
$infList = $allDrivers |
  Where-Object { $_.InfName -and $_.InfName -match '\.inf$' } |
  Select-Object -ExpandProperty InfName -Unique

if (-not $infList -or $infList.Count -eq 0) {
  throw "❌ Could not find any INF packages."
}

Write-Host "📦 Found $($infList.Count) INF package(s): $($infList -join ', ')" -ForegroundColor Yellow

# Overenie pnputil
$pnputil = Join-Path $env:SystemRoot 'System32\pnputil.exe'
if (-not (Test-Path $pnputil)) {
  throw "❌ pnputil.exe not found: $pnputil"
}

# Export INF balíkov
foreach ($inf in $infList) {
  Write-Host "==> Exporting $inf ..." -ForegroundColor Cyan
  $redir = Join-Path $OutDir ("pnputil_{0}.txt" -f ($inf -replace '\.','_'))
  $args  = @('/export-driver', $inf, $OutDir)
  
  "`n-- pnputil $($args -join ' ') --" | Out-File -FilePath $Log -Append -Encoding UTF8
  
  $proc = Start-Process -FilePath $pnputil -ArgumentList $args -PassThru -Wait -NoNewWindow `
          -RedirectStandardOutput $redir -RedirectStandardError ($redir -replace '\.txt$','_err.txt')
  
  if ($proc.ExitCode -ne 0) {
    "pnputil exit code: $($proc.ExitCode)" | Out-File -FilePath $Log -Append -Encoding UTF8
    Write-Warning "⚠ Export $inf ended with code $($proc.ExitCode). See log $redir"
  } else {
    "OK: $inf" | Out-File -FilePath $Log -Append -Encoding UTF8
  }
}

# Súhrn zariadení
"`n=== Devices ===" | Out-File -FilePath $Log -Append -Encoding UTF8
$allDrivers | Select-Object DeviceName, Manufacturer, InfName, DriverVersion, DriverDate, DeviceClass |
  Sort-Object DeviceClass, InfName, DeviceName |
  Format-Table -Auto | Out-String |
  Out-File -FilePath $Log -Append -Encoding UTF8

# ZIP archív ak je požadovaný
if ($Zip) {
  $zipPath = "$OutDir.zip"
  Write-Host "==> Creating ZIP: $zipPath" -ForegroundColor Cyan
  Compress-Archive -Path (Join-Path $OutDir '*') -DestinationPath $zipPath -Force
  Write-Host "✅ ZIP completed: $zipPath" -ForegroundColor Green
}

Write-Host "==> Completed. Destination: $OutDir" -ForegroundColor Green
Write-Host "📄 Log: $Log" -ForegroundColor Yellow