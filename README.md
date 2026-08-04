<div align="center">

<img src="Data/app_png.png" width="130" alt="Android DEX">

# Android DEX

**Transform your Android device into a desktop experience.**
Mirror apps, control your phone, stream audio, manage media, launch multiple Android apps, and connect over USB or Wi-Fi — all from Windows or Linux.


</div>

---

### 🚀 Quick  Download

| Platform | Download Link |
| :--- | :--- |
| **ADB Device Manager** | [Main System Project](https://github.com/Shrey113/Adb-Device-Manager-2) |
| **Windows** | [android_dex_win.zip](https://github.com/Shrey113/Android-Dex/releases/latest/download/Android_Dex_Windows.zip) |
| **Linux** | ⌛ under development |

---

## 📱 App Preview

<div align="center">

**Desktop Home Interface**
![Home Screen](Data/home_screen.png)

---

| ![App List](Data/App_list.png) | ![Multiple Apps](Data/multiple_apps_running.png) |
|:---:|:---:|
| **App Dashboard** | **Multi-App View** |

| ![Media Control](Data/media_control.png) | ![Controller 1](Data/controller_1.png) |
|:---:|:---:|
| **Media Center** | **Android Control** |

| ![Controller 2](Data/controller_2.png) | ![Controller 3](Data/controller_3.png) |
|:---:|:---:|
| **Audio Overlay** | **Media Preferences** |

</div>

---

## 📖 Deep-Dive Documentation

Check out these detailed guides to understand exactly how Android DEX works under the hood:

1. **[Architectural Design](doc/ARCHITECTURE.md)** : Three-layer system design, responsibilities, and data flow.
2. **[Boot & Initialization](doc/BOOT_FLOW.md)** : Step-by-step connection flow with progress stages.
3. **[Reconnection System](doc/RECONNECTION.md)** : Smart auto-healing, recovery phases, and UI overlay.
4. **[Real-Time Data Model](doc/DATA_MODEL.md)** : State store, JSON telemetry protocols, and message handling.
5. **[Error Handling](doc/ERROR_HANDLING.md)** : User-facing messaging pipelines and full fallback reference.
6. **[System Modules](doc/MODULES.md)** : Internal component roles, public APIs, and singletons.
7. **[Device Manager](doc/DEVICE_MANAGER.md)** : ADB device selection, UI dialogs, and IP connections.


---


## 🚀 Launch Options

### 🪟 Windows

| Command | Description |
| :--- | :--- |
| `android_dex_win.exe` | **Auto-detect** — recommended for most users |
| `android_dex_win.exe --usb` | Force **USB** connection only |
| `android_dex_win.exe 192.168.1.100` | Connect via **IP address** |
| `android_dex_win.exe 192.168.1.100:5555` | Connect via **IP & custom port** |

### 🐧 Linux

| Step | Command | Description |
| :---: | :--- | :--- |
| 1 | `cd android_dex_linux/` | Enter the extracted folder |
| 2 | `chmod +x run_android_dex.sh` | Make the script executable |
| 3 | `./run_android_dex.sh` | Launch Android DEX |

> The script auto-checks Linux compatibility — drivers, graphics, and dependencies — before starting.

---

## 🛠️ How It Works — The Handshake Protocol

The system uses a three-layer architecture with a cryptographic-style handshake before the desktop UI unlocks. Every component must confirm readiness before the session begins.

```mermaid
%%{init: {'theme': 'base', 'themeVariables': { 'primaryColor': '#0078D4', 'primaryTextColor': '#fff', 'primaryBorderColor': '#0078D4', 'lineColor': '#888', 'secondaryColor': '#0061af', 'tertiaryColor': '#222', 'noteBkgColor': '#333', 'noteTextColor': '#fff', 'noteBorderColor': '#555' }}}%%
sequenceDiagram
    participant PC as Windows Side (Flutter/ADB)
    participant JAR as Android Logic Engine (Java JAR)
    participant APK as Android App Hub (Kotlin APK)

    Note over PC: 1. ADB Initialization (startAdbBlocking)
    PC->>PC: 2. Local Server Setup (JarServer & ApkServer .start)
    
    Note over PC,JAR: Phase 1: Engine Deployment (Bridge)
    PC->>JAR: Push JAR to Device (via ADB Pipe)
    PC->>JAR: Launch JAR Runtime (adb.startJarRuntime)
    JAR-->>PC: Handshake Response: "jar.hello" (Logic Engine Ready)

    Note over PC,APK: Phase 2: Feature Manager Startup (Hub)
    PC->>APK: Check Install & Install if Missing
    PC->>APK: Trigger Service startup (ServerStartService)
    APK-->>PC: WebSocket Handshake: "apk.hello" (App Hub Ready)

    PC->>APK: 3. Start Extended Notification & Media Services
    Note over PC,APK: System Synchronized: Desktop UI Unlocked
```

---

## 📋 Getting Started

### Prerequisites

- **OS**: Windows 10+ or Modern Linux (Ubuntu, Fedora, etc.)
- **Device**: Android device running Android 8.0+
- **Drivers**: ADB is bundled — no separate installation needed

### Step-by-Step

1. **Enable Developer Options** on your phone
   - `Settings → About Phone` → tap **Build Number** 7 times

2. **Enable USB Debugging**
   - `Settings → Developer Options → USB Debugging → ON`

3. **Plug in your phone** (for USB) or **enable Wireless Debugging** (for Wi-Fi)

4. **Launch Android DEX** — watch the boot progress bars fill to 100%

5. **The desktop unlocks** — your Android is now a full Windows desktop experience

> If connection fails, a **"Select Device"** button appears in the boot screen — click it to open the ADB Manager and pick your device without restarting.

---

<div align="center">

*Engineered for performance. Optimized for productivity.*

Built by [@shrey113](https://github.com/shrey113)

</div>
