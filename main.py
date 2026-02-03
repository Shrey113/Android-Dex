import subprocess

EVENT_DEVICE = "/dev/input/event8"
RECORD_FILE = "events.txt"


# ---------------- RECORD ----------------
def record_events():
    print("\n[RECORD MODE]")
    print("Recording touch events...")
    print("Press CTRL + C to stop\n")

    with open(RECORD_FILE, "w") as f:
        p = subprocess.Popen(
            ["adb", "shell", "getevent", "-l", EVENT_DEVICE],
            stdout=subprocess.PIPE,
            text=True
        )

        try:
            for line in p.stdout:
                f.write(line)
        except KeyboardInterrupt:
            p.terminate()
            print(f"\nSaved to {RECORD_FILE}")


# ---------------- REPLAY (NO ROOT) ----------------
def replay_events():
    print("\n[REPLAY MODE - NO ROOT]")
    print("Replaying using adb input tap\n")

    x = None
    y = None
    touching = False

    with open(RECORD_FILE, "r") as f:
        for line in f:
            line = line.strip()

            if "ABS_MT_POSITION_X" in line:
                x = int(line.split()[-1], 16)

            elif "ABS_MT_POSITION_Y" in line:
                y = int(line.split()[-1], 16)

            elif "BTN_TOUCH DOWN" in line:
                touching = True

            elif "BTN_TOUCH UP" in line and touching:
                if x is not None and y is not None:
                    print(f"Tap at ({x}, {y})")
                    subprocess.run([
                        "adb", "shell", "input", "tap",
                        str(x), str(y)
                    ])
                touching = False


# ---------------- MAIN ----------------
def main():
    print("==== TOUCH RECORD & REPLAY (NO ROOT) ====")
    print("1. Record touch events")
    print("2. Replay recorded touches")
    choice = input("Select (1/2): ").strip()

    if choice == "1":
        record_events()
    elif choice == "2":
        replay_events()
    else:
        print("Invalid option")


if __name__ == "__main__":
    main()
