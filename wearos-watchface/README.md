# Wear OS Watch Face (Binary Bloom)

This folder contains a standalone Wear OS watch face project for Binary Bloom.

It uses a native Canvas watch face service (not WebView), with compact binary dots for:

- Hours
- Minutes
- Seconds

## Prerequisites

- Android Studio (latest stable)
- Wear OS SDK components installed
- JDK 17+
- A Wear OS emulator or physical watch for testing

## Open and Run

1. Open Android Studio.
2. Select Open and choose `wearos-watchface`.
3. Let Gradle sync and install any missing SDK components.
4. Run the `app` configuration on a Wear OS emulator/device.
5. On the watch, choose **Binary Bloom** as the active watch face.

## Build APK From Terminal

From `wearos-watchface`:

```powershell
./gradlew.bat assembleDebug
```

Expected output path:

- `app/build/outputs/apk/debug/app-debug.apk`

## Notes for Play Store Release

This project now includes:

- Watch-face preview assets in app resources and manifest metadata
- Basic branded app/watch-face icon drawable
- A built-in watch-face user setting for 12-hour vs 24-hour time format

For final Google Play publication, you will usually still want to add:

- High-resolution marketing screenshots and listing images in Play Console
- Finalized production branding artwork (PNG/WebP variants)
- Release signing configuration
- Store listing assets and policy declarations

The current implementation is a clean baseline and is ready for further visual polish.
