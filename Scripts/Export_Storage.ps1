<# 
  Export_Storage_Drivers.ps1
  Exportuje ovládače pre disky a radiče (DiskDrive, SCSIAdapter, HDC) do C:\Exported_Storage_Drivers\<timestamp>
  a vytvorí ZIP archív s výsledkom.
#>

$ErrorActionPreference = 'Stop'

function Require-Admin {
  $id = [Security.Principal.WindowsIdentity]::GetCurrent()
  $p  = New-Object Security.Principal.WindowsPrincipal($id)
  if (-not $p.IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)) {
    throw "❌ Run PowerShell as Admin."
  }
}

Require-Admin

# GUID-y tried
$ClassGuids = @(
  '{4d36e967-e325-11ce-bfc1-08002be10318}', # DiskDrive (disky)
  '{4d36e97b-e325-11ce-bfc1-08002be10318}', # SCSIAdapter (NVMe/SAS/SCSI/RAID)
  '{4d36e96a-e325-11ce-bfc1-08002be10318}'  # HDC (IDE/ATA/AHCI)
)

# Výstupný priečinok
$Timestamp = (Get-Date -Format "yyyyMMdd_HHmmss")
$OutDir = "C:\Exported_Storage_Drivers\Storage_$Timestamp"
New-Item -ItemType Directory -Force -Path $OutDir | Out-Null
$Log = Join-Path $OutDir "Export_Storage_Drivers.log"

Write-Host "==> Exportujem storage ovládače do: $OutDir" -ForegroundColor Cyan

# Zozbieraj podpísané PnP drivery pre dané triedy
$allDrivers = @()
foreach ($g in $ClassGuids) {
  $drv = Get-CimInstance Win32_PnPSignedDriver -Filter "ClassGuid='$g'" -ErrorAction SilentlyContinue
  if ($drv) { $allDrivers += $drv }
}

if (-not $allDrivers -or $allDrivers.Count -eq 0) {
  throw "❌ Could not find any DiskDrive/SCSIAdapter/HDC."
}

# Prehľad
$driversView = $allDrivers |
  Where-Object { $_.InfName -and $_.InfName -match '\.inf$' } |
  Sort-Object ClassGuid, DeviceName, InfName |
  Select-Object ClassGuid, DeviceName, Manufacturer, InfName, DriverProviderName, DriverVersion, DriverDate

# Unikátne INF mená
$infList = $driversView | Select-Object -ExpandProperty InfName -Unique

Write-Host "🔎 Found INF package: $($infList -join ', ')" -ForegroundColor Yellow

# Over pnputil
$pnputil = Join-Path $env:SystemRoot 'System32\pnputil.exe'
if (-not (Test-Path $pnputil)) {
  throw "❌ pnputil.exe sa nenašiel: $pnputil"
}

"=== Export_Storage_Drivers $(Get-Date) ===" | Out-File -FilePath $Log -Encoding UTF8
"INF balíky: $($infList -join ', ')" | Out-File -FilePath $Log -Append -Encoding UTF8

# Export jednotlivých INF balíkov z Driver Store
foreach ($inf in $infList) {
  Write-Host "==> Exporting $inf ..." -ForegroundColor Cyan
  $redirOut = Join-Path $OutDir ("pnputil_{0}.txt" -f ($inf -replace '\.','_'))
  $redirErr = $redirOut -replace '\.txt$','_err.txt'
  $args     = @('/export-driver', $inf, $OutDir)

  "`n-- pnputil $($args -join ' ') --" | Out-File -FilePath $Log -Append -Encoding UTF8
  $proc = Start-Process -FilePath $pnputil -ArgumentList $args -PassThru -Wait -NoNewWindow `
          -RedirectStandardOutput $redirOut -RedirectStandardError $redirErr

  if ($proc.ExitCode -ne 0) {
    "pnputil exit code: $($proc.ExitCode)" | Out-File -FilePath $Log -Append -Encoding UTF8
    Write-Warning "⚠ Export $inf skončil kódom $($proc.ExitCode). Pozri $redirOut / $redirErr"
  } else {
    "OK: $inf" | Out-File -FilePath $Log -Append -Encoding UTF8
  }
}

# Zapíš prehľad zariadení
"`n=== Zariadenia ===" | Out-File -FilePath $Log -Append -Encoding UTF8
$driversView |
  Format-Table ClassGuid, DeviceName, Manufacturer, InfName, DriverProviderName, DriverVersion, DriverDate -Auto |
  Out-String | Out-File -FilePath $Log -Append -Encoding UTF8

# Vytvor ZIP archív
$zipPath = "$OutDir.zip"
Write-Host "==> Balím do ZIP: $zipPath" -ForegroundColor Cyan
Compress-Archive -Path (Join-Path $OutDir '*') -DestinationPath $zipPath -Force

Write-Host "✅ ZIP is done: $zipPath" -ForegroundColor Green
Write-Host "==> Completed. Destination folder: $OutDir" -ForegroundColor Green
Write-Host "📄 Log: $Log" -ForegroundColor Yellow
