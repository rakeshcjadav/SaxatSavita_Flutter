#!/bin/bash
# Pin Firebase iOS SPM packages to 12.13.0 (matches firebase_core).
# cloud_firestore 6.4.x does not compile against Firebase iOS SDK 12.14+ pipeline APIs.

set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
FIREBASE_IOS_SDK_REVISION="d10045cace0b4c335c4efa8f7df7e9a9fc5a7c60"
GAM_REVISION="c2c76bebcfbb90d90ea10599f934f9af160e1604"

pin_file() {
  python3 - "$1" "$FIREBASE_IOS_SDK_REVISION" "$GAM_REVISION" <<'PY'
import json, sys
path, firebase_rev, gam_rev = sys.argv[1:4]
with open(path, encoding="utf-8") as f:
    data = json.load(f)
for pin in data.get("pins", []):
    if pin.get("identity") == "firebase-ios-sdk":
        pin["state"] = {"revision": firebase_rev, "version": "12.13.0"}
    elif pin.get("identity") == "googleappmeasurement":
        pin["state"] = {"revision": gam_rev, "version": "12.13.0"}
with open(path, "w", encoding="utf-8") as f:
    json.dump(data, f, indent=2)
    f.write("\n")
PY
}

for RESOLVED in \
  "$ROOT/ios/Runner.xcworkspace/xcshareddata/swiftpm/Package.resolved" \
  "$ROOT/ios/Runner.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved"; do
  if [ -f "$RESOLVED" ]; then
    pin_file "$RESOLVED"
    echo "Pinned Firebase iOS SDK 12.13.0 in $RESOLVED"
  fi
done

# FlutterGeneratedPluginSwiftPackage defaults to iOS 13.0; Firebase SPM plugins need 15+.
# Match the Podfile / Xcode deployment target so archives do not fail integrity checks.
PKG_MANIFEST="$ROOT/ios/Flutter/ephemeral/Packages/FlutterGeneratedPluginSwiftPackage/Package.swift"
MIN_IOS=$(grep -E "^platform :ios," "$ROOT/ios/Podfile" | sed -E "s/.*'([0-9.]+)'.*/\1/")
if [ -f "$PKG_MANIFEST" ] && [ -n "$MIN_IOS" ]; then
  python3 - "$PKG_MANIFEST" "$MIN_IOS" <<'PY'
import pathlib, re, sys

path, version = sys.argv[1:3]
text = pathlib.Path(path).read_text()
updated = re.sub(r'\.iOS\("[0-9.]+"\)', f'.iOS("{version}")', text, count=1)
if updated != text:
    pathlib.Path(path).write_text(updated)
    print(f"Synced FlutterGeneratedPluginSwiftPackage minimum iOS to {version}")
PY
fi

# Drop cached SPM artifacts so Xcode re-fetches the pinned revision.
rm -rf "$ROOT/build/ios/SourcePackages"
