#!/usr/bin/env bash
# Fallback for an installed simulator runtime older than Xcode's SDK.
set -euo pipefail
repo_dir="$(cd "$(dirname "$0")/.." && pwd)"
cd "$repo_dir/mobile"
: "${SIMULATOR_ID:?Set SIMULATOR_ID to a booted iOS simulator UUID}"
flutter_bin="${FLUTTER_BIN:-flutter}"
"$flutter_bin" build ios --config-only --simulator --debug --dart-define="API_URL=${API_URL:-http://localhost:5080}"
(cd ios && pod install)
stage_dir="$(mktemp -d /private/tmp/danxaliye-ios.XXXXXX)"
python3 - "$stage_dir" <<'PY'
import plistlib,sys
from pathlib import Path
with (Path(sys.argv[1])/'entitlements.plist').open('wb') as f:
    plistlib.dump({'keychain-access-groups':['com.localpro.localpro']},f)
PY
xcodebuild -quiet -project ios/Pods/Pods.xcodeproj -target Pods-Runner -configuration Debug -sdk iphonesimulator ARCHS=arm64 ONLY_ACTIVE_ARCH=YES CODE_SIGNING_ALLOWED=NO "SYMROOT=$PWD/build/ios"
xcodebuild -quiet -project ios/Runner.xcodeproj -target Runner -configuration Debug -sdk iphonesimulator ARCHS=arm64 ONLY_ACTIVE_ARCH=YES CODE_SIGNING_ALLOWED=NO "SYMROOT=$PWD/build/ios" 'EXCLUDED_SOURCE_FILE_NAMES=*.storyboard Assets.xcassets' ASSETCATALOG_COMPILER_APPICON_NAME= 'OTHER_SWIFT_FLAGS=$(inherited) -DDANXALIYE_PROGRAMMATIC_HOST' "OTHER_LDFLAGS=\$(inherited) -Xlinker -sectcreate -Xlinker __TEXT -Xlinker __entitlements -Xlinker $stage_dir/entitlements.plist"
python3 - <<'PY'
import plistlib,shutil
from pathlib import Path
app=Path('build/ios/Debug-iphonesimulator/Runner.app')
info=app/'Info.plist'
data=plistlib.loads(info.read_bytes())
for key in ('UIMainStoryboardFile','UILaunchStoryboardName','UIMainStoryboardFile~ipad','UILaunchStoryboardName~ipad'):
    data.pop(key,None)
data['UILaunchScreen']={}
data['NSAppTransportSecurity']={'NSAllowsLocalNetworking':True}
data['CFBundleIcons']={'CFBundlePrimaryIcon':{'CFBundleIconFiles':['DanxaliyeIcon60'],'UIPrerenderedIcon':False}}
info.write_bytes(plistlib.dumps(data,fmt=plistlib.FMT_BINARY))
for scale in (2,3):
    shutil.copyfile(f'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-60x60@{scale}x.png',app/f'DanxaliyeIcon60@{scale}x.png')
PY
codesign --force --deep --sign - build/ios/Debug-iphonesimulator/Runner.app
ditto build/ios/Debug-iphonesimulator/Runner.app "$stage_dir/Runner.app"
xcrun simctl install "$SIMULATOR_ID" "$stage_dir/Runner.app"
xcrun simctl launch "$SIMULATOR_ID" com.localpro.localpro
open -a Simulator --args -CurrentDeviceUDID "$SIMULATOR_ID"
