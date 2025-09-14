# DockPreferences

A single file Swift package to read and parse the macOS Dock preferences (`com.apple.dock.plist`) into a clean Swift API.

## Features
- Load Dock settings.
- Access pinned apps, recent apps, and files/folders in the Dock.
- Simple Swift and SwiftUI friendly API.
- macOS 13+ (Not tested on older versions)

## Example

```swift
import DockPreferences

do {
    let prefs = try DockPreferences.load()
    print("Dock orientation:", prefs.orientation)
    print("Persistent apps:", prefs.persistentApps.map { $0.tileData.fileLabel })
} catch {
    print("Failed to load Dock preferences:", error)
}
```


<img width="600" height="540" alt="Screenshot" src="https://github.com/user-attachments/assets/91b16309-57b0-4df6-af72-71a2a12934b0" />
