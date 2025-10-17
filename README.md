# 🧰 Export Drivers Tool

![PowerShell](https://img.shields.io/badge/PowerShell-5.1%2B-blue)
![Windows](https://img.shields.io/badge/Windows-10%20%2F%2011-lightgrey)
![License](https://img.shields.io/badge/License-MIT-green)
![Status](https://img.shields.io/badge/Build-Stable-success)
![Automation](https://img.shields.io/badge/Automation-Enabled-orange)

---

A lightweight PowerShell-based utility that **automatically exports all installed Windows drivers** and compresses them into a single ZIP file — perfect for backups, deployments, or recovery before reinstalling Windows.


---

## 🚀 Features

- 🔹 Exports **all currently installed Windows drivers**
- 🔹 Automatically creates a timestamped folder (e.g., `Drivers_2025-10-17`)
- 🔹 Compresses exported drivers into a `.zip` archive
- 🔹 Includes a `.cmd` launcher for one-click execution (no PowerShell needed)
- 🔹 Works on **Windows 10** and **Windows 11**


---

## ⚙️ How It Works

1. Run `Export_drivers.cmd` **as Administrator**  
2. The script will:
   - Create a new folder under `C:\Exported_Drivers`
   - Export all installed drivers using `Export-WindowsDriver -Online`
   - Compress the folder into a single `.zip` archive
3. The ZIP file can later be used for:
   - Restoring drivers after a clean install  
   - Injecting drivers into Windows images (WIM/ESD)  
   - Backup or audit purposes  

---

## 💡 Manual PowerShell Execution

If you prefer to run it manually instead of the CMD launcher, open PowerShell **as Administrator** and run:

```powershell
Set-ExecutionPolicy Bypass -Scope Process -Force
.\Export_drivers_zip.ps1
```

---

## 🪪 License

This project is licensed under the MIT License — feel free to use, modify, and distribute.

