# CTC DALBO Android package

- `ctcdalbo.apk`: Android APK built from the Flutter project in `../mobile`.
- `ctcdalbo-logo.png`: supplied CTC DALBO logo.
- `ctcdalbo-icon.png`: branded app icon.

The installed application is named **CTC DALBO** and uses the CTC DALBO launcher icon. The Android application ID remains `com.localpro.localpro` so existing installations retain their data.

This is a release-mode APK signed with the project's development key, not a Play Store production release. Its backend is **https://ctcdalbo-production.up.railway.app**, so it can connect from a physical Android phone with internet access.

Rebuild from the repository root:

```sh
scripts/build-ctcdalbo-apk.sh https://ctcdalbo-production.up.railway.app
```

The APK supports Android 7.0 (API 24) and newer, including arm64, armv7 and x86_64. A limited network-security exception permits the Android emulator's local test server; deployed servers use HTTPS.

APK binaries and checksums are local build artifacts and are not committed to GitHub. Production distribution also requires your own protected Android signing key.
