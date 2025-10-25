<# 
  Export_Mouse_Driver.ps1
  Exportuje ovládače pre zariadenia triedy "Mouse" do C:\Exported_Mouse_Driver\<dátum_čas>
  Výsledok sa zabalí do ZIP archívu.
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

# GUID triedy myší
$MouseClassGuid = '{4d36e96f-e325-11ce-bfc1-08002be10318}'

# Vytvor výstupný priečinok
$Timestamp = (Get-Date -Format "yyyyMMdd_HHmmss")
$OutDir = "C:\Exported_Mouse_Driver\Mouse_$Timestamp"
New-Item -ItemType Directory -Force -Path $OutDir | Out-Null
$Log = Join-Path $OutDir "Export_Mouse_Driver.log"

Write-Host "==> Export mouse drivers to: $OutDir" -ForegroundColor Cyan

# Nájdeme zariadenia typu Mouse
$drivers = Get-CimInstance Win32_PnPSignedDriver -Filter "ClassGuid='$MouseClassGuid'" |
  Select-Object DeviceName, Manufacturer, InfName, DriverVersion, DriverDate, DriverProviderName

if (-not $drivers) {
  throw "❌ Nenašli sa žiadne zariadenia triedy 'Mouse'."
}

# Unikátne INF mená
$infList = $drivers |
  Where-Object { $_.InfName -and $_.InfName -match '\.inf$' } |
  Select-Object -ExpandProperty InfName -Unique

if (-not $infList -or $infList.Count -eq 0) {
  throw "❌ Could not find any INF for mouse."
}

Write-Host "🖱 Found INF package: $($infList -join ', ')" -ForegroundColor Yellow

# Over pnputil
$pnputil = Join-Path $env:SystemRoot 'System32\pnputil.exe'
if (-not (Test-Path $pnputil)) {
  throw "❌ pnputil.exe sa nenašiel: $pnputil"
}

# Log úvod
"=== Export_Mouse_Driver $(Get-Date) ===" | Out-File -FilePath $Log -Encoding UTF8

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
    Write-Warning "⚠ Export $inf skončil kódom $($proc.ExitCode). Pozri log $redir"
  } else {
    "OK: $inf" | Out-File -FilePath $Log -Append -Encoding UTF8
  }
}

# Súhrn
"`n=== Zariadenia ===" | Out-File -FilePath $Log -Append -Encoding UTF8
$drivers | Sort-Object InfName, DeviceName |
  Format-Table DeviceName, Manufacturer, InfName, DriverVersion, DriverDate -Auto | Out-String |
  Out-File -FilePath $Log -Append -Encoding UTF8

# ZIP archív
$zipPath = "$OutDir.zip"
Write-Host "==> Preparing of ZIP: $zipPath" -ForegroundColor Cyan
Compress-Archive -Path (Join-Path $OutDir '*') -DestinationPath $zipPath -Force
Write-Host "✅ ZIP si completed: $zipPath" -ForegroundColor Green

Write-Host "==> Completed. Destination: $OutDir" -ForegroundColor Green
Write-Host "📄 Log: $Log" -ForegroundColor Yellow
