---
description: Analyze the token report and propose optimizations (changes nothing without approval)
allowed-tools: Bash(tail -n 80 .claude/token-logs/report.log)
---

Run only `tail -n 80 .claude/token-logs/report.log`. Read no other file.

Reply in Uzbek, ≤ 15 lines:
1. Top 3 most expensive tool calls (file/command, ~tokens). `Read(full)` = no offset/limit.
2. A fix for each — in this order, pick the first that fits:
   a. existing tool: `darwin-typecheck` / `android-typecheck` scripts (compile signal instead of builds),
      `flutter test -r failures-only <one test file>`, AGENTS.md component table + `rg -n`
      (finding which file owns a feature instead of reading several)
   b. add the path to `.claude/settings.json` `permissions.deny` + `.ignore` (generated/bulky file)
   c. long file → `offset/limit` rule; noisy command → a pattern in `.claude/hooks/slow-cmd-guard.sh`
      or a capped wrapper script
   d. context > 100k → `/compact`; topic changed → `/clear`
   Never propose new lines in CLAUDE.md/AGENTS.md — they cost tokens every session.
3. A ready diff (settings.json / .ignore / hook / script only).

Change nothing until I approve.
