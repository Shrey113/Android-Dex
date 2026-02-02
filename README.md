# Android DEX

Wireless desktop mode for Android. 1080p extended display, no root, open source.

## Download + Website

- Android‑Dex Releases: https://github.com/Shrey113/android_dex/releases
- Live Website: https://shrey113.github.io/Android-Dex/
- Local Website: ALL_website/index.html
- Developer Docs (local): developer-docs/index.html

## Overview

Android DEX enables a full desktop-like experience from your Android device, wirelessly.
It creates an extended 1080p display on your PC using scrcpy, connects via wireless ADB,
and provides convenient controls — all powered by a Flutter desktop app.

## Features

- Wireless ADB connection (no cables)
- 1080p extended display via scrcpy
- No root required on device
- Per‑app audio routing to PC
- Quick toggles for system controls
- Cross‑platform desktop app (Windows, macOS, Linux)
- Open source, easy to contribute

## Requirements

- Android 11 or newer
- Phone and PC on the same Wi‑Fi network
- Developer Options enabled, Wireless Debugging enabled
- Desktop OS: Windows/macOS/Linux

## Quick Start

1. Enable Wireless Debugging on your Android device (Developer Options).
2. Download and run Android‑Dex from Releases on your PC.
3. Connect to your device by IP/port or select from discovered devices.
4. Click “Start DEX” to open the 1080p extended desktop window.

## Installation

### Use Prebuilt
- Download the latest installer/binary from Releases and run it.

### Build From Source
1. Install Flutter (stable) with desktop support enabled.
2. Enable platforms as needed:
   - Windows: `flutter config --enable-windows-desktop`
   - macOS: `flutter config --enable-macos-desktop`
   - Linux: `flutter config --enable-linux-desktop`
3. Fetch dependencies: `flutter pub get`
4. Run the app:
   - Windows: `flutter run -d windows`
   - macOS: `flutter run -d macos`
   - Linux: `flutter run -d linux`
5. Build artifacts:
   - Windows: `flutter build windows`
   - macOS: `flutter build macos`
   - Linux: `flutter build linux`

## How It Works

- Android Device → Wireless ADB (Wi‑Fi/TCP)
- Desktop App (Flutter) → starts/manages scrcpy
- scrcpy → renders an extended 1080p desktop window

## Using The Website Locally

- Open `ALL_website/index.html` in your browser to view the project site.
- Developer documentation is available at `developer-docs/index.html`.

## Troubleshooting

- Ensure Wireless Debugging is enabled and the device is discoverable.
- Verify phone and PC are on the same network.
- If scrcpy fails to start, install scrcpy and ensure it’s in PATH.
- Restart the desktop app and re‑connect.

## Contributing

- Fork the repo and create feature branches.
- Follow Flutter/Dart best practices and keep changes focused.
- Open a Pull Request with a clear description and rationale.

## License

- See LICENSE in the repository.

## Acknowledgements

- scrcpy (display mirroring)
- Android Debug Bridge (ADB)
- Flutter (cross‑platform UI)
