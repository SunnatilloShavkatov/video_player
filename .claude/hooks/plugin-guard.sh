#!/usr/bin/env bash
# plugin-guard.sh — enforces the mechanical AGENTS.md rules right after an edit, so a
# violation is fixed in the same turn instead of surfacing in a typecheck or review.
#
# PostToolUse(Write|Edit|MultiEdit) hook. Reads {"tool_input":{"file_path":"..."}} on stdin.
# Exit 0 = fine. Exit 2 = violation (stderr goes back to the model).
#
# Checks:
#   1. file size   — darwin/*.swift, android/src/*.kt, lib/*.dart stay under ~500 lines
#                    (PlayerView.swift ~450). Only fires when the file is over the limit AND
#                    grew vs HEAD (or the index, for staged renames), so legacy big files
#                    can still be edited — just not grown.
#   2. Common/     — compiles on iOS and macOS: no top-level UIKit/AppKit/Flutter import
#                    (inside an #if block is fine).
#   3. iOS/, macOS/ — every file wrapped in #if os(iOS) / #if os(macOS).
#   4. lib/src     — never expose milliseconds across the channel (seconds contract).

set -uo pipefail

payload=$(cat)
file_path=$(printf '%s' "$payload" | sed -n 's/.*"file_path"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -1)

[ -z "$file_path" ] && exit 0
[ -f "$file_path" ] || exit 0

rel=${file_path#"$PWD"/}
violations=()
fail() { violations+=("$1"); }

# --- 1. file size ------------------------------------------------------------
limit=0
case "$rel" in
  darwin/*/iOS/Player/PlayerView.swift) limit=450 ;;
  darwin/*.swift|android/src/*.kt|lib/*.dart) limit=500 ;;
esac
if [ "$limit" -gt 0 ]; then
  now=$(wc -l < "$file_path" | tr -d ' ')
  if [ "$now" -gt "$limit" ]; then
    before=$(git show "HEAD:$rel" 2>/dev/null | wc -l | tr -d ' ')
    [ "${before:-0}" -eq 0 ] && before=$(git show ":$rel" 2>/dev/null | wc -l | tr -d ' ')
    before=${before:-0}
    if [ "$now" -gt "$before" ]; then
      fail "$now lines (limit ~$limit, was $before) — extract a focused component in the matching folder instead of growing this file (AGENTS.md 'File size rule')"
    fi
  fi
fi

# --- 2 + 3. Darwin platform boundaries ----------------------------------------
case "$rel" in
  darwin/*/Common/*.swift)
    bad=$(awk '
      /^[[:space:]]*#if/    { depth++ }
      /^[[:space:]]*#endif/ { depth-- }
      depth == 0 && /^[[:space:]]*import (UIKit|AppKit|Cocoa|SnapKit|Flutter|FlutterMacOS)([[:space:]]|$)/ { print NR": "$0 }
    ' "$file_path")
    [ -n "$bad" ] && fail "Common/ compiles on iOS AND macOS — wrap platform imports in #if os(iOS)/#if os(macOS): $bad"
    ;;
  darwin/*/iOS/*.swift)
    grep -q '^#if os(iOS)' "$file_path" || fail "iOS/ file must be wrapped in #if os(iOS) ... #endif"
    ;;
  darwin/*/macOS/*.swift)
    grep -q '^#if os(macOS)' "$file_path" || fail "macOS/ file must be wrapped in #if os(macOS) ... #endif"
    ;;
esac

# --- 4. seconds contract --------------------------------------------------------
case "$rel" in
  lib/src/*.dart)
    sed -E 's@//.*$@@' "$file_path" | grep -qE '\binMilliseconds\b' \
      && fail "time values cross the channel in SECONDS (int full-screen, double embedded) — no inMilliseconds (AGENTS.md 'Time Value Contract')"
    ;;
esac

[ "${#violations[@]}" -eq 0 ] && exit 0
echo "plugin-guard: $rel" >&2
for v in "${violations[@]}"; do echo "  $v" >&2; done
exit 2
