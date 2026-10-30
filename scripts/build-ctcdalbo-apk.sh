#!/usr/bin/env bash
set -euo pipefail
project_root="$(cd "$(dirname "$0")/.." && pwd)"
api_url="${1:?Usage: scripts/build-ctcdalbo-apk.sh https://your-backend-domain}"
flutter_command="${FLUTTER_BIN:-flutter}"
cd "$project_root/mobile"
"$flutter_command" build apk --release --dart-define="API_URL=$api_url"
mkdir -p "$project_root/ctcdalbo"
cp build/app/outputs/flutter-apk/app-release.apk "$project_root/ctcdalbo/ctcdalbo.apk"
cp assets/brand/ctc-dalbo-logo.png "$project_root/ctcdalbo/ctcdalbo-logo.png"
cp assets/brand/ctc-dalbo-icon.png "$project_root/ctcdalbo/ctcdalbo-icon.png"
cd "$project_root"
shasum -a 256 ctcdalbo/ctcdalbo.apk > ctcdalbo/ctcdalbo.apk.sha256
