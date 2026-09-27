#!/usr/bin/env bash
# slow-cmd-guard.sh — keeps builds and context-flooding commands out of an agent turn.
#
# PreToolUse(Bash) hook. Reads {"tool_input":{"command":"..."}} on stdin.
# Exit 0 = allowed. Exit 2 = blocked, stderr goes back to the model.
#
# Rationale: CLAUDE.md forbids builds without asking (flutter build/run, pod install,
# Gradle). Raw test output and dumps of generated files cost thousands of tokens and
# teach nothing.
#
# Matching is per command word, not per substring: a banned name that appears as
# data must not be blocked — an argument (`rg "flutter build" AGENTS.md`), a quoted
# regex (`grep -E 'swiftc|xcodebuild'`) or a heredoc body (a python script).
#
# Escape hatch: ALLOW_SLOW=1 in the environment disables the guard.

set -uo pipefail

[ "${ALLOW_SLOW:-0}" = "1" ] && exit 0

payload=$(cat)

# Extract the command, drop heredoc bodies and neutralise separators inside quotes,
# so only real command boundaries survive the split below.
cmd=$(printf '%s' "$payload" | python3 -c '
import json, re, sys
cmd = json.load(sys.stdin).get("tool_input", {}).get("command", "")
lines, kept, i = cmd.split("\n"), [], 0
while i < len(lines):
    kept.append(lines[i])
    m = re.search(r"<<-?\s*[\x27\"]?(\w+)[\x27\"]?", lines[i])
    i += 1
    if m:
        while i < len(lines) and lines[i].strip() != m.group(1):
            i += 1
        i += 1
out, quote = [], None
for ch in "\n".join(kept):
    if quote:
        if ch == quote:
            quote = None
        elif ch in ";|&()\n":
            ch = " "
    elif ch in "\x27\"":
        quote = ch
    out.append(ch)
print("".join(out))
' 2>/dev/null)

# Fallback for a machine without python3: first "command" value on the line.
if [ -z "${cmd:-}" ]; then
  cmd=$(printf '%s' "$payload" | sed -n 's/.*"command"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -1)
fi

[ -z "${cmd:-}" ] && exit 0

block() {
  echo "slow-cmd-guard: blocked in-turn command" >&2
  echo "  $1" >&2
  exit 2
}

# Wrappers that leave the real command inside the same segment:
# `time flutter test`, `FOO=1 flutter build`, `fvm flutter run`.
strip_wrappers() {
  local seg="$1" trimmed
  while :; do
    trimmed=${seg#"${seg%%[![:space:]]*}"}
    case "$trimmed" in
      time\ *|sudo\ *|nice\ *|env\ *|command\ *|exec\ *|fvm\ *)
        seg=${trimmed#* } ;;
      [A-Za-z_][A-Za-z0-9_]*=*\ *)
        seg=${trimmed#* } ;;
      *)
        printf '%s' "$trimmed"; return ;;
    esac
  done
}

# Shell separators end one command and start another. Backticks are NOT split on:
# they are far more often prose than legacy command substitution.
segments=$(printf '%s\n' "$cmd" | tr ';|&()' '\n\n\n\n\n')

while IFS= read -r raw; do
  [ -z "$raw" ] && continue
  seg=$(strip_wrappers "$raw")
  case "$seg" in
    "flutter build"*|"flutter run"*|"flutter clean"*|"flutter pub get"*|"flutter pub upgrade"*)
      block "build/run/clean/pub get are the developer's call (CLAUDE.md). Ask instead. Compile signal: .claude/skills/{darwin,android}-typecheck/scripts/typecheck.sh" ;;
    "pod install"*|"pod update"*|"xcodebuild"*|"./gradlew"*|"gradlew"*|"gradle "*|"bash gradlew"*)
      block "native builds are the developer's call (CLAUDE.md). Ask instead. Compile signal: darwin-typecheck / android-typecheck skill." ;;
    "flutter test"*)
      # Allowed, but only with a compact reporter: the default one prints every test.
      printf '%s' "$seg" | grep -qE -- '(-r|--reporter)[ =]+(failures-only|silent)' \
        || block "raw test output floods the context. Use: flutter test -r failures-only [test/<file>_test.dart]" ;;
  esac

  # Dumping a generated or bulky file costs thousands of tokens and teaches nothing.
  case "${seg%% *}" in
    cat|less|more|bat)
      case "$seg" in
        *pubspec.lock*|*.pbxproj*|*/build/*|*Pods/*|*.dart_tool*|*.xib*|*CHANGELOG.md*|*INSTRUCTIONS.md*)
          block "generated/bulky/stale file. Use rg -n '<pattern>' <file> or head -n 40 (CHANGELOG: release-bump skill)." ;;
      esac ;;
  esac
done <<EOF
$segments
EOF

exit 0
