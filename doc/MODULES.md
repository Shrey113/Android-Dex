# 🧩 Modules Reference

← [Back to README](../README.md)

> Complete reference for all internal Windows-side modules. Covers each module's role, its public API, and how it fits into the overall system. All modules are singletons unless noted otherwise.

---

## Module Map

```
AppManager ────────────────────────────── Orchestrates full init sequence
    │
    ├─► AdbProvider ─────────────────────── All ADB command execution
    ├─► JarManager ──────────────────────── JAR lifecycle + event stream
    │       └─► JarServer ───────────────── TCP listener (JAR connects here)
    ├─► ApkServer ───────────────────────── WS listener (APK connects here)
    ├─► MediaDataManager ────────────────── WS listener (media events)
    ├─► NotificationDataManager ─────────── WS listener (notification events)
    └─► ReconnectionManager ─────────────── Post-boot connection monitoring
            └─► AndroidCore ─────────────── Shared real-time state store
```

---

## `AdbProvider`

**Role:** The single source of truth for all ADB command execution. Every interaction with the connected Android device goes through this module.

### Resolved Paths (validated at first use)

| Property | Points To |
| :--- | :--- |
| `adbPath` | Bundled `adb.exe` in the installation directory |
| `apkPath` | Bundled `AndroidDex.apk` |
| `jarPath` | Bundled `androiddex.jar` |

> All paths throw a user-friendly exception (not a file path dump) if the file is missing.

### Key Methods

| Method | Description |
| :--- | :--- |
| `startAdbBlocking()` | Runs `adb start-server`; throws on failure |
| `connectBlocking()` | Runs `adb connect [device]` + sets up `adb reverse` on all ports |
| `getDevices()` → `List<String>` | Parses `adb devices` output; returns serial/IP list |
| `pushJar(localPath)` → `AdbResult` | `adb push jar /data/local/tmp/` |
| `killJar()` | `adb shell kill` the existing JAR process by PID |
| `startJarRuntime()` → `Process` | `adb shell app_process` — returns the running process handle |
| `isPackageInstalled(pkg)` → `bool` | `adb shell pm list packages \| grep pkg` |
| `installApk(path)` → `AdbResult` | `adb install -r path` |
| `startServerService(pkg)` → `AdbResult` | `adb shell am start-foreground-service` |
| `run(args)` → `AdbResult` | Generic ADB runner — wraps any argument list |
| `runOnDevice(args)` → `AdbResult` | Like `run()` but prepends the device selector (`-d` or `-s id`) |

### `AdbResult`

```dart
class AdbResult {
  final bool success;   // exitCode == 0
  final String output;  // stdout + stderr combined
}
```

---

## `AppManager`

**Role:** Master orchestrator for the full initialization sequence. Owns the `Stream<AppEvent>` that drives the APP progress bar in the boot screen.

### State

| Field | Type | Meaning |
| :--- | :--- | :--- |
| `_busy` | `bool` | Prevents concurrent `initializeSystem()` calls |

### Key Methods

| Method | Description |
| :--- | :--- |
| `initializeSystem()` | Full 11-step boot sequence; emits `AppEvent` for each step |
| `startExtendedServices()` | Activates Media + Notification channels after handshakes |

### Event Stream

Each `AppEvent` carries:
```dart
AppEvent { String message, double progress, bool isError }
```
The boot screen's APP bar listens to this stream and updates `_appProgress` / `_appLabel` reactively.

---

## `JarManager`

**Role:** Manages the entire Logic Engine lifecycle — from local file validation through device upload, process launch, and runtime monitoring. Exposes its own `Stream<JarEvent>` for the JAR progress bar.

### State

| Field | Type | Meaning |
| :--- | :--- | :--- |
| `_process` | `Process?` | Handle to the running JAR `adb shell` process |
| `jarReady` | `Completer<void>` | Completes when `jar.hello` handshake arrives |

### Key Methods

| Method | Description |
| :--- | :--- |
| `startJar()` | Full 7-step deploy: stop → kill → locate → push → launch → monitor |
| `stopJar()` | Kills `_process` if running |
| `resetJarReady()` | Replaces `jarReady` with a fresh `Completer` before a retry |
| `markHandshakeComplete()` | Called by `AppManager` after `jar.hello` — pushes JAR bar to `1.0` |

### Event Stream

```dart
JarEvent { String message, double progress, bool isError }
```

---

## `JarServer`

**Role:** `ServerSocket` that listens for the Logic Engine's TCP connect-back.

### Message Routing

| Message `type` | Action |
| :--- | :--- |
| `jar.hello` | Completes `JarManager.jarReady` · sets `AndroidCore.jarConnected = true` |
| Any other JSON | Passed to `AndroidCore.updateFromMessage()` |

---

## `ApkServer`

**Role:** WebSocket server that the Kotlin APK connects back to.

### State

| Field | Type | Meaning |
| :--- | :--- | :--- |
| `apkReady` | `Completer<void>` | Completes when `apk.hello` arrives |

### Message Routing

| Message `type` | Action |
| :--- | :--- |
| `apk.hello` | Completes `apkReady` · sets `AndroidCore.apkConnected = true` |
| `battery_small` | `AndroidCore.updateFromMessage()` → battery quick-update |
| `battery_update` | `AndroidCore.updateFromMessage()` → full battery snapshot |
| `volume_update` | `AndroidCore.updateFromMessage()` → all volume streams |
| `apk.permissions` | `AndroidCore.updateFromMessage()` → permission status |

---

## `DeviceManager`

**Role:** Singleton holding which ADB device to target. All ADB commands use `DeviceManager.instance.adbArgs` when building their argument lists.

### State

| Field | Meaning |
| :--- | :--- |
| `_deviceId` | Current target: `"-d"` (USB), `"ip:port"` (Wi-Fi), or a USB serial |
| `_needsDeviceSelection` | `true` → boot flow must show the picker dialog before starting |

### Key Methods

| Method | Description |
| :--- | :--- |
| `setFromArgs(args)` | Parses CLI args; calls `autoDetect()` if empty |
| `autoDetect()` | `getDevices()` → picks 1 auto, or sets `needsDeviceSelection` |
| `selectDevice(id)` | Called from dialog: maps serial → `-d`, IP → `ip:port` |
| `adbArgs` → `List<String>` | Returns `['-d']` or `['-s', _deviceId]` |

→ See **[Device Manager](DEVICE_MANAGER.md)** for the full dialog flow.

---

## `ReconnectionManager`

**Role:** Monitors connection health after a successful boot. Orchestrates multi-phase auto-recovery when a disconnection is detected.

> Complete documentation in **[Reconnection System](RECONNECTION.md)**.

---

## `AndroidCore`

**Role:** Centralized static state store. All telemetry from both the JAR and APK is parsed here. The Flutter UI reads directly from these fields.

### Connection Notifiers (reactive)

```dart
static final ValueNotifier<bool> jarConnected = ValueNotifier(false);
static final ValueNotifier<bool> apkConnected = ValueNotifier(false);
static final ValueNotifier<bool> allConnected  = ValueNotifier(false);
```

> Complete field reference in **[Data Model](DATA_MODEL.md)**.

---

## `ScrcpyVideoManager` / `ScrcpyAudioManager`

**Role:** Manages the scrcpy streaming process for individual Android app windows. Each app window has its own scrcpy process embedded via Win32 `SetParent`.

---

## `WindowManager`

**Role:** Win32 window lifecycle manager. Handles creation, destruction, resize, focus, and Z-ordering of embedded Android app windows.

---

## `WindowThumbnailService`

**Role:** Captures thumbnail frames of embedded windows for the Recents / Task View panel.

---

← [Back to README](../README.md) · [Boot Flow »](BOOT_FLOW.md) · [Reconnection »](RECONNECTION.md)
