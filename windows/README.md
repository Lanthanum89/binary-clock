# Windows Native App (WPF + WebView2)

This project wraps the existing web clock as a native Windows desktop app.

## Prerequisites

- .NET SDK 9+
- Windows 10/11
- WebView2 Runtime (usually preinstalled on modern Windows)

## Run

```powershell
cd windows
dotnet run
```

The project automatically copies files from ../web into the build output under web/.
