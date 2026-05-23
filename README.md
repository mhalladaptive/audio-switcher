# Audio Switcher — macOS Menu Bar App

A lightweight menu bar app for quickly switching audio input and output devices on macOS.

## Build & Run

Open Terminal on your Mac, navigate to the folder with AudioSwitch.swift and run:

```
swiftc -framework Cocoa -framework CoreAudio AudioSwitcher.swift -o AudioSwitcher && ./AudioSwitcher
```

That's it. A speaker icon will appear in your menu bar.


## Make it a permanent app (optional)
To run it as a proper `.app` you can move to Applications and launch at login:

# Build
```
swiftc -framework Cocoa -framework CoreAudio AudioSwitcher.swift -o AudioSwitcher
```
# Wrap in a .app bundle
```
mkdir -p AudioSwitcher.app/Contents/MacOS
cp AudioSwitcher AudioSwitcher.app/Contents/MacOS/AudioSwitcher
cat > AudioSwitcher.app/Contents/Info.plist << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>AudioSwitcher</string>
    <key>CFBundleIdentifier</key>
    <string>com.local.audioswitcher</string>
    <key>CFBundleName</key>
    <string>Audio Switcher</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>LSUIElement</key>
    <true/>
</dict>
</plist>
EOF
```

# Move to Applications
move   AudioSwitcher.app -> Applications Folder

Launch as any other Application in the Applications Folder

# Open it in terminal
```
open /Applications/AudioSwitcher.app
```

To launch at login: System Settings → General → Login Items → add AudioSwitcher.

## How it works

- Click the speaker icon in the menu bar
- **OUTPUT** section — your current output device is checked; click any other to switch
- **INPUT** section — your current input device is checked; click any other to switch
- The menu refreshes every 2 seconds to pick up newly connected devices
