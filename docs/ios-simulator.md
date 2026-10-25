# iOS simulator

CTC DALBO was launched successfully on the dedicated **CTC DALBO iPhone** (iPhone 16 Pro, iOS 18.6). Its UUID on this Mac is `30A7D6C2-0A4F-4DA3-A9E4-FFDD4FCC2577`.

The backend must be running at `http://localhost:5080`. Run `scripts/run-web.sh` first if needed.

## Reopen the installed app

```sh
open -a Simulator --args -CurrentDeviceUDID 30A7D6C2-0A4F-4DA3-A9E4-FFDD4FCC2577
xcrun simctl launch 30A7D6C2-0A4F-4DA3-A9E4-FFDD4FCC2577 com.localpro.localpro
```

If the device is shut down, boot it with `xcrun simctl boot <UUID>` first.

## Rebuild on this Mac

Xcode 26.3 currently has only the iOS 18.6 simulator runtime installed. Normal Flutter builds request the missing iOS 26.2 runtime. The fallback script builds directly against the simulator SDK, creates the Flutter host programmatically, and embeds simulator keychain entitlements in the executable. It adds a local networking exception and icons to the debug bundle only. Production storyboard and transport settings are preserved.

```sh
SIMULATOR_ID=30A7D6C2-0A4F-4DA3-A9E4-FFDD4FCC2577 \
FLUTTER_BIN=/Users/saedhabeb/development/flutter/bin/flutter \
./scripts/run-ios-simulator.sh
```

After installing the matching runtime through Xcode Settings → Components, use the normal `flutter run -d <UUID> --dart-define=API_URL=http://localhost:5080` workflow with an appropriate local debug transport exception. Physical devices require a reachable backend URL and normal Apple signing.

If `simctl install` stalls before reaching the installer, restart the bridge on the dedicated simulator and retry:

```sh
xcrun simctl spawn <UUID> launchctl kickstart -k user/foreground/com.apple.CoreSimulator.bridge
```
