param(
  [Parameter(Mandatory=$true)]
  [string[]]$Classes,
  [string]$OutBase = "C:\DriverExports",
  [switch]$Zip
)
Import-Module "$PSScriptRoot\Common\ExportDrivers.Common.psm1" -Force
$dest = New-StampFolder -Base $OutBase -Prefix ("CLASS-" + ($Classes -join "_"))
Export-DriversByClass -Destination $dest -Classes $Classes -Zip:$Zip
Write-Host "HOTOVO → $dest" -ForegroundColor Green
