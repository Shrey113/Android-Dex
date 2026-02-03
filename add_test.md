Perfect — this helps a lot 👍
You **already have 80% of the PC-side infrastructure done**.
Now I’ll tell you **exactly what to do next**, step-by-step, **using ADB**, and **without breaking your current server**.

I’ll keep it **practical**, not theory.

---

# ✅ What you already have (important)

Your Dart server already:

* ✅ Accepts TCP connections
* ✅ Parses JSON lines
* ✅ Knows device IP → uses `adb -s ip:5555`
* ✅ Can run arbitrary ADB commands (`adbRun`)
* ✅ Is already coordinating with `scrcpy`

So **DO NOT rewrite anything**.

---

# 🎯 What you need to ADD next (clear goal)

You need to support **controller input messages** like:

```json
{ "type": "key-down", "id": 3 }
{ "type": "key-up",   "id": 3 }
{ "type": "tap",      "x": 500, "y": 800 }
```

…and convert them to **ADB input**.

---

# STEP 1️⃣ Add a dedicated INPUT handler (NEW)

Add this method to `AdbTcpServer`:

```dart
Future<void> _handleInputCommand(
  String ip,
  Map<String, dynamic> json,
) async {
  final type = json["type"];

  switch (type) {
    case "tap":
      final x = json["x"];
      final y = json["y"];
      await adbRun(ip, [
        "shell",
        "input",
        "tap",
        "$x",
        "$y",
      ]);
      break;

    case "swipe":
      await adbRun(ip, [
        "shell",
        "input",
        "swipe",
        "${json["x1"]}",
        "${json["y1"]}",
        "${json["x2"]}",
        "${json["y2"]}",
        "${json["duration"] ?? 50}",
      ]);
      break;

    case "keyevent":
      await adbRun(ip, [
        "shell",
        "input",
        "keyevent",
        json["code"],
      ]);
      break;
  }
}
```

This is your **ADB input bridge**.

---

# STEP 2️⃣ Hook it into `_handleCommand`

Inside `_handleCommand`, **right after JSON parsing**, add:

```dart
if (jsonData is Map<String, dynamic>) {
  if (jsonData["type"] == "tap" ||
      jsonData["type"] == "swipe" ||
      jsonData["type"] == "keyevent") {
    await _handleInputCommand(ip, jsonData);
    return;
  }
}
```

That’s it.

No refactor needed.

---

# STEP 3️⃣ Controller → PC JSON format (Android side)

From your **Android Controller App**, send **simple messages**.

### Tap

```json
{ "type": "tap", "x": 640, "y": 420 }
```

### Swipe / joystick

```json
{
  "type": "swipe",
  "x1": 600,
  "y1": 400,
  "x2": 700,
  "y2": 400,
  "duration": 16
}
```

### Keyboard

```json
{ "type": "keyevent", "code": "KEYCODE_W" }
```

ADB handles **multi-touch internally**, so no more 3-key issues.

---

# STEP 4️⃣ OPTIONAL (important for controllers)

### Don’t send DOWN/UP anymore

ADB `input` is **stateless**.

Instead of:

```
key-down
key-up
```

Use:

* short swipe loops
* repeated taps
* keyevent repeats

This avoids timing bugs.

---

# STEP 5️⃣ (Advanced) True multi-touch with `sendevent`

Only if you need **real holds / FPS games**:

* Detect touchscreen device:

```bash
adb shell getevent -pl
```

* Cache `/dev/input/eventX`
* Build `sendevent` sequences

⚠️ This is optional — most DeX apps work fine with `input tap/swipe`.

---

# 🔥 Why this fixes your problem permanently

| Problem     | Old (Accessibility) | New (ADB) |
| ----------- | ------------------- | --------- |
| 3+ keys     | ❌ impossible        | ✅ works   |
| Reliability | ❌ OEM-dependent     | ✅ stable  |
| scrcpy      | ⚠️ indirect         | ✅ native  |
| Performance | ⚠️ lag              | ✅ fast    |

This is **exactly how scrcpy itself works**.

---

# ✅ Minimal checklist (do this now)

✔ Add `_handleInputCommand`
✔ Route JSON input types
✔ Send `tap / swipe / keyevent` from controller
✔ Stop using Accessibility for heavy input

---

# 🚀 What you can do next (pick ONE)

1️⃣ Add **key-mapping profiles**
2️⃣ Add **gesture smoothing for joystick**
3️⃣ Add **FPS camera control**
4️⃣ Add **record / replay input**
5️⃣ Add **wireless ADB auto-pairing**

Just tell me the number 👌
