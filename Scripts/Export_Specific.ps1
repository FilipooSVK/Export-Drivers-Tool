param(
  [string]$InfName,        # napr. oem42.inf alebo konkretný INF
  [string]$HardwareId,     # fragment HWID (VID_... alebo PCI\VEN_...)
  [string]$OutBase = "C:\DriverExports",
  [switch]$Zip
)
if (-not $InfName -and -not $HardwareId) {
  throw "Zadaj -InfName alebo -HardwareId."
}
Import-Module "$PSScriptRoot\Common\ExportDrivers.Common.psm1" -Force
$prefix = "SPECIFIC"
if ($InfName)    { $prefix += "-INF" }
if ($HardwareId) { $prefix += "-HWID" }
$dest = New-StampFolder -Base $OutBase -Prefix $prefix
Export-DriverSpecific -Destination $dest -InfName $InfName -HardwareId $HardwareId -Zip:$Zip
Write-Host "HOTOVO → $dest" -ForegroundColor Green
