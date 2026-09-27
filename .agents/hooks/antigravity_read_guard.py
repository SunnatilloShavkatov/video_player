#!/usr/bin/env python3
"""
antigravity_read_guard.py — PreToolUse(view_file) hook for Antigravity.
Prevents unconstrained full-file reads of bulky docs, generated files, and locks.
Input (stdin):  {"toolCall": {"name": "view_file", "args": {"AbsolutePath": "...", "StartLine": ..., "EndLine": ...}}}
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
    file_path = args.get("AbsolutePath", "").strip()

    if not file_path:
        respond("allow")

    bulky_patterns = [
        r'pubspec\.lock$',
        r'Podfile\.lock$',
        r'\.pbxproj$',
        r'/Pods/',
        r'/build/',
        r'/\.dart_tool/',
        r'\.xib$',
        r'CHANGELOG\.md$',
        r'INSTRUCTIONS\.md$',
        r'API_CLARIFICATION\.md$'
    ]

    is_bulky = any(re.search(p, file_path) for p in bulky_patterns)
    if is_bulky:
        start_line = args.get("StartLine")
        end_line = args.get("EndLine")

        if start_line is None or end_line is None:
            respond(
                "deny",
                f"Reading '{file_path.split('/')[-1]}' in full is blocked to conserve token budget. "
                "Use 'run_command' with 'rg -n <query> <file>' or specify a targeted line range (<= 80 lines)."
            )

        if isinstance(start_line, int) and isinstance(end_line, int):
            if (end_line - start_line) > 100:
                respond(
                    "deny",
                    f"Line range too large ({end_line - start_line + 1} lines) for bulky file. "
                    "Keep view_file slices under 80 lines to conserve token context."
                )

    respond("allow")

if __name__ == "__main__":
    main()
