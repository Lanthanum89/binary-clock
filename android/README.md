# Android Native App (Kotlin + WebView)

This project wraps the existing web clock as a native Android app.

The Android runtime uses a compact app mode optimised for phone screens:

- Dot-based binary lights (instead of rectangular tiles)
- Portrait and landscape layouts tuned to keep the full clock visible
- Automatic full-screen fitting inside the Android WebView

## Prerequisites

- Android Studio (latest)
- Android SDK + platform tools
- JDK 17+

## Open and Run

1. Open Android Studio.
2. Select Open and choose android.
3. Let Gradle sync.
4. Run the app on an emulator or device.

## Build APK From Terminal

From the `android` folder:

```powershell
./build-apk.ps1
```

Or from Command Prompt:

```bat
build-apk.cmd
```

Release build:

```powershell
./build-apk.ps1 -Configuration release
```

Expected output paths:

- Debug: `app/build/outputs/apk/debug/app-debug.apk`
- Release: `app/build/outputs/apk/release/app-release.apk`

If `gradlew.bat` does not exist yet, open this folder in Android Studio once and run:

```bash
gradle wrapper
```

## Asset Sync

The Gradle task syncWebAssets copies files from ../../web to app/src/main/assets/web before each build.

## Related Project

If you want a proper Wear OS watch face (for example for Google Play), use the standalone project in `../wearos-watchface`.
