# Scribo

On-screen annotation overlay for macOS (native AppKit, Apple Silicon & Intel).
A spiritual port of Linux's [gromit-mpx](https://github.com/bk138/gromit-mpx):
draw on top of anything — presentations, demos, screen recordings, teaching.

## Features

- **Transparent full-screen overlay** on every display, floating above the Dock
  and menu bar.
- **Non-activating** — drawing never steals focus from the app underneath.
- **Click-through when idle**: toggle draw mode on/off instantly.
- **Tools**: pen, highlighter, line, arrow, rectangle, ellipse, eraser.
- **Colors & widths** picked from the menu-bar menu (configurable palette).
- **Undo / redo / clear**.
- **Multi-monitor** aware; rebuilds automatically when displays change.
- **Global hot keys** via the Carbon Hot Key API — *no* Accessibility
  permission required.
- **Menu-bar app** (`LSUIElement`), no Dock icon.

## Hot keys

| Key        | Action            |
|------------|-------------------|
| `F9`       | Toggle draw mode  |
| `F10`      | Clear screen      |
| `F11`      | Undo              |
| `⇧ F11`    | Redo              |

Tools, colors and widths are also switchable from the menu-bar icon (pencil).

> Tip: if F9–F11 trigger macOS's default function-key behaviour, enable
> *"Use F1, F2, etc. keys as standard function keys"* in
> **System Settings → Keyboard**, or hold `fn`.

## Build & run

Requires Xcode command-line tools (Swift 5.9+).

```bash
# Quick run (plain executable — menu-bar icon appears, but no bundle):
swift run

# Build a proper Scribo.app bundle:
./make-app.sh
open .build/Scribo.app
```

The pencil icon appears in the menu bar. Press **F9** and draw.

## Configuration

On first launch Scribo writes a config file to:

```
~/Library/Application Support/Scribo/config.json
```

Edit it via the menu-bar menu → **Edit Config File…**. You can set the default
color, default pen width, and the quick-pick palette (hex colors).

## Permissions

- **Drawing over other apps**: works out of the box (no permission prompt) —
  Scribo only *paints over* the screen, it doesn't read it.
- **Global hot keys**: handled by the Carbon Hot Key API, which needs no
  Accessibility grant.
- To **distribute** the app to others, sign & notarize it with an Apple
  Developer ID (otherwise Gatekeeper warns on first open).

## Architecture

| File | Responsibility |
|------|----------------|
| `main.swift` | Entry point; `.accessory` activation policy |
| `AppDelegate.swift` | Wires settings, overlay, status bar, hot keys |
| `AppSettings.swift` | Shared mutable drawing state |
| `Tool.swift` | Tool definitions |
| `Stroke.swift` | One mark + its `NSBezierPath` builder |
| `CanvasView.swift` | Transparent per-display drawing surface |
| `OverlayWindow.swift` | Borderless non-activating floating panel |
| `OverlayController.swift` | One window/canvas per screen; command fan-out |
| `HotKeyManager.swift` | Carbon global hot keys |
| `StatusBarController.swift` | Menu-bar icon + menu |
| `Preferences.swift` | JSON config load/save |

## Roadmap ideas

- Customisable hot keys in the config file
- On-screen tool HUD
- Snapshot the annotated screen to an image
- Text-insertion tool
- Pressure / tilt support for pens
