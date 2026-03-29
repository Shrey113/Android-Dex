# 📡 Device Manager & ADB Manager Dialog

← [Back to README](../README.md)

> Complete reference for device selection — how the system auto-detects devices, when and how the picker dialog appears, the IP connection flow, and the `DeviceManager` singleton API.

---

## `DeviceManager` Singleton

The single source of truth for *which* ADB device to target. Every ADB command in the system builds its argument list using `DeviceManager.instance.adbArgs`.

### State

| Field | Type | Default | Meaning |
| :--- | :--- | :--- | :--- |
| `_deviceId` | `String?` | `null` | Resolved target: serial, `"ip:port"`, or `"-d"` |
| `_needsDeviceSelection` | `bool` | `false` | When `true`, the boot flow must show the dialog before starting |

### Properties

| Property | Return | Description |
| :--- | :--- | :--- |
| `deviceId` | `String` | Current target; returns `"-d"` if nothing set |
| `needsDeviceSelection` | `bool` | Whether user must pick a device |
| `isUsb` | `bool` | `_deviceId == "-d"` |
| `isWifi` | `bool` | `_deviceId` is an IP address |
| `adbArgs` | `List<String>` | `["-d"]` or `["-s", _deviceId]` |

### Key Methods

#### `setFromArgs(List<String> args)`
Called from the application entry point with CLI arguments:

```
args = ["--usb"]             → _deviceId = "-d"
args = ["192.168.1.5"]       → _deviceId = "192.168.1.5:5555"
args = ["192.168.1.5:5555"]  → _deviceId = "192.168.1.5:5555"
args = []                    → autoDetect()
```

#### `autoDetect()`
Calls `AdbProvider.instance.getDevices()` then:

| Result | Action |
| :--- | :--- |
| 0 devices | `_deviceId = "-d"` · `needsDeviceSelection = true` |
| 1 device (USB serial) | `_deviceId = "-d"` · `needsDeviceSelection = false` |
| 1 device (IP) | `_deviceId = "ip:port"` · `needsDeviceSelection = false` |
| 2+ devices | `_deviceId = first device` · `needsDeviceSelection = true` |

#### `selectDevice(String id)`
Called when the user picks a device in the dialog:

```
id = "emulator-5554"    → _deviceId = "-d"    (USB/serial → force USB flag)
id = "192.168.1.5:5555" → _deviceId = "192.168.1.5:5555"  (keep IP)
needsDeviceSelection    → false
```

---

## When Does the Dialog Appear?

The dialog is shown in **exactly two situations** — never speculatively:

### Situation 1 — Pre-Boot (no device or multiple devices)

```
App launched → setFromArgs() → autoDetect()
    │
    └── needsDeviceSelection == true?
            │
            ▼
       DeviceManagerDialog opens
            │
       User picks device or types IP
            │
       selectDevice(id) called
            │
       Boot sequence begins
```

### Situation 2 — Post-Error (connection failure during boot)

```
Boot sequence running...
    │
    └── EXCEPTION thrown
            │
            └── _isConnectionError(message)?
                    │
                    ▼
        _canPickDevice = true
        Error panel shown in boot screen
        "Open ADB Manager" button appears
            │
        User taps button → dialog opens
            │
        User picks device
            │
        _resetBootState() → _runBoot() (retry)
```

> **Key design decision:** The dialog is never auto-popped during a connection error. The user sees the error message first, then deliberately opens the manager. This ensures they understand *what* failed before choosing how to fix it.

---

## `DeviceManagerDialog` — UI Reference

**Opened via:** `showDialog()` with `barrierColor: Colors.transparent`

The transparent barrier means the InitScreen background (animated gradient) remains fully visible behind the dialog — no dark overlay.

### Layout

```
┌─────────────────────────────────────────────┐
│  📱  Android Dex — ADB Manager              │
│       Tap a device to connect instantly     │
├─────────────────────────────────────────────┤
│  ⚠ [Reason banner — why dialog opened]     │  ← only shown if reason provided
├─────────────────────────────────────────────┤
│                                             │
│  ┌─ DEVICE LIST (tap = immediate connect) ─┐ │
│  │  🔌  USB Device              ›          │ │
│  │       ABC123XYZ — tap to connect        │ │
│  ├─────────────────────────────────────────┤ │
│  │  📶  192.168.1.100:5555      ›          │ │
│  │       Wi-Fi ADB — tap to connect        │ │
│  └─────────────────────────────────────────┘ │
│                                             │
│  [or "Scanning for ADB devices…" spinner]   │
│  [or "No ADB devices found" empty state]    │
│                                             │
├─────────────────────────────────────────────┤
│  Connect via IP Address                     │
│  ┌────────────────────────┐  ┌───────────┐  │
│  │ 192.168.1.100          │  │  Connect  │  │
│  └────────────────────────┘  └───────────┘  │
│  ✗ [Inline error if IP fails]              │
├─────────────────────────────────────────────┤
│  [ ↺ Refresh Devices ]        [ ✕ Cancel ] │
└─────────────────────────────────────────────┘
```

### Interaction Model

| Action | Result |
| :--- | :--- |
| Tap any device row | `Navigator.pop(deviceId)` immediately — dialog closes |
| Type IP + press Connect / Enter | `adb connect ip:5555` runs; success → `Navigator.pop(ip)` |
| IP connection fails | Inline error message replaces Connect spinner |
| Press Refresh | Rescans `adb devices`; list reloads with fade-in animation |
| Press Cancel | `Navigator.pop(null)` — dialog closes, no device set |

### IP Connection Flow (Detail)

```
User types "192.168.1.100" → presses Connect
        │
        ▼
ip = "192.168.1.100:5555"   (auto-appends port)

AdbProvider.run(["connect", "192.168.1.100:5555"])
        │
        ├─ Output contains "connected" or "already connected"
        │       │
        │       └── Navigator.pop("192.168.1.100:5555") ✓
        │           → DeviceManager.selectDevice("192.168.1.100:5555")
        │           → Boot sequence starts / retries
        │
        └─ Any other output / exception
                │
                └── _ipError = "Unable to connect to 192.168.1.100:5555
                                — verify the IP and try again."
                    Spinner → Connect button restored
```

---

## `_DeviceRow` Widget

Each row in the device list. Hover-aware with animated border and arrow:

- **USB devices** (no `:`) → USB icon · label "USB Device" · sublabel "ABC123 — tap to connect"
- **Wi-Fi devices** (contains `:`) → Wi-Fi icon · label shows IP · sublabel "Wi-Fi ADB — tap to connect"
- On hover → blue border glows · arrow icon fades in
- On tap → immediate `Navigator.pop(deviceId)` — no additional confirm step

---

← [Back to README](../README.md) · [Boot Flow »](BOOT_FLOW.md) · [Modules »](MODULES.md)
