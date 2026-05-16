---
name: changelog
description: Use when generating release notes or changelogs from a git commit range — between tags, specific commits, or N commits back from HEAD. Produces audience-appropriate output for public channels (no technical leaks) and developer releases (with refs and details).
---

# Changelog

Generate changelogs from a git commit range for two distinct audiences.

## Input

The user specifies a commit range in one of three forms:

1. **Tag to tag**: `v1.0.0..v1.1.0`
2. **Commit to HEAD**: `abc1234..HEAD` or `v1.0.0..HEAD`
3. **Last N commits**: `~N` or "last 20 commits"

**Range semantics — `A..B` is half-open: A is excluded, B is included.**
This is standard `git log A..B` behavior (commits reachable from B but not
A), so passing the range verbatim to `git log` is correct. The endpoint
`A` is the *previous* release boundary — its own commit was already
covered by an earlier changelog and must NOT reappear. The endpoint `B`
*is* part of this changelog. Concretely:

- `v1.0.0..v1.1.0` → every commit after the `v1.0.0` tag, up to and
  including the commit tagged `v1.1.0`. The `v1.0.0` commit itself is out.
- `~N` / "last N commits" → resolve as `HEAD~N..HEAD`: the N most recent
  commits, with `HEAD` included and `HEAD~N` excluded.

Never hand-include `A`'s commit or hand-exclude `B`'s — if a tool or
manual listing disagrees with `git log A..B`, the `git log` output wins.

Read full commit messages (`git log --format="--- %h ---%n%B" <range>`), not just oneline.

If the diff is needed for classification (user requests it or commit messages are terse), also read `git diff --stat <range>` to map changes to paths.

## Output Channels

### Channel 1: Telegram (public, Russian by default)

**Audience:** End users who use the product. They have NO access to the source code.

**Iron rules:**
- NO commit hashes, PR numbers, or links
- NO code identifiers: class names, function names, field names, config keys, file paths
- NO technical jargon: FSM, middleware, TTL, MongoDB, Redis, LLM, orchestrator, pipeline, singleton, mutex, ARQ
- NO admin-only features (anything behind admin access)
- NO internal architecture changes (refactors, CI/CD, deployment, monitoring)
- NO invented version numbers — use only what the user provides
- NO hallucinated benefits — never claim speed/performance improvements unless a commit explicitly states measurable improvement. "Parallel dispatch" in architecture does NOT mean "faster responses" for users.
- NO invisible changes — if users don't know something exists (e.g., database storage, background cleanup), changes to it are NOT user-facing. The litmus test: "Would a user notice if this change was reverted?"
- DO describe behavior changes in user terms: "бот теперь делает X" not "добавлен Y middleware"
- DO classify HTML/rendering crashes as bug fixes (symptom: "спецсимволы вызывали ошибку"), NOT security issues. For end users, "XSS" = "the bot crashed when I typed <".

**Sections (in order):**

1. **Заметные изменения в интерфейсе** — visual/interaction changes users will see immediately
2. **Улучшения в работе бота** — behavior improvements users will notice over time (smarter replies, better suggestions, faster responses)
3. **Изменения в настройках по умолчанию** — default value changes that affect existing users (call out the old → new values)
4. **Исправления ошибок** — bugs that users could have encountered (describe the symptom, not the fix)
5. **Важно** — breaking changes that require user action, if any

Omit empty sections. Keep each item to 1-2 sentences max.

**Tone:** informative, concise, friendly but not chatty. No emojis in section headers.

### Channel 2: GitHub Release (developer, English by default)

**Audience:** Developers and contributors with repo access.

**Rules:**
- Include short commit hashes as `[abc1234]` (no full URLs unless user provides a repo base URL)
- Group by impact, not by commit order
- Technical details welcome but stay concise
- Admin tooling, CI/CD, deployment, internal refactors — all belong here

**Sections (in order):**

1. **UI Changes** — user-visible interface changes
2. **Backend Improvements** — behavior, performance, architecture changes visible through the product
3. **Internal** — refactors, CI/CD, deployment, monitoring, docs, admin tooling
4. **Bug Fixes** — with symptom + root cause
5. **Security** — specific details (what was vulnerable, how it was fixed)
6. **Breaking Changes** — API/config/data model changes that require migration
7. **Deprecations** — if any

Omit empty sections.

## Classification Guide

Use this to decide which section an item belongs to:

```
Changed files in src/interfaces/aiogram/  → likely UI
Changed files in src/api/routers/         → likely Backend (check if user-facing)
Changed files in src/features/*/tools.py  → likely Backend
Changed files in deploy/, scripts/, .github/ → Internal
Changed files in docs/                    → Internal (unless user-facing docs)
Commit message has "admin" or "admin_"    → Internal (never Telegram)
Commit message has "Fix"/"fix"            → Bug Fix (check if user-facing for Telegram)
Commit message mentions security/XSS/injection → Security
Commit has only "c" bullets (refactor)    → Internal
Commit has "+" bullets                    → Feature (classify by path/description)
```

When a commit spans multiple categories, split it — one item per section.

## Anti-Patterns

- **Don't invent version numbers.** If user says "changelog for v1.0.0..HEAD", the output has no version label unless they provide one.
- **Don't guess repo URLs.** Write `[abc1234]` not `[abc1234](https://github.com/...)` unless user provides the base URL.
- **Don't include typing indicators, spinners, or loading states as "backend improvements"** — if users see them, they're UI.
- **Don't merge distinct features into one bullet** just because they were in one commit.
- **Don't repeat the same fix in both Bug Fixes and another section.**
- **Don't infer performance gains.** "Parallel dispatch" in code ≠ "faster responses" for users. Only claim speed if a commit explicitly measures it.
- **Don't mention invisible infrastructure.** Database cleanup, TTL indexes, background jobs — if users never knew the old behavior, they won't appreciate the new one. Litmus: "Would a user file a bug if this was reverted?"
- **Don't put HTML/rendering crashes under Security for Telegram.** From the user's perspective, `<` in a task name crashing the bot is a bug, not a security issue. Use Security section only in GitHub for the technical XSS context.

## Verification Against Docs

After generating both changelogs, cross-reference with documentation changes in the same commit range. Skip this step if the user explicitly asks to (e.g., `--no-verify`).

**Procedure:**

1. Run `git diff --stat <range> -- docs/` to list changed `.md` files
2. If no docs changed — skip verification, output changelogs as-is
3. For each changed doc file, read the diff (`git diff <range> -- <file>`) — focus on added/modified lines, not removals
4. Cross-reference against the generated changelogs:
   - **Missing items:** Does the doc describe a feature/change not covered in the changelog? Add it.
   - **Conflicts:** Does a changelog item contradict what the doc says? Fix the changelog — docs are more likely to be accurate on behavior descriptions.
   - **Better wording:** Does the doc explain a feature in clearer user terms than the changelog? Borrow the phrasing (especially useful for the Telegram channel).
5. Output a brief verification summary: how many doc files checked, any items added/corrected

**Important:** This is additive. Docs only help when they were updated in the same range. Missing doc updates don't invalidate the changelog — commits are still the primary source.

## Language Override

Default: Telegram in Russian, GitHub in English.
User can request any language explicitly before or after generation.
