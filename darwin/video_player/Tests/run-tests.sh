#!/usr/bin/env bash
# Runs the pure-Swift unit tests (Common/ logic without UIKit/AppKit) on macOS with plain
# swiftc + XCTest. Needs no Flutter build, so it also works where `swift test` cannot
# resolve the generated FlutterFramework package. Usage: darwin/video_player/Tests/run-tests.sh
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
SRC="$HERE/../Sources/video_player/Common"
OUT="$(mktemp -d)"
BUNDLE="$OUT/CommonTests.xctest"
DEV="$(xcode-select -p)/Platforms/MacOSX.platform/Developer"

mkdir -p "$BUNDLE/Contents/MacOS"
cat > "$BUNDLE/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<plist version="1.0"><dict>
<key>CFBundleExecutable</key><string>CommonTests</string>
<key>CFBundleIdentifier</key><string>uz.plugin.video-player.CommonTests</string>
<key>CFBundlePackageType</key><string>BNDL</string>
</dict></plist>
PLIST

xcrun swiftc -parse-as-library -emit-library -module-name CommonTests \
  -F "$DEV/Library/Frameworks" -I "$DEV/usr/lib" -L "$DEV/usr/lib" -lXCTestSwiftSupport -Xlinker -rpath -Xlinker "$DEV/Library/Frameworks" \
  -Xlinker -rpath -Xlinker "$DEV/usr/lib" \
  "$SRC/HTTPSURL.swift" "$SRC/SubtitleTrack.swift" "$SRC/PlayerConfiguration.swift" \
  "$SRC/VGPlayerUtils.swift" "$HERE/CommonTests/CommonTests.swift" \
  -o "$BUNDLE/Contents/MacOS/CommonTests"

xcrun xctest "$BUNDLE"
