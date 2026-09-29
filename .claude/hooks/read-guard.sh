#!/usr/bin/env bash
# PreToolUse(Read): source files >300 lines must be read in ranges of <=200 lines.
input=$(cat)
python3 - "$input" <<'PY'
import json, os, sys
ti = json.loads(sys.argv[1]).get("tool_input", {})
path, limit = ti.get("file_path", ""), ti.get("limit")
if not path.endswith((".swift", ".kt", ".dart")) or not os.path.isfile(path):
    sys.exit(0)
lines = sum(1 for _ in open(path, errors="ignore"))
if lines > 300 and (limit is None or limit > 200):
    print(f"read-guard: {os.path.basename(path)} has {lines} lines. Find the range with rg -n, then Read offset/limit <= 200.", file=sys.stderr)
    sys.exit(2)
PY
