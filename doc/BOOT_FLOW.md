# ⚙️ Boot & Initialization Flow

← [Back to README](../README.md)

> Every launch of Android DEX executes a precise, sequenced initialization protocol. This document covers every step, its purpose, what triggers it, and how it maps to the UI progress indicators.

---

## Progress Bars

The boot screen shows **two independent progress bars** fed by separate event streams:

| Bar | Source | What It Tracks |
| :--- | :--- | :--- |
| **JAR** | `JarManager` event stream | Logic Engine deployment + handshake |
| **APP** | `AppManager` event stream | Overall system initialization |

Both bars must reach `1.00` (100%) before the desktop UI unlocks.

---

## Full Initialization Sequence

### APP Bar (Overall System)

| Progress | User Message | What's Actually Happening |
| :--- | :--- | :--- |
| `0.02` | Starting ADB server… | `adb start-server` |
| `0.10` | Connecting to Android device… | `adb connect` + device link |
| `0.20` | Device connected — network bridge configured | `adb reverse` on all required ports |
| `0.28` | Starting local communication servers… | Binds 4 TCP/WS servers on Windows |
| `0.38` | Deploying service module to Android device… | Kicks off JAR deployment (JAR bar begins) |
| `0.55` | Verifying companion app on device… | `adb shell pm list packages` |
| `0.65` | Companion app not found — installing now… | `adb install` *(only if missing)* |
| `0.72` | Launching Android companion services… | `adb shell am start ServerStartService` |
| `0.84` | Waiting for background service to connect… | Blocks on `jar.hello` TCP handshake (15s timeout) |
| `0.93` | Waiting for companion app to connect… | Blocks on `apk.hello` WebSocket handshake (15s timeout) |
| `0.97` | Activating media and notification services… | Sends start commands through APK channel |
| `1.00` | **System ready** ✓ | Desktop UI unlocked |

### JAR Bar (Logic Engine Deployment)

> The JAR bar runs concurrently with APP steps `0.38 → 0.84`. It tracks the Logic Engine sub-process independently.

| Progress | User Message | What's Actually Happening |
| :--- | :--- | :--- |
| `0.00` | Preparing service deployment… | `stopJar()` — kills any existing local process |
| `0.15` | Stopping previous service on device… | `adb shell kill [pid]` — clears old JAR process on Android |
| `0.30` | Locating service module… | Checks `androiddex.jar` exists in local install directory |
| `0.50` | Uploading service module to device… | `adb push androiddex.jar /data/local/tmp/` *(slowest step)* |
| `0.70` | Service module uploaded successfully | Push confirmed, file verified |
| `0.82` | Launching service runtime on device… | `adb shell app_process ... JarMain` |
| `0.92` | Service is running — awaiting connection… | JAR process started, waiting for TCP connect-back |
| `1.00` | **Service connected — handshake confirmed** ✓ | `jar.hello` received; JAR bar fully complete |

---

## Pre-Boot: Device Selection

Before the initialization sequence begins, the system resolves **which device to target**:

```
App launched
     │
     ├─ CLI args provided?
     │       │
     │       ├─ --usb  → target USB device (-d transport)
     │       └─ <ip>   → target Wi-Fi device (ip:5555)
     │
     └─ No args → Auto-Detect
             │
             ├─ 0 devices found → needsDeviceSelection = true
             │   └── ADB Manager Dialog opens (user picks)
             │
             ├─ 1 device found → use it automatically
             │
             └─ 2+ devices found → needsDeviceSelection = true
                 └── ADB Manager Dialog opens (user picks)
```

→ See **[Device Manager](DEVICE_MANAGER.md)** for the full dialog flow.

---

## Error Behaviour During Boot

At any step failure, the affected bar stops at its current value and an error panel appears below the progress bars. If the failure is connection-related:

- A glowing **"Open ADB Manager — Select Device"** button appears
- Clicking it opens the device picker **without restarting the app**
- After device selection, the boot sequence retries from the beginning with a clean state

→ See **[Error Handling](ERROR_HANDLING.md)** for the full error message reference.

---

## Timeout Policy

| Handshake | Timeout | Error Message |
| :--- | :--- | :--- |
| JAR TCP (`jar.hello`) | 15 seconds | "Background service timed out. The device may be busy or unreachable." |
| APK WebSocket (`apk.hello`) | 15 seconds | "Companion app timed out. Ensure it is installed and running on the device." |

---

← [Back to README](../README.md) · [Architecture »](ARCHITECTURE.md) · [Modules »](MODULES.md)
