# 🛡️ Error Handling

← [Back to README](../README.md)

> Philosophy, principles, and a complete reference table for all user-facing error messages in Android DEX.

---

## Philosophy

> **Technical information stays in dev logs. Plain English reaches the user.**

Android DEX operates on a strict two-tier messaging system:

| Tier | Who Sees It | Content | Example |
| :--- | :--- | :--- | :--- |
| **Dev Log** | Developer (console / logcat) | Raw process output, stack traces, exit codes, file paths | `[JAR STDERR]: java.lang.ClassNotFoundException` |
| **User Message** | End-user (boot screen) | Plain-English, actionable, no technical jargon | `"Service module not found. Please reinstall the application."` |

This means `dev.log()` and `debugPrint()` calls are completely separate from the `Stream<AppEvent>` and `Stream<JarEvent>` that drive the UI.

---

## Message Pipeline

```
Exception thrown anywhere in boot/reconnect
        │
        ▼
e.toString().replaceFirst('Exception: ', '')
        │
        ▼
_log(message, isError: true)
        │
        ▼
Stream<AppEvent> or Stream<JarEvent>
        │
        ▼
InitScreen / ReconnectingOverlay renders _ErrorBox
```

---

## Complete Error Message Reference

### `AdbProvider` — ADB & Device Errors

| Situation | User-Facing Message |
| :--- | :--- |
| `adb.exe` not found in install dir | `ADB runtime not found. Please reinstall the application.` |
| `AndroidDex.apk` not found in install dir | `Companion APK is missing from the installation folder. Please reinstall.` |
| `androiddex.jar` not found in install dir | `Service module not found in the installation folder. Please reinstall.` |
| `adb start-server` exits with non-zero | `ADB server failed to start. Close any other ADB instances and retry.` |
| `adb connect` output doesn't confirm connection | `Unable to connect to the device. Verify the IP address or check the USB cable.` |
| `adb reverse` fails on any port | `Network bridge setup failed on port {N}. The device may have revoked ADB permissions.` |

---

### `JarManager` — Logic Engine Errors

| Situation | User-Facing Message |
| :--- | :--- |
| Local `.jar` file missing | `Service module not found. Please reinstall the application.` |
| `adb push` unsuccessful | `Could not transfer service to device. Check connection and try again.` |
| Any exception during `startJar()` | `Service initialization failed. Ensure the device is connected.` |
| JAR process exits with non-zero code | `Service process stopped unexpectedly. Will attempt reconnection.` |

---

### `AppManager` — System Init Errors

| Situation | User-Facing Message |
| :--- | :--- |
| APK install fails | `App installation failed. Check device storage and USB permissions.` |
| `am start` service launch fails | `Failed to launch Android service. Try restarting the device.` |
| JAR handshake timeout (15s) | `Background service timed out. The device may be busy or unreachable.` |
| APK handshake timeout (15s) | `Companion app timed out. Ensure it is installed and running on the device.` |
| Any uncaught exception | The exception message with `"Exception: "` prefix stripped |

---

### `ReconnectionManager` — Reconnection Errors

| Situation | User-Facing Message |
| :--- | :--- |
| Device cleanly disconnected / unreachable | `Device disconnected. Check your USB cable or Wi-Fi connection.` |
| Unexpected exception during reconnect | `Reconnection failed unexpectedly. Try restarting the application.` |

---

### `DeviceManagerDialog` — IP Connection Errors

| Situation | User-Facing Message |
| :--- | :--- |
| IP field empty on Connect tap | `Enter a valid IP address` |
| `adb connect` output doesn't confirm | `Unable to connect to {ip} — verify the IP and try again.` |
| Exception during connect | `Connection failed — ensure ADB over Wi-Fi is enabled on the device.` |

---

### `InitScreen` — Boot State Errors

| Situation | User-Facing Message |
| :--- | :--- |
| User cancels device picker with no device | `No device selected. Connect an Android device` |

---

## Connection Error Detection

The boot screen uses a heuristic check to decide whether to show the **"Open ADB Manager"** button after an error:

```dart
bool _isConnectionError(String msg) {
  final l = msg.toLowerCase();
  return l.contains('connect')  ||
         l.contains('device')   ||
         l.contains('adb')      ||
         l.contains('network')  ||
         l.contains('refused')  ||
         l.contains('timeout')  ||
         l.contains('unreachable') ||
         l.contains('bridge');
}
```

If `true` → `_canPickDevice = true` → the glow button appears below the error box.  
If `false` → only the error message is shown (e.g., a reinstall-type error wouldn't benefit from the device picker).

---

## Error UI Components

### `_ErrorBox` (Boot Screen)

A red-tinted inline panel below the progress bars:

```
┌───────────────────────────────────────────────┐
│  ✖  {error message}                           │
└───────────────────────────────────────────────┘
```

### `_ChooseDeviceButton` (Boot Screen — connection errors only)

Appears below `_ErrorBox` when `_canPickDevice == true`:

```
┌───────────────────────────────────────────────┐
│  📱  Open ADB Manager — Select Device         │  ← glowing blue border
└───────────────────────────────────────────────┘
```

Clicking triggers `_handleChooseDevice()`:
1. Opens `DeviceManagerDialog`
2. On device selection → `_resetBootState()` → `_runBoot()` (clean retry)

---

← [Back to README](../README.md) · [Modules »](MODULES.md) · [Device Manager »](DEVICE_MANAGER.md)
