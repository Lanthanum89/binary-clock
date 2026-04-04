# Android Native App (Kotlin + WebView)

This project wraps the existing web clock as a native Android app.

## Prerequisites

- Android Studio (latest)
- Android SDK + platform tools
- JDK 17+

## Open and Run

1. Open Android Studio.
2. Select Open and choose android.
3. Let Gradle sync.
4. Run the app on an emulator or device.

## Asset Sync

The Gradle task syncWebAssets copies files from ../../web to app/src/main/assets/web before each build.
