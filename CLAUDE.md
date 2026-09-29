# CLAUDE.md - Video Player Plugin

@AGENTS.md

`AGENTS.md` (imported above) is the single source of truth for architecture, contracts,
folder layout and pitfalls — shared with other coding agents. Edit rules there, not here.
This file only adds Claude Code specifics.

- **Package:** `uz.plugin.video_player`
- **Current Version:** `3.6.0`
- **Repository:** `https://github.com/SunnatilloShavkatov/video_player`

## Claude Code specifics

- **Skills:** use `native-feature` for any cross-layer change, `darwin-typecheck` after
  touching `darwin/`, and `release-bump` for version bumps (see `.claude/skills/`).
- **No builds without asking:** don't run `flutter build`, `flutter run`, `pod install`
  or Gradle. `flutter test` and the darwin typecheck script are fine.
- **No commits:** stop after showing the diff; the user commits, tags and pushes.
- **Hooks** (`.claude/settings.json`): `slow-cmd-guard` blocks builds and raw `flutter test`
  (use `-r failures-only`), `plugin-guard` checks file size / Darwin `#if os` / seconds contract
  after each edit, `token-report` logs each turn's cost; `/token-review` analyzes that log.
- **Moving Swift files:** use `git mv` so history follows; the podspec globs pick up new
  paths automatically. Update the folder map in `AGENTS.md` in the same change.
