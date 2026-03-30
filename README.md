# Binary Bloom Clock

A pastel-themed binary clock project with two runtime options:

- Native Windows desktop widget built with PowerShell + WinForms
- Browser-based web app built with HTML, CSS, and JavaScript

Both versions currently use a compact 4-row binary layout with values `8, 4, 2, 1`.

## Features

- Compact binary clock display for hours, minutes, and seconds
- 12h / 24h toggle
- Elegant pastel UI style
- Resizable widget window (native version)
- Drag-to-move header area (native and web widget shell behavior)
- Tray support for native app (hide/restore)
- Local state persistence (window bounds and preferences)

## Project Structure

```
binary-clock/
├── web/                    # Browser-based web app (PWA)
│   ├── index.html         # Web app markup
│   ├── styles.css         # Web app styles (responsive design)
│   ├── script.js          # Web app logic
│   ├── manifest.json      # PWA manifest for app installation
│   └── service-worker.js  # Offline support & caching
├── windows/               # Windows desktop widget (PowerShell)
│   ├── native-widget.ps1     # Main Windows desktop widget app
│   ├── launch-clock.cmd      # One-click launcher (runs in STA mode)
│   ├── launch-clock.ps1      # PowerShell launcher script
│   └── widget-state.json     # Saved runtime state
├── LICENSE
└── README.md
```

### Web App Features

- Responsive design for desktop, tablet, and phone
- Installable as PWA (add to home screen on mobile)
- Works offline (service worker caching)
- 12h / 24h toggle
- Elegant pastel UI

### Windows App Features

- Resizable desktop widget window
- Drag-to-move and corner-resize
- System tray support (hide/restore)
- Always-on-top toggle
- Local state persistence

## Requirements

### Native widget

- Windows
- PowerShell 5.1+ (or PowerShell 7 with Windows compatibility)
- .NET WinForms support (System.Windows.Forms, System.Drawing)

### Web app

- Any modern browser

## Run the Native Desktop Widget (Windows)

From the `windows/` folder:

Option 1:

```bat
launch-clock.cmd
```

Option 2:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -STA -File .\native-widget.ps1
```

## Run the Web App

### Quick start (local file)

Open `web/index.html` directly in a browser.

### Development server (recommended)

From the `web/` folder:

```bash
python -m http.server 5500
```

Then open: `http://localhost:5500/index.html`

### Mobile & Phone

1. Open `web/index.html` on your phone browser (or access via local network at `http://<your-ip>:5500`)
2. Tap the menu (⋮) → **Install app** or **Add to Home Screen**
3. The app appears in your app drawer and works offline

## Native Widget Controls

Top buttons:

- `12h` / `24h`: Switch time format
- `Pin`: Toggle always-on-top
- `Fit`: Fit widget to screen bounds
- `Tray`: Hide to system tray
- `Close`: Exit app

Other behaviors:

- Drag header area to move
- Drag edges/corners to resize
- Double-click tray icon to restore

## Notes

- State is saved to `widget-state.json` in the project folder.
- If PowerShell execution policy blocks startup, run with `-ExecutionPolicy Bypass` as shown above.

## License

This project is licensed under the MIT License. See the `LICENSE` file for details.
