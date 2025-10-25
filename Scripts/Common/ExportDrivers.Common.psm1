# ExportDrivers.Common.psm1

# region Helpers
function Require-Admin {
  $id = [Security.Principal.WindowsIdentity]::GetCurrent()
  $p  = New-Object Security.Principal.WindowsPrincipal($id)
  if (-not $p.IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)) {
    throw "Spusti PowerShell ako správca."
  }
}

function Ensure-Dir([string]$Path) {
  if (-not (Test-Path $Path)) {
    New-Item -ItemType Directory -Path $Path -Force | Out-Null
  }
}

function New-StampFolder([string]$Base="C:\DriverExports",[string]$Prefix="Export") {
  Ensure-Dir $Base
  $stamp = Get-Date -Format "yyyyMMdd_HHmmss"
  $dest = Join-Path $Base "$Prefix-$stamp"
  New-Item -ItemType Directory -Path $dest -Force | Out-Null
  return $dest
}

function Compress-Folder([string]$Source,[string]$ZipPath) {
  Add-Type -AssemblyName System.IO.Compression.FileSystem
  if (Test-Path $ZipPath) { Remove-Item $ZipPath -Force }
  [System.IO.Compression.ZipFile]::CreateFromDirectory($Source, $ZipPath, [System.IO.Compression.CompressionLevel]::Optimal, $false)
  return $ZipPath
}
# endregion

# region Core exports

<#
  .SYNOPSIS
    Export všetkých 3rd-party driverov z online systému.
  .NOTES
    Windows štandardne exportuje len „tretie strany“ (nie inbox Microsoft).
#>
function Export-DriversAll {
  param(
    [string]$Destination,
    [switch]$Zip
  )
  Require-Admin
  Ensure-Dir $Destination

  Write-Host ">> Export-WindowsDriver -Online -> $Destination" -ForegroundColor Cyan
  Export-WindowsDriver -Online -Destination $Destination | Out-Null

  if ($Zip) {
    $zip = "$Destination.zip"
    Write-Host ">> ZIP: $zip" -ForegroundColor Yellow
    Compress-Folder -Source $Destination -ZipPath $zip | Out-Null
  }
  return $Destination
}

<#
  .SYNOPSIS
    Export driverov podľa tried (Class) alebo podmienok.
  .PARAMETER Classes
    Zoznam tried zariadení (napr. 'Mouse','HIDClass','SCSIAdapter','HDC').
#>
function Export-DriversByClass {
  param(
    [string]$Destination,
    [string[]]$Classes,
    [switch]$Zip
  )
  Require-Admin
  Ensure-Dir $Destination

  # Získaj všetky podpísané drivery z PnP (online systém)
  $all = Get-CimInstance -ClassName Win32_PnPSignedDriver

  if ($Classes -and $Classes.Count -gt 0) {
    $flt = $all | Where-Object { $_.Class -and ($Classes -contains $_.Class) }
  } else {
    $flt = $all
  }

  # Vyber INF-y (oemXX.inf) a exportuj ich pomocou pnputil
  $uniqueInfs = $flt | Where-Object { $_.InfName } | Select-Object -ExpandProperty InfName -Unique

  if (-not $uniqueInfs -or $uniqueInfs.Count -eq 0) {
    Write-Warning "Nenašli sa žiadne INF-y pre zadané triedy."
    return $Destination
  }

  foreach ($inf in $uniqueInfs) {
    Write-Host "   pnputil /export-driver $inf $Destination" -ForegroundColor Gray
    pnputil /export-driver $inf "$Destination" | Out-Null
  }

  if ($Zip) {
    $zip = "$Destination.zip"
    Write-Host ">> ZIP: $zip" -ForegroundColor Yellow
    Compress-Folder -Source $Destination -ZipPath $zip | Out-Null
  }
  return $Destination
}

<#
  .SYNOPSIS
    Export drivera podľa INF názvu alebo podľa HardwareId (partial match).
#>
function Export-DriverSpecific {
  param(
    [string]$Destination,
    [string]$InfName,        # napr. oem42.inf alebo synmous.inf
    [string]$HardwareId,     # napr. "VID_046D&PID_C52B"
    [switch]$Zip
  )
  Require-Admin
  Ensure-Dir $Destination

  $targets = @()

  if ($InfName) {
    $targets += $InfName
  }

  if ($HardwareId) {
    $found = Get-CimInstance Win32_PnPSignedDriver |
      Where-Object {
        $_.HardwareID -and ($_.HardwareID -join '|') -match [Regex]::Escape($HardwareId)
      } |
      Select-Object -ExpandProperty InfName -Unique
    $targets += $found
  }

  $targets = $targets | Where-Object { $_ } | Select-Object -Unique
  if (-not $targets -or $targets.Count -eq 0) {
    Write-Warning "Nenašiel som žiadne INF-y podľa zadaných kritérií."
    return $Destination
  }

  foreach ($inf in $targets) {
    Write-Host "   pnputil /export-driver $inf $Destination" -ForegroundColor Gray
    pnputil /export-driver $inf "$Destination" | Out-Null
  }

  if ($Zip) {
    $zip = "$Destination.zip"
    Write-Host ">> ZIP: $zip" -ForegroundColor Yellow
    Compress-Folder -Source $Destination -ZipPath $zip | Out-Null
  }
  return $Destination
}
# endregion

Export-ModuleMember -Function Require-Admin,Ensure-Dir,New-StampFolder,Compress-Folder,Export-DriversAll,Export-DriversByClass,Export-DriverSpecific
