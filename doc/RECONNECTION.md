# 🔄 Reconnection System

← [Back to README](../README.md)

> Everything about how Android DEX detects, handles, and recovers from connection loss — in one place. Phases, triggers, failure states, UI behaviour, and the overlay system.

---

## Overview

Once the boot sequence completes successfully, `ReconnectionManager` takes over as the **connection watchdog**. It monitors both the Logic Engine (JAR) and Feature Hub (APK) connections independently, and executes a two-phase recovery strategy when either drops.

```
Boot Complete
     │
     ▼
ReconnectionManager.startMonitoring()
     │
     ▼  (Listens to ValueNotifier<bool>)
AndroidCore.jarConnected ──┐
AndroidCore.apkConnected ──┴──► _onConnectionChanged()
                                        │
                            ┌───────────▼────────────┐
                            │  Is _busy? → skip       │
                            │  Both connected? → idle │
                            └───────────┬────────────-┘
                                        │
                                        ▼
                                  Begin Recovery
```

---

## Recovery Phases

### Phase 1 — Quick Reconnect

**Triggered:** Immediately on first disconnection detected  
**Goal:** Re-establish the ADB link and restore TCP/WebSocket connections without re-deploying anything

```
Quick Reconnect
     │
     ├─ adb connect [device ip or -d]
     ├─ adb reverse tcp:PORT tcp:PORT  (all ports)
     ├─ Wait for JAR to reconnect (if jarReconnecting)
     └─ Wait for APK to reconnect (if apkReconnecting)
          │
          ├─ Both reconnected? → phase: idle (success) ✓
          └─ Failed? → proceed to Phase 2
```

**User Message:** `"Attempting to reconnect to device…"`  
**UI:** Reconnecting overlay shown; desktop apps frozen

---

### Phase 2 — Full Restart (up to 2 attempts)

**Triggered:** Quick reconnect failed  
**Goal:** Re-deploy the Logic Engine and re-launch the companion APK service from scratch

```
Full Restart (attempt 1 of 2)
     │
     ├─ stopJar() ── kill existing process
     ├─ killJar() ── kill Android-side JAR
     ├─ pushJar() ── re-upload service module
     ├─ startJarRuntime() ── re-launch process
     ├─ startServerService() ── re-trigger APK service
     ├─ Wait for jar.hello + apk.hello
     │
     ├─ Success? → phase: idle ✓
     └─ Failed?  → Full Restart (attempt 2 of 2)
                        │
                        ├─ Success? → phase: idle ✓
                        └─ Failed?  → phase: FAILED ✗
```

**User Message:** `"Performing full restart (attempt N of 2)…"`

---

### Phase: Failed

**Triggered:** Both full restart attempts failed  
**Result:** Reconnection overlay shows a permanent error state

**User Messages:**
- Disconnection (clean): `"Device disconnected. Check your USB cable or Wi-Fi connection."`
- Unexpected error: `"Reconnection failed unexpectedly. Try restarting the application."`

---

## State Model

```dart
enum ReconnectionPhase {
  idle,           // Connected — no action needed
  quickReconnect, // Phase 1 in progress
  fullRestart,    // Phase 2 in progress
  failed,         // All recovery attempts exhausted
}

class ReconnectionStatus {
  final ReconnectionPhase phase;
  final bool jarReconnecting;   // JAR component specifically recovering
  final bool apkReconnecting;   // APK component specifically recovering
  final String message;         // Current user-facing status message
  final int attempt;            // Current attempt number (1 or 2 in Phase 2)
}
```

The UI observes `ReconnectionManager.instance.status` (a `ValueNotifier<ReconnectionStatus>`) and updates the overlay in real-time.

---

## Partial Disconnection

The system handles **partial disconnections** — where only one component drops:

| Scenario | `jarReconnecting` | `apkReconnecting` | Recovery Action |
| :--- | :--- | :--- | :--- |
| JAR drops, APK fine | `true` | `false` | Only JAR-related steps run |
| APK drops, JAR fine | `false` | `true` | Only APK-related steps run |
| Both drop | `true` | `true` | Full recovery for both |

---

## Reconnecting Overlay

`ReconnectingOverlay` is a full-screen widget that appears over the desktop UI during recovery.

### What it shows

- **Phase indicator** — which phase is running
- **Component status** — JAR and APK individual status pills
  - 🟡 Reconnecting...
  - 🔴 Failed
  - 🟢 Connected
- **Attempt counter** — "Attempt 1 of 2" during full restart
- **User message** — plain-English status
- **Final error state** — when `phase == failed`, shows the disconnect reason

### What it prevents

The overlay blocks all user interaction with the desktop until either:
- Recovery succeeds → overlay dismisses automatically
- Recovery fails → overlay stays up with the error message

---

## Monitoring Lifecycle

| Event | What `ReconnectionManager` does |
| :--- | :--- |
| `startMonitoring()` called | Registers listeners on `jarConnected` + `apkConnected` notifiers |
| Connection drops | Triggers `_onConnectionChanged()` → starts recovery if not `_busy` |
| Recovery succeeds | Sets `phase = idle`, clears `_busy` |
| Recovery fails | Sets `phase = failed`, clears `_busy` |
| App restart | `startMonitoring()` called again after next successful boot |

> **Note:** `startMonitoring()` is idempotent — calling it when already monitoring is a no-op.

---

← [Back to README](../README.md) · [Modules »](MODULES.md) · [Data Model »](DATA_MODEL.md)
