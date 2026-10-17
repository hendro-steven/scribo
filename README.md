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

## Download & install

Grab the latest **Scribo.zip** from the
[Releases page](https://github.com/hendro-steven/scribo/releases).

1. Unzip it and move **Scribo.app** to your **Applications** folder.
2. **First launch only:** right-click **Scribo.app → Open**, then click **Open**
   in the dialog.

   > Scribo is *ad-hoc signed* (free distribution), not notarized by Apple, so
   > macOS shows a one-time "unidentified developer" warning. Opening it this way
   > once tells macOS to trust it; afterwards it launches normally.

   Prefer the Terminal? Clear the quarantine flag instead:
   ```bash
   xattr -dr com.apple.quarantine /Applications/Scribo.app
   ```
3. Look for the **pencil icon** in your menu bar. Press **F9** and draw.

## Build from source

Requires Xcode command-line tools (Swift 6.0+; code is in Swift 5 language mode).

```bash
# Quick run (plain executable — menu-bar icon appears, but no bundle):
swift run

# Build a proper Scribo.app bundle:
./make-app.sh                 # host architecture
./make-app.sh --universal     # Apple Silicon + Intel
./make-app.sh --universal --zip   # also produce a distributable Scribo.zip
open .build/Scribo.app
```

## Releasing (maintainers)

Releases are automated by GitHub Actions
([`.github/workflows/release.yml`](.github/workflows/release.yml)). Pushing a
version tag builds a **universal** `.app`, zips it, and publishes it to GitHub
Releases with install instructions and auto-generated changelog:

```bash
git tag v1.0.0
git push origin v1.0.0
```

The workflow can also be triggered manually from the **Actions** tab
(*Run workflow*) as a build check — manual runs build and verify the universal
`.app` but only **tag** pushes publish a Release. No Apple Developer account or
secrets are required — the build is ad-hoc signed on the runner.

## App icon

The icon is generated from code (no binary design assets to hand-edit). Edit the
drawing in [`tools/make-icon.swift`](tools/make-icon.swift), then regenerate the
bundled `.icns`:

```bash
./tools/make-icon.sh    # renders the art and packs Resources/Scribo.icns
```

`make-app.sh` copies `Resources/Scribo.icns` into the app bundle automatically.

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
- **Distribution**: the released build is ad-hoc signed, so users do the
  one-time right-click-Open step above. To remove that step entirely you'd sign
  & notarize with an Apple Developer ID ($99/yr).

## Architecture

The app logic lives in a library target (`ScriboCore`) so it can be unit-tested;
a thin executable target (`Scribo`) is just the entry point.

| File | Responsibility |
|------|----------------|
| `Sources/Scribo/main.swift` | Entry point; `.accessory` activation policy |
| `ScriboCore/AppDelegate.swift` | Wires settings, overlay, status bar, hot keys |
| `ScriboCore/AppSettings.swift` | Shared mutable drawing state |
| `ScriboCore/Tool.swift` | Tool definitions |
| `ScriboCore/Stroke.swift` | One mark + its `NSBezierPath` builder |
| `ScriboCore/CanvasView.swift` | Transparent per-display drawing surface |
| `ScriboCore/OverlayWindow.swift` | Borderless non-activating floating panel |
| `ScriboCore/OverlayController.swift` | One window/canvas per screen; command fan-out |
| `ScriboCore/HotKeyManager.swift` | Carbon global hot keys |
| `ScriboCore/StatusBarController.swift` | Menu-bar icon + menu |
| `ScriboCore/Preferences.swift` | JSON config load/save |

## Tests

Unit tests cover the pure-logic layer (tool classification, stroke geometry,
hex-colour parsing, config round-tripping, default settings):

```bash
swift test
```

The UI/overlay/hot-key layers aren't unit-tested (they need a running app and a
screen); CI runs `swift test` on every PR.

## Roadmap ideas

- Customisable hot keys in the config file
- On-screen tool HUD
- Snapshot the annotated screen to an image
- Text-insertion tool
- Pressure / tilt support for pens
