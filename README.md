# Android DEX

**Wireless desktop mode for Android** — 1080p extended display, no root .

Android DEX turns your Android phone into a **true desktop-style extended display** on Windows using **wireless ADB + scrcpy**.  
It is **not Samsung DeX** — it works on supported Android devices and provides a clean, customizable desktop experience.

---

## 📥 Download & Website

| Name | Link |
| --- | --- |
| Android DEX (Windows App) | [Download](https://github.com/Shrey113/Android-Dex/releases/download/Android-Dex-v.0.1/android_dex.exe) |
| For All OS  |  Coming soon ⌛ |
| Official Website | [Website](https://shrey113.github.io/Android-Dex/) |
| Developer Docs | [Docs](https://shrey113.github.io/Android-Dex/developer-docs/) |
| Introduction | [Watch](https://shrey113.github.io/Android-Dex/developer-docs/Video_help.html#1) |
| Controller Setup | [Guide](https://shrey113.github.io/Android-Dex/developer-docs/Video_help.html#2) |

---

## 🛠️ What It Does

Android DEX creates an **extended 1080p virtual display** on your PC and streams it wirelessly to your Android device.

- Uses **scrcpy virtual display**
- Works over **wireless ADB**
- Desktop-style Android UI
- No root required

---

## ✨ Feature Highlights

- Wireless ADB connection  
- virtual display via scrcpy  
- Windows desktop controller app  
- Separate Android helper apps  
- Low-latency desktop interaction  

---

## 📋 Prerequisites

- Android **11+**
- Phone and PC on the **same Wi-Fi network**
- **Developer Options → Wireless Debugging** enabled
- Desktop OS: **Windows**
- Required helper files:
  - `All helper/platform-tools/adb.exe`
  - `All helper/scrwin64/scrcpy.exe`
  - `All helper/AndroidDex.apk`
  - `All helper/DexController.apk`

---

## 🖼️ On-Device UI Previews

**Android Dex Control**  
<img src="developer-docs/Android Dex Control.gif" alt="Android Dex Control" width="400" />

**Context Menu**  
<img src="Data/README%20-%20Data/AndroidDex%20-%20App%20Context%20menu.png" alt="Context Menu" width="400" />

**Notifications Panel**  
<img src="Data/README%20-%20Data/AndroidDex%20-%20Notification.png" alt="Notifications Panel" width="400" />

**Quick Settings Tile**  
<img src="Data/README%20-%20Data/AndroidDex%20-%20Setting.png" alt="Quick Settings Tile" width="400" />

---

## 🔄 End-to-End Flow (How It Works)

1. **Tool check**  
   Verifies `adb` and `scrcpy` binaries exist in the helper folder.  
   Source: [scrcpy_service.dart](https://github.com/Shrey113/Android-Dex/blob/main/lib/services/scrcpy_service.dart)

2. **ADB connection**  
   Connects using `adb connect <ip:port>` and validates the device.  
   Source: [scrcpy_service.dart](https://github.com/Shrey113/Android-Dex/blob/main/lib/services/scrcpy_service.dart)

3. **App prerequisites**   
   - Checks `com.example.androiddex` and `com.example.dexcontroller`
   - Shows install dialog with separate install buttons
   - Installs APKs from helper folder  
   Source: [home_screen.dart](https://github.com/Shrey113/Android-Dex/blob/main/lib/screens/home_screen.dart)

4. **Accessibility enablement**  
   Enables required accessibility service via ADB.  
   Source: [scrcpy_service.dart](https://github.com/Shrey113/Android-Dex/blob/main/lib/services/scrcpy_service.dart)

5. **Start scrcpy session**  
   - Creates 1080p / 280 DPI virtual display
   - Fullscreen mode
   - Auto-launches Android DEX app
   - Applies user-configured flags  
   Source: [scrcpy_config.dart](https://github.com/Shrey113/Android-Dex/blob/main/lib/screens/scrcpy_config.dart)

---

## ⚙️ scrcpy Settings (Desktop App)

Open **Settings** from the title bar:

- **Max FPS**: `30 / 60 / 90 / 120` → `--max-fps=<value>`
- **Video codec**: `h264` / `h265` → `--video-codec=<value>`
- **Destroy content toggle** → `--no-vd-destroy-content`

Settings are saved using **Shared Preferences** and applied on session start.  
A **Command Preview** is shown for easy copying (device selection flags are excluded).

Source: [scrcpy_config.dart](https://github.com/Shrey113/Android-Dex/blob/main/lib/screens/scrcpy_config.dart)

---


## 💻 CLI / Environment Variables

> Environment variables are currently hidden and will be documented after permission approval.
```
SCRCPY_Shrey11_=????
SCRCPY_FLAG_Shrey11_=????
HiddenPort_Shrey11_=????
```
---

## 🌟 Credits

- [Shrey113](https://github.com/Shrey113)
- [scrcpy](https://github.com/Genymobile/scrcpy)
- [Android Debug Bridge (ADB)](https://developer.android.com/tools/adb)
- [Flutter](https://flutter.dev/)


