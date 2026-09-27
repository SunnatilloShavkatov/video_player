#!/usr/bin/env python3
"""
antigravity_plugin_guard.py — PostToolUse hook for Antigravity.
Inspects recently modified Swift, Kotlin, and Dart files to enforce:
  1. File line count limit (~500 lines, PlayerView ~450)
  2. Darwin platform boundaries (Common/ has no UIKit/AppKit, iOS/ has #if os(iOS))
  3. Seconds contract (no inMilliseconds in lib/src)
Output (stdout): {}
"""
import sys
import os
import json
import subprocess
import re

def main():
    try:
        # Consume stdin if any
        _ = sys.stdin.read()
    except Exception:
        pass

    # Find modified files in git
    try:
        res = subprocess.run(
            ["git", "diff", "--name-only"],
            capture_output=True,
            text=True,
            check=True
        )
        modified_files = [f.strip() for f in res.stdout.splitlines() if f.strip()]
    except Exception:
        modified_files = []

    violations = []

    for rel_path in modified_files:
        if not os.path.isfile(rel_path):
            continue

        # 1. File line limits
        limit = 0
        if rel_path.endswith("PlayerView.swift"):
            limit = 450
        elif rel_path.endswith((".swift", ".kt", ".dart")):
            limit = 500

        if limit > 0:
            with open(rel_path, "r", encoding="utf-8", errors="ignore") as f:
                lines = f.readlines()
            count = len(lines)
            if count > limit:
                violations.append(
                    f"File '{rel_path}' is {count} lines (limit: {limit}). "
                    f"Extract focused subcomponents instead of growing the file (AGENTS.md 'File size rule')."
                )

        # 2. Darwin platform imports in Common/
        if "darwin/" in rel_path and "/Common/" in rel_path and rel_path.endswith(".swift"):
            with open(rel_path, "r", encoding="utf-8", errors="ignore") as f:
                content = f.read()
            # Check for top-level UIKit/AppKit/Cocoa imports outside #if
            lines = content.splitlines()
            depth = 0
            for idx, line in enumerate(lines, 1):
                stripped = line.strip()
                if stripped.startswith("#if"):
                    depth += 1
                elif stripped.startswith("#endif"):
                    depth = max(0, depth - 1)
                elif depth == 0 and re.match(r'^import\s+(UIKit|AppKit|Cocoa|SnapKit|Flutter|FlutterMacOS)\b', stripped):
                    violations.append(
                        f"Common/ file '{rel_path}:{idx}' imports platform-specific module '{stripped}'. "
                        "Common/ must compile on both iOS and macOS without UI framework imports."
                    )

        # 3. Darwin #if os wrappers
        if "darwin/" in rel_path and "/iOS/" in rel_path and rel_path.endswith(".swift"):
            with open(rel_path, "r", encoding="utf-8", errors="ignore") as f:
                first_lines = "".join(f.readlines()[:5])
            if "#if os(iOS)" not in first_lines:
                violations.append(f"iOS file '{rel_path}' must begin with '#if os(iOS)' wrapper.")

        if "darwin/" in rel_path and "/macOS/" in rel_path and rel_path.endswith(".swift"):
            with open(rel_path, "r", encoding="utf-8", errors="ignore") as f:
                first_lines = "".join(f.readlines()[:5])
            if "#if os(macOS)" not in first_lines:
                violations.append(f"macOS file '{rel_path}' must begin with '#if os(macOS)' wrapper.")

        # 4. Seconds contract in lib/src
        if rel_path.startswith("lib/src/") and rel_path.endswith(".dart"):
            with open(rel_path, "r", encoding="utf-8", errors="ignore") as f:
                content = f.read()
            # strip comments
            clean_content = re.sub(r'//.*$', '', content, flags=re.MULTILINE)
            if "inMilliseconds" in clean_content:
                violations.append(
                    f"'{rel_path}' uses 'inMilliseconds'. "
                    "Time values must cross the method channel in SECONDS (int full-screen, double embedded)."
                )

    if violations:
        sys.stderr.write("⚠️  [Antigravity Plugin Guard Violations]:\n")
        for v in violations:
            sys.stderr.write(f"  - {v}\n")

    json.dump({}, sys.stdout)
    sys.exit(0)

if __name__ == "__main__":
    main()
