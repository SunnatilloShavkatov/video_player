#!/usr/bin/env bash
# token-report.sh — Stop hook: what THIS task cost and which tool results were heaviest.
# Never blocks a turn (always exit 0). Log: .claude/token-logs/report.log (gitignored).
# Reads only the transcript lines added since the previous Stop, so it stays fast in long sessions.
command -v jq >/dev/null 2>&1 || exit 0
input=$(cat)
sid=$(printf '%s' "$input" | jq -r '.session_id // "nosession"')
tp=$(printf '%s' "$input" | jq -r '.transcript_path // ""')
[ -f "$tp" ] || exit 0

dir="${CLAUDE_PROJECT_DIR:-$PWD}/.claude/token-logs"
mkdir -p "$dir"
state="$dir/.state-$sid"

total_lines=$(wc -l < "$tp" | tr -d ' ')
from=0
[ -f "$state" ] && from=$(cat "$state" 2>/dev/null || echo 0)
[ "$from" -gt "$total_lines" ] 2>/dev/null && from=0   # transcript rotated / compacted
echo "$total_lines" > "$state"
new=$(tail -n +"$((from + 1))" "$tp")
[ -z "$new" ] && exit 0

read -r t_in t_out t_cw t_cr ctx < <(printf '%s\n' "$new" | jq -rs '
  [ .[] | select(.type=="assistant" and .message.usage) ] as $a
  | ($a | unique_by(.message.id) | map(.message.usage)) as $u
  | [ ($u|map(.input_tokens//0)|add//0),
      ($u|map(.output_tokens//0)|add//0),
      ($u|map(.cache_creation_input_tokens//0)|add//0),
      ($u|map(.cache_read_input_tokens//0)|add//0),
      (($a|last).message.usage // {} | (.input_tokens//0)+(.cache_creation_input_tokens//0)+(.cache_read_input_tokens//0)) ]
  | @tsv' 2>/dev/null)
t_in=${t_in:-0}; t_out=${t_out:-0}; t_cw=${t_cw:-0}; t_cr=${t_cr:-0}; ctx=${ctx:-0}
total=$((t_in + t_out + t_cw + t_cr))
eff=$(( t_in + t_cw * 125 / 100 + t_cr / 10 + t_out * 5 ))

# Heaviest tool results of this task (size/4 ~ tokens) + tool call count.
# A Read without offset/limit is tagged "(full)" so whole-file reads stand out.
tools=$(printf '%s\n' "$new" | jq -rs '
  [ .[] | select(.type=="assistant") | .message.content[]? | select(.type=="tool_use")
    | {id, name,
       full: (.name=="Read" and (.input.offset==null) and (.input.limit==null)),
       arg: ((.input.file_path // .input.command // .input.pattern // .input.skill // .input.description // "")
             | tostring | gsub("\n"; " ") | sub("^cd [^&;]+(&&|;) *"; "") | sub("^.*/video_player/"; "")
             | .[0:70])} ] as $calls
  | [ .[] | select(.type=="user") | .message.content[]? | select(.type=="tool_result")
      | {id: .tool_use_id, size: (.content|tostring|length)} ] as $res
  | "calls=\($calls|length)",
    ([ $res[] as $r | $calls[] | select(.id==$r.id) | {name, arg, full, tok: ($r.size/4|floor)} ]
     | sort_by(-.tok) | .[0:5][] | "  \(.tok) tok  \(.name)\(if .full then "(full)" else "" end)  \(.arg)")' 2>/dev/null)
calls=$(printf '%s\n' "$tools" | sed -n 's/^calls=//p')
heavy=$(printf '%s\n' "$tools" | grep -v '^calls=')

# Known offenders in this repo -> the fix that replaces them.
hints=""
case "$heavy" in *pubspec.lock*|*.pbxproj*|*/build/*|*Pods/*|*.dart_tool*|*.xib*) hints="$hints generated-file->deny;" ;; esac
case "$heavy" in *INSTRUCTIONS.md*) hints="$hints INSTRUCTIONS.md-is-stale->AGENTS.md;" ;; esac
case "$heavy" in *CHANGELOG.md*|*API_CLARIFICATION.md*|*README.md*) hints="$hints big-doc->rg -n/offset;" ;; esac
printf '%s\n' "$heavy" | grep -E 'tok  Bash  ' | grep -E 'flutter test' | grep -qvE 'failures-only|-r ' \
  && hints="$hints raw-test->flutter test -r failures-only <file>;"
printf '%s\n' "$heavy" | grep -E 'tok  Bash  ' | grep -v 'typecheck.sh' | grep -qE 'swiftc|xcodebuild|gradle' \
  && hints="$hints native-build->darwin/android-typecheck;"
printf '%s\n' "$heavy" | grep -qE '^  [0-9]{4,} tok  Read\(full\)  (darwin|android|lib)/' \
  && hints="$hints big-read->offset/limit;"
[ "$(printf '%s\n' "$heavy" | grep -cE 'tok  (Read|Grep|Glob)[^ ]*  (darwin|android)/')" -ge 3 ] \
  && hints="$hints exploring->AGENTS.md component table + rg -n;"

{
  echo "=== $(date '+%Y-%m-%d %H:%M') | session ${sid:0:8} ==="
  echo "Task: in=$t_in out=$t_out cache_write=$t_cw cache_read=$t_cr | jami=$total | narx-ekv=$eff | tool calls=${calls:-0}"
  echo "Kontekst: $ctx tok"
  [ -n "$heavy" ] && { echo "Eng og'ir tool natijalari:"; echo "$heavy"; }
  [ -n "$hints" ] && echo "Hint:$hints"
  echo
} >> "$dir/report.log"

# Keep the log bounded.
if [ "$(wc -l < "$dir/report.log")" -gt 3000 ]; then
  tail -n 2000 "$dir/report.log" > "$dir/report.log.tmp" && mv "$dir/report.log.tmp" "$dir/report.log"
fi

msg="Token: task ~${eff} narx-ekv (out ${t_out}, ${calls:-0} tool), kontekst ${ctx}.${hints:+ Hint:$hints} Tahlil: /token-review"
jq -n --arg m "$msg" '{systemMessage: $m}'
exit 0
