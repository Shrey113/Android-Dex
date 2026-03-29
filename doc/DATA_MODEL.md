# 📊 Data Model — Real-Time State

← [Back to README](../README.md)

> `AndroidCore` is the centralized, static state store holding a live mirror of the Android device's system state. All telemetry from both the Logic Engine (JAR) and Feature Hub (APK) is parsed here. This document covers the state fields, JSON message protocol, and event types.

---

## `AndroidCore` — State Fields

### Connection Status (Reactive)

These are `ValueNotifier<bool>` — Flutter widgets can listen to them directly.

```dart
static final ValueNotifier<bool> jarConnected = ValueNotifier(false);
static final ValueNotifier<bool> apkConnected = ValueNotifier(false);
static final ValueNotifier<bool> allConnected  = ValueNotifier(false);
```

---

### Battery State

| Field | Type | Source | Description |
| :--- | :--- | :--- | :--- |
| `batteryPercentage` | `int` | `battery_small`, `battery_update` | Current level (0–100) |
| `batteryCharging` | `bool` | `battery_small`, `battery_update` | Is charging? |
| `batteryPlugged` | `int` | `battery_small`, `battery_update` | Plug type int code |
| `batterySaver` | `bool` | `battery_small`, `battery_update` | Battery saver mode active? |
| `batteryTemperature` | `double` | `battery_update` | °C |
| `batteryVoltage` | `double` | `battery_update` | Volts |
| `batteryCurrentMa` | `int` | `battery_update` | Milliamps (+ charging, - discharging) |
| `batteryHealth` | `String` | `battery_update` | `"Good"`, `"Overheat"`, etc. |
| `batteryTechnology` | `String` | `battery_update` | `"Li-ion"`, `"Li-poly"` |
| `batteryPlugType` | `String` | `battery_update` | `"USB"`, `"AC"`, `"Wireless"`, `"None"` |

---

### Volume State

| Field | Type | Description |
| :--- | :--- | :--- |
| `volumeMusic` / `volumeMusicMax` | `int` | Media volume (current / max) |
| `volumeRing` / `volumeRingMax` | `int` | Ringtone volume |
| `volumeNotification` / `volumeNotificationMax` | `int` | Notification volume |
| `volumeAlarm` / `volumeAlarmMax` | `int` | Alarm volume |
| `volumeMusicAvailable` | `bool` | Stream controllable by current ringer mode |
| `volumeRingAvailable` | `bool` | Stream controllable by current ringer mode |
| `volumeNotificationAvailable` | `bool` | Stream controllable |
| `volumeAlarmAvailable` | `bool` | Stream controllable |

---

### Device State Flags

| Field | Type | Description |
| :--- | :--- | :--- |
| `wifi` | `bool` | Wi-Fi enabled |
| `wifiName` | `String` | Connected SSID |
| `bluetooth` | `bool` | Bluetooth enabled |
| `bluetoothName` | `String` | Connected device name |
| `mobileData` | `bool` | Mobile data active |
| `airplane` | `bool` | Airplane mode on |
| `mute` | `bool` | Ringer muted |
| `rotationLock` | `bool` | Auto-rotate locked |
| `location` | `bool` | Location services on |
| `torch` | `bool` | Flashlight on |

---

### Permission Status

| Field | Type | Description |
| :--- | :--- | :--- |
| `permissionLevel` | `String` | `"success"`, `"warning"`, or `"error"` |
| `permissionMessage` | `String` | Human-readable status summary |
| `permissionsData` | `Map<String, bool>` | Per-permission grant map |
| `permissionTimestamp` | `int` | Unix ms timestamp of last report |

---

## JSON Message Protocol

All messages are JSON objects sent over TCP (from JAR) or WebSocket (from APK). The `type` field routes the message to the correct handler in `updateFromMessage()`.

### `battery_small` — Realtime Battery Tick

Sent every ~1 second. Lightweight for frequent updates.

```json
{
  "type": "battery_small",
  "percentage": 87,
  "charging": true,
  "plugged": 2,
  "battery_saver": false,
  "states": {
    "wifi": true,
    "bluetooth": false,
    "mobile_data": true,
    "airplane_mode": false,
    "mute": false,
    "rotation_lock": false,
    "location": true,
    "torch": false,
    "wifi_name": "HomeNetwork",
    "bluetooth_name": ""
  }
}
```

> The `states` object is present on every message type. It's always parsed to keep device flags current.

---

### `battery_update` — Full Battery Snapshot

Sent on significant changes or at intervals. Contains full diagnostic data.

```json
{
  "type": "battery_update",
  "battery": {
    "percentage": 87,
    "charging": true,
    "plugged": 2,
    "voltage": 4.2,
    "temperature": 29.5,
    "current_ma": -1200,
    "health": "Good",
    "technology": "Li-ion",
    "plug_type": "USB",
    "battery_saver": false
  }
}
```

---

### `volume_update` — All Audio Streams

Sent when any audio stream changes. Always includes all streams.

```json
{
  "type": "volume_update",
  "streams": [
    { "stream_name": "music",        "current": 8,  "max": 15, "available": true  },
    { "stream_name": "ring",         "current": 4,  "max": 7,  "available": true  },
    { "stream_name": "notification", "current": 4,  "max": 7,  "available": true  },
    { "stream_name": "alarm",        "current": 6,  "max": 7,  "available": true  }
  ]
}
```

---

### `apk.permissions` — Runtime Permission Status

Sent on startup and when permissions change.

```json
{
  "type": "apk.permissions",
  "level": "warning",
  "message": "Notification access is not granted. Some features will be limited.",
  "timestamp": 1711700000000,
  "data": {
    "READ_CONTACTS": true,
    "POST_NOTIFICATIONS": false,
    "BIND_NOTIFICATION_LISTENER_SERVICE": false,
    "RECORD_AUDIO": true
  }
}
```

**Severity Levels:**

| Level | Meaning |
| :--- | :--- |
| `"success"` | All required permissions granted |
| `"warning"` | Some optional permissions missing — partial functionality |
| `"error"` | Critical permissions missing — core features unavailable |

---

### Handshake Messages

| Message | Direction | Meaning |
| :--- | :--- | :--- |
| `{"type":"jar.hello"}` | JAR → Windows | Logic Engine TCP connection confirmed |
| `{"type":"apk.hello"}` | APK → Windows | Feature Hub WebSocket connection confirmed |

---

## Update Flow

```
Incoming JSON message
        │
        ▼
AndroidCore.updateFromMessage(msg)
        │
        ├─ Parse "states" block → update device flags
        │
        └─ Switch on "type":
                ├─ battery_small  → quick battery fields
                ├─ battery_update → full battery snapshot
                ├─ volume_update  → all volume streams
                └─ apk.permissions → permission map + level

Flutter UI reads AndroidCore fields directly
(ValueNotifier fields trigger reactive rebuilds)
```

---

← [Back to README](../README.md) · [Modules »](MODULES.md) · [Reconnection »](RECONNECTION.md)
