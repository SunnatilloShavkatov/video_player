#!/usr/bin/env bash
# Typechecks the Darwin plugin sources for iOS and/or macOS with swiftc — no
# `flutter build`, no example app. Usage: typecheck.sh [ios|macos|all]
set -euo pipefail

PLATFORM="${1:-all}"
ROOT="$(git -C "$(dirname "$0")" rev-parse --show-toplevel)"
SRC="$ROOT/darwin/video_player/Sources/video_player"
OUT="${TMPDIR:-/tmp}/video_player_typecheck"
mkdir -p "$OUT"

FLUTTER_ROOT="$(dirname "$(dirname "$(readlink -f "$(command -v flutter)")")")"
ENGINE="$FLUTTER_ROOT/bin/cache/artifacts/engine"

find_snapkit() {
  local candidates=(
    "$ROOT/example/build/ios/SourcePackages/checkouts/SnapKit/Sources"
    "$ROOT/example/ios/Pods/SnapKit/Sources"
  )
  candidates+=("$HOME"/Library/Developer/Xcode/DerivedData/Runner-*/SourcePackages/checkouts/SnapKit/Sources)
  for dir in "${candidates[@]}"; do
    local file
    file="$(find "$dir" -name ConstraintMaker.swift 2>/dev/null | head -1)"
    if [[ -n "$file" ]]; then dirname "$file"; return; fi
  done
}

typecheck_ios() {
  local snapkit sdk target=arm64-apple-ios15.0-simulator
  snapkit="$(find_snapkit)"
  if [[ -z "$snapkit" ]]; then
    echo "SnapKit sources not found. The example app must have been resolved once" >&2
    echo "(pod install or an Xcode/Flutter iOS build) — ask the user before building." >&2
    return 1
  fi
  sdk="$(xcrun --sdk iphonesimulator --show-sdk-path)"
  xcrun swiftc -emit-module -module-name SnapKit -sdk "$sdk" -target "$target" \
    -emit-module-path "$OUT/SnapKit.swiftmodule" "$snapkit"/*.swift
  # shellcheck disable=SC2046
  xcrun swiftc -typecheck -module-name video_player -sdk "$sdk" -target "$target" \
    -I "$OUT" -F "$ENGINE/ios/Flutter.xcframework/ios-arm64_x86_64-simulator" \
    $(find "$SRC/iOS" "$SRC/Common" -name '*.swift') "$SRC/VideoPlayerPlugin.swift"
  echo "iOS: OK"
}

typecheck_macos() {
  # shellcheck disable=SC2046
  xcrun swiftc -typecheck -module-name video_player \
    -sdk "$(xcrun --sdk macosx --show-sdk-path)" -target arm64-apple-macos10.15 \
    -F "$ENGINE/darwin-x64/FlutterMacOS.xcframework/macos-arm64_x86_64" \
    $(find "$SRC/macOS" "$SRC/Common" -name '*.swift') "$SRC/VideoPlayerPlugin.swift"
  echo "macOS: OK"
}

case "$PLATFORM" in
  ios) typecheck_ios ;;
  macos) typecheck_macos ;;
  all) typecheck_ios; typecheck_macos ;;
  *) echo "usage: $0 [ios|macos|all]" >&2; exit 2 ;;
esac
