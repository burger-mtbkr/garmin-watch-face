# Yellow Gold — Garmin Fenix 8 Pro Watch Face

A clean, high-contrast Connect IQ watch face for the **Garmin Fenix 8 Pro
(47mm / 51mm, including MicroLED)**. Solid black background with bright
**yellow-gold** text to match a black body + yellow-gold strap.

<img width="524" height="630" alt="image" src="https://github.com/user-attachments/assets/edf220ee-d0ea-4006-b3ae-3045b3bf75b9" />


## Features

- **Clean centered layout**
  - Large `HH:MM` in the upper center
  - Date line just below
  - Bottom row of data fields: **Steps · Heart Rate · Body Battery**
- **Fully configurable** (via the Garmin Connect app *and* on-device settings):
  - **Time format** — 12-hour (`7:46`), 24-hour (`07:46`), or **Military (`0746`)**
  - **Date format** — `SAT JUN 27`, `27 JUN`, or `06/27`
  - **Accent color** — yellow-gold (default), white, red, orange, cyan, green
  - **Show/hide** each field — seconds, steps, heart rate, body battery
- Live seconds via partial updates; reduced drawing in always-on sleep mode to
  be gentle on the MicroLED panel.
- Graceful fallbacks (`--`) when heart rate or body battery data is unavailable.

## Project structure

```
manifest.xml                 # products (fenix8pro47mm/51mm), API 6.0, permissions
monkey.jungle                # build descriptor
source/
  YellowGoldApp.mc           # app entry point + onSettingsChanged
  YellowGoldView.mc          # the watch face (draw, data, sleep handling)
  Settings.mc                # reads properties with safe fallbacks
  Theme.mc                   # accent palette + background color
resources/
  drawables/                 # launcher icon
  strings/strings.xml        # all UI labels
  settings/settings.xml      # settings UI
  settings/properties.xml    # property types + defaults
```

## Building

Requires the [Connect IQ SDK](https://developer.garmin.com/connect-iq/sdk/)
(API level 6.0+) and a developer key.

**VS Code (recommended):** install the *Monkey C* extension, open this folder,
and run **Connect IQ: Build Current Project** / **Run**.

**Command line:**

```sh
monkeyc -d fenix8pro51mm -f monkey.jungle -o bin/YellowGold.prg -y /path/to/developer_key
```

Then run it in the simulator:

```sh
connectiq            # launch the simulator
monkeydo bin/YellowGold.prg fenix8pro51mm
```

> **Device IDs:** `manifest.xml` targets `fenix8pro47mm` and `fenix8pro51mm`.
> If your installed SDK names them differently, check `bin/devices.xml` in the
> SDK and update the `<iq:product>` ids — the build will tell you immediately.

## Testing checklist

1. Build for `fenix8pro51mm`; confirm black background + yellow time/date/fields.
2. Open the simulator's **Settings Editor** and exercise every setting:
   12h/24h/military, date formats, accent colors, and each show/hide toggle.
3. Toggle **Always On / sleep** and confirm the simplified low-power render.
4. Use the simulator's data-simulation panel to verify heart rate and body
   battery render, and that `--` shows when data is null.
