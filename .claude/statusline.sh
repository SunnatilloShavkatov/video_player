#!/usr/bin/env bash
# statusline.sh — always-visible bottom line: model | context | session cost.
#   Sonnet | ctx 45k (22%) | $0.43        green <50%, yellow >=50%, red >=75% (-> /compact or /clear)
# Runs on every refresh, so it reads only the transcript tail, never the whole file.
command -v jq >/dev/null 2>&1 || { printf 'statusline: brew install jq'; exit 0; }
input=$(cat)
model=$(printf '%s' "$input" | jq -r '.model.display_name // "?"')
model_id=$(printf '%s' "$input" | jq -r '.model.id // ""')
cost=$(printf '%s' "$input" | jq -r '.cost.total_cost_usd // 0')
tp=$(printf '%s' "$input" | jq -r '.transcript_path // ""')

ctx=0
if [ -f "$tp" ]; then
  ctx=$(tail -n 400 "$tp" | jq -rs '[.[] | select(.type=="assistant") | .message.usage // empty] | last
    | if . == null then 0 else ((.input_tokens//0)+(.cache_creation_input_tokens//0)+(.cache_read_input_tokens//0)) end' 2>/dev/null)
fi
ctx=${ctx:-0}

limit=${CLAUDE_CTX_LIMIT:-200000}
case "$model_id" in *1m*|*1M*) limit=1000000 ;; esac
pct=$(( ctx * 100 / limit ))
color='\033[32m'; [ "$pct" -ge 50 ] && color='\033[33m'; [ "$pct" -ge 75 ] && color='\033[31m'
printf "%s | ${color}ctx %sk (%s%%)\033[0m | \$%.2f" "$model" "$((ctx / 1000))" "$pct" "$cost"
