#!/usr/bin/env bash
# PreToolUse(Bash): block unpiped `cat` of files >300 lines; read a range instead.
input=$(cat)
python3 - "$input" <<'PY'
import json, os, re, sys
data = json.loads(sys.argv[1])
cmd = data.get("tool_input", {}).get("command", "")
cwd = data.get("cwd", ".")
cd = re.match(r'\s*cd\s+(\S+)\s*&&', cmd)
if cd:
    cwd = os.path.join(cwd, os.path.expanduser(cd.group(1).strip('"')))
for m in re.finditer(r'(?:^|&&|[;(])\s*cat\s+((?:-\w+\s+)*)([^|;&<>]+?)(?=\s*(?:$|[;&)]))', cmd):
    for path in m.group(2).split():
        p = os.path.join(cwd, os.path.expanduser(path))
        if os.path.isfile(p) and sum(1 for _ in open(p, errors="ignore")) > 300:
            print(f"cat-guard: {path} >300 lines. Use sed -n 'A,Bp' or Read offset/limit.", file=sys.stderr)
            sys.exit(2)
PY
