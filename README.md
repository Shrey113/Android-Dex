# Android DEX

Wireless desktop mode for Android — 1080p extended display, no root, open source.

## Download + Website
- Releases: https://github.com/Shrey113/android_dex/releases
- Live Site: https://shrey113.github.io/Android-Dex/
- Local Site: `ALL_website/index.html`
- Developer Docs (local): `developer-docs/index.html`

## What It Does
Android DEX creates an extended 1080p display on your desktop using scrcpy and connects to your Android device over Wireless ADB. The Flutter desktop app handles device discovery, connection, prerequisites, and starting scrcpy with configurable options.

## Feature Highlights
- Wireless ADB connection
- 1080p extended display via scrcpy
- No root required
- Desktop app for Windows/macOS/Linux
- Built‑in prerequisites check and APK installer
- Configurable scrcpy options (FPS, codec, flags) with preview + copy

## Prerequisites
- Android 11+
- Phone and PC on the same Wi‑Fi network
- Developer Options → Wireless Debugging enabled
- Desktop OS: Windows/macOS/Linux
- Helper binaries and APKs present:
  - `All helper/platform-tools/adb.exe`
  - `All helper/scrwin64/scrcpy.exe`
  - `All helper/AndroidDex.apk`
  - `All helper/DexController.apk`

## Quick Start
1. Enable Wireless Debugging on your Android device.
2. Launch the Android DEX desktop app.
3. Enter your device IP:port or pick from the device list.
4. Press “Start DEX”.
5. If prompted, install the required apps and then start:
   - AndroidDex.apk (package: `com.example.androiddex`)
   - DexController.apk (package: `com.example.dexcontroller`)
6. The app enables the accessibility service and starts scrcpy with your settings.

## End‑to‑End Flow
1. Tools check: verifies adb/scrcpy exist in the helper folder.  
   Code: [scrcpy_service.dart](file:///a:/All%20Android/android_dex/lib/services/scrcpy_service.dart)
2. Connect ADB: `adb connect <ip:port>` and validate connection.  
   Code: [scrcpy_service.dart](file:///a:/All%20Android/android_dex/lib/services/scrcpy_service.dart)
3. Prerequisites:
   - Checks installation of `com.example.androiddex` and `com.example.dexcontroller`
   - Shows an install dialog with separate Install buttons
   - Installs from `All helper/AndroidDex.apk` and `All helper/DexController.apk`
   Code: [home_screen.dart](file:///a:/All%20Android/android_dex/lib/screens/home_screen.dart), [scrcpy_service.dart](file:///a:/All%20Android/android_dex/lib/services/scrcpy_service.dart)
4. Enable accessibility:
   - Runs: `adb shell settings put secure enabled_accessibility_services com.example.androiddex/.services.DexAccessibilityService`
   Code: [scrcpy_service.dart](file:///a:/All%20Android/android_dex/lib/services/scrcpy_service.dart)
5. Start scrcpy:
   - Base flags create a 1080p/280dpi extended display, full screen, no audio, and auto‑launch the AndroidDex app
   - User settings append additional flags (FPS, codec, destroy‑content toggle)
   Code: [scrcpy_service.dart](file:///a:/All%20Android/android_dex/lib/services/scrcpy_service.dart), [scrcpy_config.dart](file:///a:/All%20Android/android_dex/lib/screens/scrcpy_config.dart)

## scrcpy Settings (Desktop App)
Open the Settings page from the title bar:
- Max FPS: 30 / 60 / 90 / 120 → `--max-fps=<value>`
- Video codec: `h264` or `h265` → `--video-codec=<value>`
- “Add --no-vd-destroy-content” switch → `--no-vd-destroy-content`

Settings are persisted using Shared Preferences and applied to scrcpy on session start. The Settings page also shows a “Command Preview” that you can copy. Device selection flags (`-s <ip:port>`) are intentionally omitted from the preview.

Code: [scrcpy_config.dart](file:///a:/All%20Android/android_dex/lib/screens/scrcpy_config.dart)

## UI Overview
- Home Screen
  - Device connection form (IP:port)
  - Device list with refresh
  - Server toggle and window controls
  - Install dialog for missing APKs
  Code: [home_screen.dart](file:///a:/All%20Android/android_dex/lib/screens/home_screen.dart)
- Settings Screen
  - Minimal header with Back + title
  - Animated switch control
  - Command Preview with copy
  Code: [scrcpy_config.dart](file:///a:/All%20Android/android_dex/lib/screens/scrcpy_config.dart)

### On‑Device UI Previews
Context Menu:
![AndroidDex App Context Menu](Data/README%20-%20Data/AndroidDex%20-%20App%20Context%20menu.png)

Notifications Panel:
![AndroidDex Notifications](Data/README%20-%20Data/AndroidDex%20-%20Notification.png)

Quick Settings:
![AndroidDex Settings Tile](Data/README%20-%20Data/AndroidDex%20-%20Setting.png)

## CLI Equivalent
The app ultimately launches a command similar to:
```
scrcpy --new-display=1920x1080/280 --no-audio \
  --start-app=com.example.androiddex \
  --no-vd-system-decorations -f --shortcut-mod=lctrl \
  [--max-fps=60] [--video-codec=h265] [--no-vd-destroy-content]
```
Notes:
- The device selection flags `-s <ip:port>` are supplied internally when launching scrcpy.
- Flags in brackets are optional depending on your settings.

## Build From Source
1. Install Flutter (stable) with desktop support.
2. Enable platforms:
   - Windows: `flutter config --enable-windows-desktop`
   - macOS: `flutter config --enable-macos-desktop`
   - Linux: `flutter config --enable-linux-desktop`
3. Fetch dependencies: `flutter pub get`
4. Run:
   - Windows: `flutter run -d windows`
   - macOS: `flutter run -d macos`
   - Linux: `flutter run -d linux`
5. Build:
   - Windows: `flutter build windows`
   - macOS: `flutter build macos`
   - Linux: `flutter build linux`

## Troubleshooting
- Ensure Wireless Debugging is enabled and the device is reachable by IP:port.
- Confirm helper binaries/APKs exist in the `All helper/` folder.
- If scrcpy fails:
  - Check the Settings flags; reduce FPS or switch codec
  - Re‑install APKs using the install dialog
  - Restart the app and reconnect
- Desktop window sizing can be adjusted in `lib/main.dart`.

## Contributing
- Fork the repo, create focused feature branches, and open PRs.
- Follow Flutter/Dart best practices and keep changes small and reviewable.

## License
See `LICENSE`.

## Credits
- scrcpy
- Android Debug Bridge (ADB)
- Flutter
