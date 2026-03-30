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

- `native-widget.ps1`: Main Windows desktop widget app
- `launch-clock.cmd`: One-click Windows launcher (runs native widget in STA mode)
- `launch-clock.ps1`: PowerShell launcher for native widget
- `index.html`: Web app markup
- `styles.css`: Web app styles
- `script.js`: Web app logic
- `widget-state.json`: Saved runtime state for native widget

## Requirements

### Native widget

- Windows
- PowerShell 5.1+ (or PowerShell 7 with Windows compatibility)
- .NET WinForms support (System.Windows.Forms, System.Drawing)

### Web app

- Any modern browser

## Run the Native Desktop Widget (Windows)

Option 1:

```bat
launch-clock.cmd
```

Option 2:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -STA -File .\native-widget.ps1
```

## Run the Web App

Option 1 (quick): open `index.html` directly in a browser.

Option 2 (recommended local server):

```bash
python -m http.server 5500
```

Then open:

- `http://localhost:5500/index.html`

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
