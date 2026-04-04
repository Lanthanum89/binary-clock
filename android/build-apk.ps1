param(
  [ValidateSet("debug", "release")]
  [string]$Configuration = "debug"
)

$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot

$task = if ($Configuration -eq "release") { "assembleRelease" } else { "assembleDebug" }
$gradlew = Join-Path $PSScriptRoot "gradlew.bat"

if (Test-Path $gradlew) {
  & $gradlew $task
} elseif (Get-Command gradle -ErrorAction SilentlyContinue) {
  gradle $task
} else {
  Write-Host "No Gradle wrapper or gradle command found." -ForegroundColor Yellow
  Write-Host "Open this folder in Android Studio once, then run 'gradle wrapper' from android/." -ForegroundColor Yellow
  exit 1
}

$apkPath = if ($Configuration -eq "release") {
  Join-Path $PSScriptRoot "app/build/outputs/apk/release/app-release.apk"
} else {
  Join-Path $PSScriptRoot "app/build/outputs/apk/debug/app-debug.apk"
}

if (Test-Path $apkPath) {
  Write-Host "APK ready: $apkPath" -ForegroundColor Green
} else {
  Write-Host "Build completed, but APK file not found at expected location:" -ForegroundColor Yellow
  Write-Host $apkPath
}
