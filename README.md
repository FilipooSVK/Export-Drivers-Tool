# 🧰 Export Driver Tool

![PowerShell](https://img.shields.io/badge/PowerShell-5.1%2B-blue)
![Windows](https://img.shields.io/badge/Windows-10%20%2F%2011-lightgrey)
![License](https://img.shields.io/badge/License-MIT-green)
![Status](https://img.shields.io/badge/Build-Stable-success)
![Automation](https://img.shields.io/badge/Automation-Enabled-orange)
[![ko-fi](https://ko-fi.com/img/githubbutton_sm.svg)](https://ko-fi.com/X8X31QYP4A)
---

A comprehensive PowerShell-based toolkit with an **interactive menu system** for exporting Windows drivers with precision. Export all drivers, specific device classes (Mouse, Storage, Network, etc.), or target individual drivers by INF/Hardware ID — perfect for backups, system migrations, or driver management.

---

## 🚀 Features

- ✅ **Interactive Menu System** - Easy-to-use CMD interface with multiple export options
- 🔹 Export **ALL installed drivers** (3rd-party/non-Microsoft)
- 🔹 Export by **device class** (Mouse, Keyboard, Display, Network, Storage, USB, etc.)
- 🔹 Export **specific drivers** by INF name or Hardware ID
- 🔹 **Multi-class selection** - Choose multiple categories in one export
- 🔹 Automatically creates **timestamped folders** with descriptive names
- 🔹 Optional **ZIP compression** (toggle on/off)
- 🔹 Customizable **destination folder**
- 🔹 Detailed **export logs** for each operation
- 🔹 Works on **Windows 10** and **Windows 11**

---

## 📁 Project Structure

```
DriverExportTool/
│
├── start.cmd          # Main launcher (run as Admin)
│
└── Scripts/
    ├── Export_ByClass.ps1         # Export by device class
    ├── Export_All.ps1             # Export all 3rd-party drivers
    ├── Export_NonMS.ps1           # Export non-Microsoft drivers
    └── Export_Specific.ps1        # Export specific driver by INF/HWID
```

---

## ⚙️ How It Works

### 🎯 Quick Start

1. **Run** `start.cmd` **as Administrator**
2. Choose from the interactive menu:
   - **Option 1-2**: Export all drivers (3rd-party/non-Microsoft)
   - **Option 3**: Select specific device classes (multi-selection available)
   - **Option 4**: Export specific driver by INF name or Hardware ID
   - **Option 5**: Toggle ZIP compression on/off
   - **Option 6**: Change destination folder
   - **Option 7**: Open export folder in Explorer

3. Exported drivers will be saved to:
   ```
   C:\DriverExports\<CategoryName>_<Timestamp>\
   ```

### 📦 Example Output Structure

```
C:\DriverExports/
│
├── Mouse_20241025_143022/              # Single class export
│   ├── oem42.inf
│   ├── oem42.cat
│   ├── driver_files/
│   └── Export_Mouse.log
│
├── Mouse-Keyboard-Display_20241025_143522/  # Multi-class export
│   ├── [all related INF files]
│   └── Export_MultiClass.log
│
└── Mouse_20241025_143022.zip           # Optional ZIP archive
```

---

## 🎮 Menu Options Explained

### 📋 Main Menu

| Option | Description |
|--------|-------------|
| **1** | Export ALL 3rd-party drivers |
| **2** | Export NON-Microsoft drivers |
| **3** | **BY CLASS** - Interactive category selection |
| **4** | Export SPECIFIC driver (by INF or Hardware ID) |
| **5** | Toggle ZIP compression (ON/OFF) |
| **6** | Change destination folder |
| **7** | Open destination folder in Explorer |
| **0** | Exit |

### 🎯 Class Selection Menu (Option 3)

Choose one or multiple categories:

| Key | Category | Device Classes |
|-----|----------|----------------|
| **1** | Mouse | Mouse, HIDClass |
| **2** | Keyboard | Keyboard, HIDClass |
| **3** | Display | Display |
| **4** | Network | Net |
| **5** | Audio | Media |
| **6** | Bluetooth | Bluetooth |
| **7** | Camera | Camera, Image |
| **8** | Printer | Printer |
| **9** | Chipset | System, HDC, SoftwareDevice |
| **A** | Storage | SCSIAdapter, DiskDrive, StorageVolume |
| **B** | USB | USB |
| **C** | HID | HIDClass |
| **D** | Battery | Battery |
| **E** | Sensors | Sensor |
| **F** | System | System |
| **X** | **EXPORT** selected categories |
| **0** | Back to main menu |

**Example workflow:**
1. Press `1` (Mouse)
2. Press `4` (Network)
3. Press `5` (Audio)
4. Press `X` to export → Creates folder: `Mouse-Network-Audio_20241025_143522`

---

## 💡 Manual PowerShell Execution

If you prefer running individual scripts directly:

```powershell
# Set execution policy (run as Administrator)
Set-ExecutionPolicy Bypass -Scope Process -Force

# Export all drivers
.\Scripts\Export_All.ps1 -OutBase "C:\DriverExports" -Zip

# Export by device class
.\Scripts\Export_ByClass.ps1 -Classes "Mouse,HIDClass" -CategoryName "Mouse" -OutBase "C:\DriverExports" -Zip

# Export specific driver
.\Scripts\Export_Specific.ps1 -InfName "oem42.inf" -OutBase "C:\DriverExports" -Zip

# Export by Hardware ID
.\Scripts\Export_Specific.ps1 -HardwareId "VID_046D" -OutBase "C:\DriverExports"
```

---

## 📝 Use Cases

### ✅ System Backup
Export all drivers before:
- Clean Windows reinstallation
- Major Windows updates
- Hardware changes

### ✅ Driver Migration
Transfer drivers between:
- Similar hardware configurations
- Virtual machines
- Deployment images

### ✅ Troubleshooting
- Isolate specific device class drivers
- Compare driver versions
- Archive working driver sets

### ✅ Deployment Preparation
- Create driver repositories
- Inject drivers into WIM/ESD images
- Prepare offline driver stores

---

## 🛠️ Technical Details

### Requirements
- **OS**: Windows 10 / Windows 11
- **PowerShell**: 5.1 or higher
- **Permissions**: Administrator privileges required
- **Tools**: Uses built-in `pnputil.exe` for driver export

### Device Class GUIDs Supported

The tool recognizes standard Windows device class GUIDs including:
- Mouse: `{4d36e96f-e325-11ce-bfc1-08002be10318}`
- Keyboard: `{4d36e96b-e325-11ce-bfc1-08002be10318}`
- Display: `{4d36e968-e325-11ce-bfc1-08002be10318}`
- Network: `{4d36e972-e325-11ce-bfc1-08002be10318}`
- Storage: `{4d36e967-e325-11ce-bfc1-08002be10318}`
- USB: `{36fc9e60-c465-11cf-8056-444553540000}`
- And many more...

---

## 🔧 Configuration

### Change Default Settings

Edit `start.cmd`:

```batch
:: Default destination folder
set "OUTBASE=C:\DriverExports"

:: ZIP compression (1=enabled, 0=disabled)
set "ZIP=1"
```

Or change via menu (Options 5 & 6) — settings persist during session.

---

## 📊 Export Logs

Each export creates a detailed log file:

```
=== Export_Mouse 2024-10-25 14:30:22 ===
Classes: Mouse, HIDClass

-- pnputil /export-driver oem42.inf C:\DriverExports\Mouse_20241025_143022 --
OK: oem42.inf

=== Devices ===
DeviceName          Manufacturer    InfName      DriverVersion    DriverDate
----------          ------------    -------      -------------    ----------
HID-compliant mouse Microsoft       oem42.inf    10.0.22621.1    2023-09-15
```

---

## 🚨 Troubleshooting

### Script won't run
- ✅ Right-click `start.cmd` → **Run as Administrator**
- ✅ Check if `Scripts\` folder exists with `.ps1` files

### "pnputil.exe not found"
- ✅ Verify Windows installation integrity: `sfc /scannow`

### Empty export
- ✅ Some drivers may be inbox (built-in) - try "Export ALL" option
- ✅ Check log files for specific error messages

### ZIP creation fails
- ✅ Ensure sufficient disk space
- ✅ Check folder permissions on destination

---

## 🪪 License

This project is licensed under the **MIT License** — feel free to use, modify, and distribute.

```
MIT License

Copyright (c) 2024

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software.
```

---

## 🤝 Contributing

Contributions are welcome! Feel free to:
- Report bugs via Issues
- Submit feature requests
- Create pull requests

---

## 📞 Support

For issues or questions:
1. Check the **Troubleshooting** section
2. Review export log files
3. Open an issue on GitHub

---

## 🌟 Star This Project

If you find this tool useful, please consider giving it a ⭐ on GitHub!

---

**Made with ❤️ for the Windows community**
