# Binary Bloom Clock

A pastel-themed binary clock project with five runtime options:

- Native Windows desktop widget built with PowerShell + WinForms
- Browser-based web app built with HTML, CSS, and JavaScript
- Native Windows desktop app built with WPF + WebView2
- Native Android app built with Kotlin + WebView
- Native Wear OS watch face built with Kotlin + Canvas Watch Face API

All versions use a compact 4-row binary layout with values `8, 4, 2, 1`.

## Features

- Compact binary clock display for hours, minutes, and seconds using small dot tiles
- 12h / 24h toggle
- Light / dark theme toggle (defaults to system preference)
- Night mode: a dimmed, warm bedside view with a large digital readout under the dots
- Elegant pastel UI style
- Resizable widget window (desktop native versions)
- Drag-to-move header area (native and web widget shell behaviour)
- Mobile-optimised layout, including a dedicated landscape layout for phones
- Tray support for native app (hide/restore)
- Local state persistence (window bounds and preferences)

## Project Structure

```text
binary-clock/
├── web/                    # Browser-based web app (PWA), built with Vite
│   ├── index.html         # Web app markup
│   ├── src/
│   │   ├── main.js        # Web app logic
│   │   └── styles.css     # Web app styles (responsive design)
│   ├── public/icons/      # App icons
│   ├── vite.config.js     # Vite + vite-plugin-pwa config (manifest, service worker)
│   └── package.json
├── powershell/            # Windows desktop widget (PowerShell)
│   ├── native-widget.ps1     # Main Windows desktop widget app
│   ├── launch-clock.cmd      # One-click launcher (runs in STA mode)
│   ├── launch-clock.ps1      # PowerShell launcher script
│   └── widget-state.json     # Saved runtime state
├── windows/               # Native Windows app wrapper (WPF + WebView2)
│   ├── BinaryBloomClock.Windows.csproj
│   ├── App.xaml
│   ├── App.xaml.cs
│   ├── MainWindow.xaml
│   ├── MainWindow.xaml.cs
│   └── README.md
├── android/               # Native Android app wrapper (Kotlin + WebView)
│   ├── app/
│   ├── build.gradle.kts
│   ├── settings.gradle.kts
│   └── README.md
├── wearos-watchface/      # Native Wear OS watch face project
│   ├── app/
│   ├── build.gradle.kts
│   ├── settings.gradle.kts
│   └── README.md
├── LICENSE
└── README.md
```

### Web App Features

- Responsive design for desktop, tablet, and phone, including a compact landscape layout
- Installable as a PWA (add to home screen / install app on mobile and desktop)
- Works offline (service worker caching via vite-plugin-pwa)
- 12h / 24h toggle
- Light / dark theme toggle and a dimmed night mode for bedside use
- Elegant pastel UI

### Windows App Features

- Resizable desktop widget window
- Drag-to-move and corner-resize
- System tray support (hide/restore)
- Always-on-top toggle
- Local state persistence

### Additional Native Wrappers

- WPF + WebView2 wrapper that runs the same `web/` app in a native window
- Kotlin + WebView Android wrapper that loads local bundled assets
- Kotlin + Canvas Wear OS watch face service

## Requirements

### Native widget

- Windows
- PowerShell 5.1+ (or PowerShell 7 with Windows compatibility)
- .NET WinForms support (System.Windows.Forms, System.Drawing)

### Web app

- Any modern browser
- Node.js 22+ and npm (for local development/build only — no build tools needed to just use the live site)

## Run the Native Desktop Widget (Windows)

From the `powershell/` folder:

Option 1:

```bat
launch-clock.cmd
```

Option 2:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -STA -File .\native-widget.ps1
```

## Run the Web App

The web app is live at [lanthanum89.github.io/binary-clock](http://lanthanum89.github.io/binary-clock/), deployed automatically from `main` via GitHub Actions (`.github/workflows/deploy-pages.yml`).

### Development server

From the `web/` folder:

```bash
npm install
npm run dev
```

Then open the URL Vite prints (typically `http://localhost:5173`).

### Production build

```bash
npm run build
npm run preview
```

`npm run build` outputs the static site (including the generated manifest and service worker) to `web/dist/`.

### Mobile & Phone

1. Open the live site (or your local dev server, on the same network) on your phone browser
2. Tap the menu (⋮) → **Install app** or **Add to Home Screen**
3. The app appears in your app drawer, works offline, and adapts to both portrait and landscape orientation

## Run the Native Windows App (WPF + WebView2)

From the repo root:

```powershell
cd windows
dotnet run
```

The project automatically copies files from `../web` into the output folder.

## Run the Native Android App (Kotlin + WebView)

1. Open Android Studio.
2. Open the folder `android`.
3. Let Gradle sync and install required SDK components.
4. Run on an emulator or Android device.

During build, Gradle copies `../../web` into `app/src/main/assets/web`.

## Run the Wear OS Watch Face

1. Open Android Studio.
2. Open the folder `wearos-watchface`.
3. Let Gradle sync and install required Wear OS SDK components.
4. Run on a Wear OS emulator or watch.
5. Select **Binary Bloom** as the active watch face.

## Native Widget Controls

Top buttons:

- `12h` / `24h`: Switch time format
- `Pin`: Toggle always-on-top
- `Fit`: Fit widget to screen bounds
- `Tray`: Hide to system tray
- `Close`: Exit app

Other behaviours:

- Drag header area to move
- Drag edges/corners to resize
- Double-click tray icon to restore

## Notes

- State is saved to `widget-state.json` in the project folder.
- If PowerShell execution policy blocks startup, run with `-ExecutionPolicy Bypass` as shown above.

## Licence

This project is licensed under the MIT Licence. See the `LICENSE` file for details.
