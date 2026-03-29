# 🏗️ Architecture — Android DEX

← [Back to README](../README.md)

> Deep-dive into how Android DEX distributes responsibilities across its three-layer system. This document covers the design rationale, communication channels, and data flow between each layer.

---

## Overview

```
┌────────────────────────────────────────────────────────────────────┐
│                        WINDOWS SIDE                                │
│  Flutter UI · ADB Lifecycle · Server Infrastructure · Scrcpy      │
└────────────────┬──────────────────────────────┬───────────────────┘
                 │ TCP Socket                    │ WebSocket
                 ▼                               ▼
┌────────────────────────┐         ┌─────────────────────────────┐
│   ⚡ Logic Engine      │         │   📱 Feature Hub (APK)      │
│   Java JAR             │         │   Kotlin Service             │
│   ADB Shell Context    │         │   Android System Context     │
└────────────────────────┘         └─────────────────────────────┘
```

Both Android-side components **connect back to the Windows side** — the Windows app runs the servers; Android clients connect to them.

---

## Layer 1 — Windows Side

**Role:** Orchestrator, UI host, server infrastructure, and rendering engine.

### Responsibilities

| Domain | What It Does |
| :--- | :--- |
| **ADB Lifecycle** | Starts ADB server, connects device, sets up reverse port forwarding |
| **Server Infrastructure** | Runs four TCP/WebSocket servers that Android components connect to |
| **JAR Deployment** | Locates, pushes, and launches the Logic Engine on the device |
| **APK Management** | Detects, installs, and starts the companion APK service |
| **Rendering** | Embeds scrcpy windows as native Win32 child windows inside Flutter |
| **UI** | Boot screen, home screen, app drawer, taskbar, reconnection overlay |
| **Reconnection** | Monitors connection state; auto-heals without user restart |
| **Device Selection** | Auto-detects ADB devices; shows picker dialog when needed |

### Communication (Inbound — from Android)

| Server | Protocol | From | Purpose |
| :--- | :--- | :--- | :--- |
| **JAR Server** | Raw TCP + JSON | Logic Engine (JAR) | Commands, status, handshake (`jar.hello`) |
| **APK Server** | WebSocket + JSON | Feature Hub (APK) | Telemetry, notifications, handshake (`apk.hello`) |
| **Media Data Server** | WebSocket | Feature Hub | Media session metadata + artwork |
| **Notification Server** | WebSocket | Feature Hub | Notification stream |

### Communication (Outbound — to Android)

| Channel | Protocol | Purpose |
| :--- | :--- | :--- |
| **ADB Commands** | Process execution | Device setup, APK install, service start |
| **ADB Pipe (JAR launch)** | `adb shell app_process` | Boot the Logic Engine process |
| **ADB Reverse** | `adb reverse tcp:PORT` | Bridges Android → Windows TCP ports |
| **scrcpy channel** | IPC | Video stream, input injection |

---

## Layer 2 — Logic Engine (Java JAR)

**Role:** Shell-level command executor running with elevated ADB daemon privileges.

### Why a JAR?

The Android APK layer cannot access certain low-level system APIs due to Android's permission model. The JAR, launched via `adb shell app_process`, executes at the **ADB shell user level** — the same level that allows `setenforce`, `input keyevent`, volume manipulation via `AudioService`, and control over the `ActivityManager` without launcher process restrictions.

### Responsibilities

| Feature | How |
| :--- | :--- |
| **Volume Control** | Direct `AudioManager` stream access at shell level |
| **App Launch** | `ActivityManager.startActivity()` with flags for foreground |
| **App Kill** | `ActivityManager.forceStopPackage()` |
| **Screen Wake/Sleep** | `PowerManager` + `WakeManager` invocation |
| **Display Interaction** | Direct display state manipulation |

### Lifecycle

```
Windows Side locates androiddex.jar locally
        │
        ▼
adb push → uploads to /data/local/tmp/ on device
        │
        ▼
adb shell app_process → JAR entry point executes
        │
        ▼
JAR opens TCP connection back to Windows Server
        │
        ▼
JAR sends: {"type":"jar.hello"}  ← handshake confirmed
        │
        ▼
Windows marks JarManager.jarReady = complete ✓
JAR progress bar reaches 1.00
```

---

## Layer 3 — Feature Hub (Kotlin APK)

**Role:** Permission-holding daemon for all telemetry and high-level Android APIs.

### Why a separate APK?

Unlike the JAR, the APK runs in the **Android application context**, giving it access to listener APIs that require app registration: `NotificationListenerService`, `MediaSessionManager`, Bluetooth callbacks, and `BIND_ACCESSIBILITY_SERVICE`. These cannot be accessed from a bare shell process.

### Responsibilities

| Feature | API Used |
| :--- | :--- |
| **Notification Streaming** | `NotificationListenerService` |
| **Media Session** | `MediaSessionManager` — title, artist, artwork, state |
| **Battery Telemetry** | `BatteryManager` broadcast receiver |
| **Device States** | Wi-Fi, Bluetooth, Mobile Data, Airplane, Mute, Rotation, Location, Torch |
| **Permission Status** | Runtime permission check + severity reporting |
| **Volume Commands** | `AudioManager` from app context |

### Lifecycle

```
Windows Side checks if APK is installed (pm list packages)
        │
        ├─ Not installed → adb install → installs APK
        │
        ▼
adb shell am start → launches ServerStartService intent
        │
        ▼
APK opens WebSocket connection back to Windows APK Server
        │
        ▼
APK sends: {"type":"apk.hello"}  ← handshake confirmed
        │
        ▼
Windows marks ApkServer.apkReady = complete ✓
APP progress bar reaches 1.00
System fully synchronized — Desktop UI unlocked
```

---

## Data Flow Diagram

```
Android Device                          Windows PC
─────────────────────────────────────   ──────────────────────────────────────
JAR (TCP Client) ──────────────────────► JAR Server (TCP Listener)
                                                   │
                                                   ▼
                                         AndroidCore State Store
                                                   │
APK (WebSocket Client) ────────────────► APK Server (WS Listener)   │
                                                   │         ▼
Media Events ──────────────────────────► Media Server       Flutter UI
                                                   │    (reads state,
Notification Events ───────────────────► Notify Server       responds to
                                                   │    ValueNotifiers)

scrcpy stream ─────────── Win32 → Flutter embedded window (H.264)
```

---

← [Back to README](../README.md) · [Boot Flow »](BOOT_FLOW.md) · [Modules »](MODULES.md)
