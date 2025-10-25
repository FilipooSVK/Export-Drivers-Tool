param(
  [string]$OutBase = "C:\DriverExports",
  [switch]$Zip
)
Import-Module "$PSScriptRoot\Common\ExportDrivers.Common.psm1" -Force
$dest = New-StampFolder -Base $OutBase -Prefix "ALL"
Export-DriversAll -Destination $dest -Zip:$Zip
Write-Host "HOTOVO → $dest" -ForegroundColor Green
