# PullTimer — Project Overview

## What It Is

PullTimer is a macOS menu bar app for setting timers by dragging down from the menu bar icon. The further you drag, the longer the timer. Inspired by Gestimer 2.

- No Dock icon, no CMD-Tab presence (`LSUIElement=YES`, `NSApp.setActivationPolicy(.accessory)`)
- Multiple concurrent timers, each with optional title
- Live countdown in the popover list
- System notifications + in-process sound on expiry
- Optional Apple Reminders sync
- Timers survive app relaunch (persisted to UserDefaults)

---

## Project Structure

```
Sources/PullTimer/
├── App/
│   ├── AppDelegate.swift          # Entry point — wires subsystems, requests notification auth
│   └── main.swift                 # NSApplication.shared.run()
├── Models/
│   ├── TimerItem.swift            # Codable struct — the core data model
│   └── TimerStore.swift           # @MainActor ObservableObject — tick loop, persistence, state
├── StatusBar/
│   └── StatusBarController.swift  # NSStatusItem, drag detection, popover, context menu
├── DragInteraction/
│   ├── DragOverlayWindow.swift    # Fullscreen transparent NSWindow (level .statusBar+1)
│   ├── DragOverlayView.swift      # CoreGraphics drawing — line, dot, duration bubble
│   └── DurationMapper.swift       # Pixels → TimeInterval (non-linear 3-segment curve)
├── Views/
│   ├── SaveTimerView.swift        # SwiftUI — floating dialog after drag release
│   ├── TimerListView.swift        # SwiftUI — popover content, 300pt wide
│   ├── TimerRowView.swift         # SwiftUI — single row with animated countdown badge
│   ├── SettingsView.swift         # SwiftUI — sound, reminders, launch-at-login toggles
│   └── ButtonStyles.swift         # Reusable SwiftUI button styles
├── Notifications/
│   └── NotificationManager.swift  # UNUserNotificationCenter wrapper + delegate
├── Reminders/
│   └── RemindersManager.swift     # EventKit actor — optional Reminders sync
└── Utilities/
    ├── TimeFormatter.swift         # "6h 46m", "30 minutes", "10:31 AM" formatters
    ├── NSWindow+Hosting.swift      # FloatingWindow — borderless NSWindow for SwiftUI views
    └── PointerCursor.swift         # .pointerCursor() SwiftUI view modifier
```

Build system: **Swift Package Manager** (not Xcode project). Build with:
```
/Library/Developer/CommandLineTools/usr/bin/swift build
```

---

## Core Data Model

```swift
struct TimerItem: Codable, Identifiable, Sendable, Equatable {
    let id: UUID
    var title: String
    let duration: TimeInterval   // original drag-set seconds (for display)
    let startedAt: Date
    let endAt: Date              // the moment the alarm fires
    let notificationID: String   // = id.uuidString
    var reminderID: String?      // EKReminder identifier, set after Reminders sync
}
```

Persisted as JSON array in `UserDefaults` key `"com.pulltimer.timers"`. On relaunch, expired items are silently discarded.

---

## Drag Interaction

The entire interaction runs on the main thread via a **synchronous event loop** (`NSApp.nextEvent` in `.eventTracking` mode). This is the correct AppKit pattern for status bar drag interactions — it bypasses the button's own tracking loop.

**Event flow:**
1. `leftMouseDown` on status bar button → `StatusBarController.trackDrag()`
2. Capture icon's screen position before entering the loop
3. Loop: `leftMouseDragged` → show `DragOverlayWindow`, draw line + bubble via `DragOverlayView`
4. `leftMouseUp` → hide overlay → if dragged past dead zone → show `SaveTimerView`; if no drag → toggle popover

**Dead zone:** 56pt (≈2cm). Below this threshold the visual feedback is faded and no timer is created.

**Duration mapping** (`DurationMapper`):
```
0 – 10% of screen  →  0 – 30 min   (fine control for short timers)
10% – 40%          →  30 min – 4h
40% – 100%         →  4h – 24h
```
Result is snapped to nearest minute, minimum 1 minute.

**Drag visual** (drawn via CoreGraphics in `DragOverlayView.draw()`):
- Purple line from icon origin to cursor
- Dot at cursor (7pt, white outline)
- Floating dark bubble (near-black, 0.93 alpha) with duration + end time text
- Bubble avoids screen edges, prefers left side of cursor

---

## Notification Strategy (Two Layers)

The app uses two complementary layers to guarantee reliable notification delivery:

**Layer 1 — In-process (100% reliable while app is alive):**
- `NSSound(named: "Glass")?.play()` — plays directly, no permissions needed, ignores Focus Mode
- `UNUserNotificationCenter` banner with 1-second delay (best-effort overlay)

**Layer 2 — Pre-scheduled UN notification (backup when app is killed):**
- Scheduled via `UNTimeIntervalNotificationTrigger` at timer creation and on relaunch
- Fires even if the app is not running
- Cancelled by `NotificationManager.cancel(id:)` when the in-process path handles it first

`TimerStore.tick()` fires every second. When a timer expires, it:
1. Removes the timer from the list
2. Calls `NotificationManager.cancel(id:)` — removes the pre-scheduled UN notification
3. Calls `NotificationManager.fireExpiry(for:)` — plays NSSound + posts a new 1-second UN banner
4. Posts `NotificationCenter.default` `.timerExpired` — for in-app visual feedback (icon flash)

On relaunch, `TimerStore.load()` reschedules UN notifications for all surviving timers.

**Limitation:** Ad-hoc signed builds (`--sign -`) cannot use `timeSensitive` entitlement, so UN notifications may be suppressed by Focus Mode. NSSound is not affected.

---

## Settings

Three toggles, persisted to `UserDefaults`:

| Key | Default | Effect |
|---|---|---|
| `notificationSoundEnabled` | `true` | Controls `NSSound` playback and `UNNotificationContent.sound` |
| `remindersEnabled` | `false` | Gates EventKit sync on every `TimerStore.add()` |
| `launchAtLogin` | `false` | Calls `SMAppService.mainApp.register/unregister()` (macOS 13+) |

The Settings window is a `FloatingWindow` (borderless `NSWindow`) with a "Close" button that closes the window only — it does NOT quit the app. The "Quit PullTimer" action is in the right-click context menu on the status bar icon.

On every open, `SettingsView` runs `.task { }` to check actual system authorization for Reminders. If permission was revoked externally, the toggle is reset to off.

---

## Reminders Sync

`RemindersManager` is declared as `actor` (not `@MainActor`) because `EKEventStore.save()` is a blocking call that must not run on the main thread.

When a timer is added with Reminders enabled:
1. Creates an `EKReminder` with `EKAlarm(absoluteDate: item.endAt)`
2. Sets `dueDateComponents` so the reminder appears in Reminders' scheduled view
3. Saves the `calendarItemIdentifier` back to `TimerItem.reminderID`
4. When the timer is manually deleted, the reminder is also removed

Permission check without prompting: `EKEventStore.authorizationStatus(for: .reminder)` — used on settings open to detect revoked access. Prompting only happens when the user explicitly enables the Reminders toggle.

Required entitlement: `com.apple.security.personal-information.calendars`

---

## Window Management

All floating UI (Save dialog, Settings) uses `FloatingWindow` from `NSWindow+Hosting.swift`:
- `styleMask: [.borderless]`
- `backgroundColor = .clear`, `isOpaque = false`
- `level = .floating`
- Hosts a SwiftUI view via `NSHostingController`
- `showAt(releasePoint:)` positions below the given screen point

`StatusBarController` holds weak/strong references to `saveWindow` and `settingsWindow`. Opening a new window always closes the previous one first.

The popover (`NSPopover`) uses `.applicationDefined` behavior — dismissed via a global event monitor that catches any mouse click outside it.

---

## Key Design Decisions

**Why synchronous drag loop instead of NSEvent tracking loop:**
The status bar button's own tracking loop swallows drag events. `NSApp.nextEvent` in `.eventTracking` mode is the standard AppKit workaround.

**Why `layoutPriority` in `TimerRowView` instead of fixed widths:**
Rows use `maxWidth: .infinity` to fill whatever width the parent provides. `layoutPriority` determines compression order: badge (2) → delete button (1) → title (0, truncates last). This correctly constrains to the 300pt popover width without any manual width math.

**Why not SwiftUI `@main App`:**
SwiftUI's `@main` fights `NSStatusItem` ownership. `AppDelegate` with `@NSApplicationMain` gives full control over activation policy and window lifecycle.

**Why `DateComponentsFormatter` for verbose strings:**
Automatically localizes to the system language (Vietnamese, English, etc.) without any manual translation tables.

---

## Known Limitations (v1.0)

- No `.timeSensitive` interrupt level without a paid Apple Developer account + notarization
- No snooze or pause functionality
- No editing of a timer after creation
- Reminders sync only adds items — no two-way sync (completing a reminder doesn't stop the timer)
- Focus Mode can suppress UN banner notifications (NSSound is unaffected)
