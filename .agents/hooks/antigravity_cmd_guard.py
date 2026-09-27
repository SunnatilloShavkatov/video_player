#!/usr/bin/env python3
"""
antigravity_cmd_guard.py — PreToolUse(run_command) hook for Antigravity.
Prevents builds, clean runs, gradlew, and context-flooding raw test commands.
Adheres to the Antigravity PreToolUse JSON contract:
Input (stdin):  {"toolCall": {"name": "run_command", "args": {"CommandLine": "..."}}}
Output (stdout): {"decision": "allow"|"deny", "reason": "..."}
"""
import sys
import json
import re

def respond(decision: str, reason: str = ""):
    resp = {"decision": decision}
    if reason:
        resp["reason"] = reason
    json.dump(resp, sys.stdout)
    sys.exit(0)

def main():
    try:
        payload = json.load(sys.stdin)
    except Exception:
        respond("allow")

    tool_call = payload.get("toolCall", {})
    args = tool_call.get("args", {})
    cmd = args.get("CommandLine", "").strip()

    if not cmd:
        respond("allow")

    # Split into shell pipeline/segment commands
    # Clean quotes/parentheses
    segments = re.split(r'[;&|()]+', cmd)

    banned_build_patterns = [
        r'\bflutter\s+(build|run|clean|pub\s+get|pub\s+upgrade)\b',
        r'\b(pod\s+install|pod\s+update|xcodebuild)\b',
        r'(\./gradlew|\bgradlew|\bgradle\s+)\b'
    ]

    for seg in segments:
        seg = seg.strip()
        if not seg:
            continue

        # Strip environment variables or wrapper prefixes (e.g., time, fvm, env)
        seg_clean = re.sub(r'^(time|sudo|nice|env|fvm|exec)\s+', '', seg)
        seg_clean = re.sub(r'^[A-Za-z_][A-Za-z0-9_]*=\S*\s+', '', seg_clean)

        for pattern in banned_build_patterns:
            if re.search(pattern, seg_clean):
                respond(
                    "deny",
                    "build/run/clean and native builds are developer-only (AGENTS.md). "
                    "Ask the user instead. For compile checks, use: "
                    "bash .claude/skills/darwin-typecheck/scripts/typecheck.sh or "
                    "bash .claude/skills/android-typecheck/scripts/typecheck.sh"
                )

        if re.search(r'\bflutter\s+test\b', seg_clean):
            if not re.search(r'(-r|--reporter)\s+(failures-only|silent)', seg_clean):
                respond(
                    "deny",
                    "Raw test output floods the context window. "
                    "Always run tests with: flutter test -r failures-only [test/<file>_test.dart]"
                )

        # Catch dumping generated or bulky files
        if re.search(r'^(cat|less|more|bat|head\s+-n\s+[1-9]\d{2,})\s+', seg_clean):
            if re.search(r'(pubspec\.lock|\.pbxproj|CHANGELOG\.md|INSTRUCTIONS\.md|Podfile\.lock)', seg_clean):
                respond(
                    "deny",
                    "Dumping bulky/generated files floods context. "
                    "Use 'rg -n <query> <file>' or head -n 40 instead."
                )

    respond("allow")

if __name__ == "__main__":
    main()
