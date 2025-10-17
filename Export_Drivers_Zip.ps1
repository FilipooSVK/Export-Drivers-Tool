# ===============================
# 🧰 Export All Drivers + ZIP It
# ===============================

# 1️⃣ Create destination folder with date
$Date = Get-Date -Format "yyyyMMdd_HHmm"
$BackupRoot = "C:\DriverBackup_$Date"
$ZipFile = "C:\DriverBackup_$Date.zip"

# 2️⃣ Ensure destination folder exists
if (-not (Test-Path $BackupRoot)) {
    New-Item -ItemType Directory -Path $BackupRoot -Force | Out-Null
}

Write-Host "🚀 Starting export of all 3rd-party drivers..." -ForegroundColor Cyan
Write-Host "📁 Destination folder: $BackupRoot" -ForegroundColor Yellow

# 3️⃣ Export drivers
try {
    Export-WindowsDriver -Online -Destination $BackupRoot -ErrorAction Stop
    Write-Host "✅ Driver export completed successfully!" -ForegroundColor Green
}
catch {
    Write-Host "❌ Error during export: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# 4️⃣ Count exported drivers
$Count = (Get-ChildItem -Path $BackupRoot -Recurse -Filter *.inf | Measure-Object).Count
Write-Host "📦 Total exported drivers: $Count" -ForegroundColor Cyan

# 5️⃣ Compress exported drivers into ZIP
Write-Host "🗜️  Compressing drivers into ZIP archive..." -ForegroundColor Cyan
try {
    Compress-Archive -Path "$BackupRoot\*" -DestinationPath $ZipFile -Force
    Write-Host "✅ ZIP archive created: $ZipFile" -ForegroundColor Green
}
catch {
    Write-Host "❌ Error while creating ZIP: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# 6️⃣ Optional: Remove uncompressed folder after successful ZIP
# Remove-Item -Path $BackupRoot -Recurse -Force

# 7️⃣ Done!
Write-Host "`n🎉 All done!"
Write-Host "📂 Backup location: $ZipFile" -ForegroundColor Yellow
