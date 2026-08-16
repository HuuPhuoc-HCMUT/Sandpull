# Sandpull Guide

A menu bar hourglass for Mac. Drag down to set a time, name it, and let the sand run. The pull gesture is inspired by [Gestimer](https://maddin.io/gestimer/). Sandpull is not affiliated with Gestimer.

Requires **macOS 13 Ventura** or later. Sandpull stays in the menu bar — no Dock icon, no Cmd-Tab.

---

## 1. First launch

Download `Sandpull.dmg`, open it, and drag Sandpull into Applications. If macOS blocks the app, right-click it and choose **Open**.

Then look at the **right side of the menu bar**. The hourglass is the app.

- **Click** the hourglass → timer list
- **Drag down** from the hourglass → set a duration
- **Right-click** → Settings, How it works, Quit

If macOS asks about notifications, allow them so a timer can reach you when it ends.

The in-app tour is the same four steps as this guide. Open it anytime from **How it works…** (right-click, or the ⓘ in the list / Settings).

---

## 2. Pull to set a time

Press on the hourglass and drag **down**.

| What you see | What it means |
|---|---|
| Teal line | Distance = duration |
| Hourglass on the line | Sand shifts as the time grows; the glass can rotate |
| Dark bubble | Minutes + the clock time it will end |
| Sand-colored bubble | The end time is on `:00` or `:30` |

A short dead zone at the top ignores tiny movements so a click does not create a timer. Past that, every minute is available — not 5-minute buckets. Quarter-hour end times hold for a short extra pull so they are easy to land on. Turn off **Half-hour highlight** in Settings if you do not want the sand-colored bubble.

**Cancel:** drag onto the trash near the Dock. The timer is discarded. A haptic click can confirm you entered the zone.

**Release** (not on the trash) opens the **Save** window. That is a different window from the timer list.

---

## 3. Name it, then Save

The Save window is what appears when you let go.

1. Check the duration — drag the slider or tap `5m` `10m` `15m` `30m` `1h`
2. Pick a **Label** chip, or type your own
3. **Save** creates a real timer. **Cancel** throws the pull away

Chips remember titles you have used, and a history chip can restore the last duration for that name. **Cmd+C / Cmd+V / Cmd+A** work in the text field.

In Settings → **List & Save** you can hide the time chips or the recent-name chips. A Look code also changes the shape of this window.

This is not the list. Clicking the icon opens the list. Releasing a pull opens Save.

---

## 4. The timer list

Click the hourglass (without dragging) to open the list.

**Active** — running timers. Each row reads like Gestimer: **in** remaining time, **at** the end clock, then the name. Click a row to edit. Hover to remove.

**Done** — expired timers stay here until you press **Done** on the row or **Clear done**.

At the bottom you can add a timer without pulling: type a name, set the slider, tap a chip, then **Add**. Settings → **List & Save** can hide the slider or the name chips.

ⓘ starts the guided tour. **Quit** leaves the app.

---

## 5. While a timer runs

The menu bar can show the nearest countdown next to the hourglass. Sand in the glass falls as time passes.

You can run several timers at once. They survive quitting and reopening the app.

---

## 6. When time is up

Sandpull keeps the expired timer (it moves to **Done**) and shows an in-app popup:

- **+5 min** / **+10 min** — snooze
- **Done** — clear the timer
- **×** — dismiss the popup

A sound can play if Notification Sound is on. System banners stay quiet while the app is running so the in-app popup is the one you see.

---

## 7. Settings

Right-click the hourglass → **Settings…** (or `,`). Click outside the window to close it. Text fields accept **Cmd+C / Cmd+V / Cmd+A**.

**General**

| Setting | Default | What it does |
|---|---|---|
| Notification Sound | On | Play a sound when a timer ends |
| Sync with Reminders | Off | Add each new timer to Apple Reminders |
| Launch at Login | Off | Start Sandpull when you log in |

**List & Save** — these change the timer list and the Save window.

| Setting | Default | What it does |
|---|---|---|
| List type | Gestimer | Small / Gestimer / Large — title size in the timer list |
| List slider | On | Duration bar when adding from the list |
| Recent names | On | Suggest labels you already used |
| Save presets | On | `5m` `10m` `15m` `30m` `1h` on the Save window |

**Advanced**

| Setting | Default | What it does |
|---|---|---|
| Default timer | 15m | Duration used by **Add** in the list |
| Drag start | 112 px | Dead zone before a pull begins |
| Duration curve | Balanced | Precise / Balanced / Fast — how quickly minutes grow |
| Max duration | 24h | Top of a full-screen drag (8h / 12h / 24h) |
| Menu bar countdown | On | Remaining time next to the icon |
| Hourglass rotation | On | Spin the glass while dragging |
| Half-hour highlight | On | Sand color when the end time hits :00 or :30 |
| Haptic on cancel | On | Click when you enter the trash zone |

**Looks**

On the [Looks page](https://huuphuoc-hcmut.github.io/Sandpull/store.html), pick a form, face, and chime, then **Copy code**. Paste that code (for example `sp-monument-both-bell`) at the bottom of Settings and press **Apply**.

The code changes the hourglass, the menu bar face, the expiry sound, and the chrome of the list and Save windows (corners and chips).

**Reset to defaults** restores Advanced, List & Save, and Looks.

---

## 8. The in-app tour

**How it works…** plays the four steps on your screen:

1. Watch the hourglass  
2. Drag down to choose a time  
3. Release — the Save window opens  
4. Type a name and Save — a real timer is created  

Skip or press Esc to leave. Skipping does not create a timer.

---

## 9. Short reference

| Gesture | Result |
|---|---|
| Click the hourglass | Open / close the list |
| Drag down, release | Save window → new timer |
| Drag onto the trash | Cancel |
| Click an Active row | Edit name and duration |
| Right-click | Settings, tour, Quit |
| Esc while pulling | Cancel the pull |

macOS 13+ · Apple silicon and Intel · Free · Inspired by [Gestimer](https://maddin.io/gestimer/)
