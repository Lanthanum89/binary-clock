@echo off
setlocal

set CONFIG=%1
if "%CONFIG%"=="" set CONFIG=debug

if /I "%CONFIG%"=="release" (
  set TASK=assembleRelease
  set APK=app\build\outputs\apk\release\app-release.apk
) else (
  set TASK=assembleDebug
  set APK=app\build\outputs\apk\debug\app-debug.apk
)

cd /d "%~dp0"

if exist gradlew.bat (
  call gradlew.bat %TASK%
) else (
  where gradle >nul 2>nul
  if %ERRORLEVEL%==0 (
    gradle %TASK%
  ) else (
    echo No Gradle wrapper or gradle command found.
    echo Open this folder in Android Studio once, then run "gradle wrapper" from android/.
    exit /b 1
  )
)

if exist "%APK%" (
  echo APK ready: %cd%\%APK%
) else (
  echo Build completed, but APK file not found at expected location:
  echo %cd%\%APK%
)

endlocal
