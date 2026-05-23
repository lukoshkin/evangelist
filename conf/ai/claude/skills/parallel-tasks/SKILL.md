---
name: parallel-tasks
description: Use when dispatching 2+ tasks (issues, plan items, fixes) for parallel execution across subagents or separate Claude Code sessions, especially when tasks MAY touch overlapping files. Invocation `/parallel-tasks <task1> <task2> ...` or free-form "run these N issues in parallel", "fan out fixing #A, #B, #C". Differs from `superpowers:dispatching-parallel-agents` (which is for strictly INDEPENDENT tasks).
---

# Parallel Tasks with Cooperative Locking

## Overview

When several tasks (issues to fix, plan items, refactors) could run in
parallel but might touch overlapping files, the gold-standard guarantee is
**no surprise merge conflicts, predictable commit order**. This skill achieves
that with three pieces:

1. **Pre-scoping** — every task declares its planned file footprint upfront.
2. **Cooperative lock file** — agents register file claims, extensions, and
   completions in a shared structured log; they wait when another task holds
   a file they need.
3. **Monitor agent** — watches the lock and posts advisories to any task
   whose planned scope is affected by another task's runtime extension.

All tasks dispatch in parallel; the protocol resolves both planned and
runtime overlaps. Sibling skill for strictly independent work:
`superpowers:dispatching-parallel-agents`.

## When to Use

- `/parallel-tasks <task1> <task2> [task3...]` — canonical invocation.
- "Fan out these N issues / fix #A, #B, #C in parallel."
- "Tackle issue #N while implementing plan X."
- ≥2 tasks; you want parallelism but can't guarantee zero file overlap.

**Don't use when:** tasks are truly independent (use
`superpowers:dispatching-parallel-agents` — lighter), or only one task
(no coordination needed).

## Phases

### 0. Inputs

- N task descriptions (issue numbers, plan steps, free-form).
- Priority order — explicit from user, or defaulted (issue number asc, or
  order given). Lower number = higher priority on ties.

### 1. Pre-scope (parallel)

Dispatch one short scoping subagent per task. Each returns: `{task_id,
estimated_files: [paths], rationale: <1-line>}`. Use the existing
`feature-dev:code-explorer` agent type if available; otherwise general-purpose
with a tight prompt:

```
Read issue/task: <description>
Estimate which files this work will touch. Return JSON:
  {"estimated_files": ["src/a.py", "tests/test_a.py"], "rationale": "..."}
Do NOT modify anything. ≤200 words.
```

### 2. Conflict matrix + plan

Compute pairwise intersections of estimated footprints. Build a plan:

```
Task 1 (priority=1): [src/a.py, src/b.py]            — no planned conflict
Task 2 (priority=2): [src/c.py, src/shared.py]       — planned conflict with 3
Task 3 (priority=3): [src/d.py, src/shared.py]       — planned conflict with 2
```

All N tasks still dispatch in parallel. Lock file resolves overlaps at
runtime; priority decides who wins ties.

### 3. Initialize the lock file

Project-local at `.claude/parallel-tasks.lock` (gitignored). Format:
append-only, single line per event, `KEY=value` fields, greppable.

Header (write once at init):

```
# parallel-tasks v1 — started <ISO-ts>
# task=1 priority=1 planned=src/a.py,src/b.py title="<short>"
# task=2 priority=2 planned=src/c.py,src/shared.py title="<short>"
# task=3 priority=3 planned=src/d.py,src/shared.py title="<short>"
```

Event lines (append by agents):

```
TS=2026-05-23T14:33:21Z TASK=1 EVENT=claim FILE=src/a.py
TS=2026-05-23T14:33:45Z TASK=2 EVENT=extend FILE=src/util.py NOTE="needed for X"
TS=2026-05-23T14:34:10Z TASK=2 EVENT=finish FILE=src/util.py
TS=2026-05-23T14:35:00Z TASK=monitor EVENT=advisory FOR_TASK=3 FILE=src/util.py NOTE="task=2 modified; re-read before edit"
TS=2026-05-23T14:40:00Z TASK=1 EVENT=complete
```

Events: `claim` · `extend` · `finish` · `complete` · `advisory` · `wait` ·
`resume`. Keep field order stable so grep patterns are simple.

Add `.claude/parallel-tasks.lock` to `.gitignore` if not already.

### 4. Dispatch (all in parallel)

Spawn the monitor first (background), then all N task agents in parallel.
Each task agent gets the boilerplate below baked into its prompt.

### 5. Integrate

Wait for all `EVENT=complete` lines (one per task). Stage commits in
declared priority order; run tests; ship.

## Task agent prompt boilerplate

Every task agent dispatched under this skill MUST be given this protocol
verbatim. Replace `<N>` and the scope list with the task's own values.

````
You are Task <N> in a parallel-tasks dispatch.

Goal: <task description>
Planned scope: <file list>
Priority: <K> (lower wins ties)
Lock file: .claude/parallel-tasks.lock

PROTOCOL — mandatory:

(a) Before reading or modifying any file `<f>`, check the lock:

    last=$(grep -E " FILE=<f>$" .claude/parallel-tasks.lock | tail -1)

    If $last is an EVENT=claim or EVENT=extend by another task (not yours)
    with no matching EVENT=finish after it, you MUST wait:

      timeout 600 tail -f .claude/parallel-tasks.lock 2>/dev/null \
        | grep -m 1 -E "TASK=<other> EVENT=finish FILE=<f>"

    Then re-check (another task may have claimed it during your wait).

(b) When you start work on a file in your planned scope, append:

    echo "TS=$(date -u +%Y-%m-%dT%H:%M:%SZ) TASK=<N> EVENT=claim FILE=<f>" \
      >> .claude/parallel-tasks.lock

(c) When you discover a needed file BEYOND your planned scope, append:

    echo "TS=$(date -u +%Y-%m-%dT%H:%M:%SZ) TASK=<N> EVENT=extend FILE=<f> NOTE=\"<why>\"" \
      >> .claude/parallel-tasks.lock

(d) When done with any file (saves written), append:

    echo "TS=$(date -u +%Y-%m-%dT%H:%M:%SZ) TASK=<N> EVENT=finish FILE=<f>" \
      >> .claude/parallel-tasks.lock

(e) Subscribe to monitor advisories addressed to you. Periodically run:

    grep -E "EVENT=advisory FOR_TASK=<N>" .claude/parallel-tasks.lock | tail -5

    Any line you haven't seen before: read the NOTE, re-read the cited file,
    adapt your plan (your in-memory view is stale).

(f) When fully done, append:

    echo "TS=$(date -u +%Y-%m-%dT%H:%M:%SZ) TASK=<N> EVENT=complete" \
      >> .claude/parallel-tasks.lock

Do NOT commit. The orchestrator stages commits in priority order after all
tasks complete.
````

## Monitor agent prompt

Dispatched once at init, runs for the lifetime of the batch:

````
You are the monitor for a parallel-tasks dispatch.

Lock file: .claude/parallel-tasks.lock
Planned scopes:
  Task 1: <files>
  Task 2: <files>
  ...

Stream the lock with:

    tail -f .claude/parallel-tasks.lock 2>/dev/null \
      | grep --line-buffered -E "EVENT=(claim|extend|complete)"

On every new claim/extend by task=<N> on file <f>:
- For each OTHER task K whose planned scope contains <f>, append:

    echo "TS=$(date -u +%Y-%m-%dT%H:%M:%SZ) TASK=monitor EVENT=advisory FOR_TASK=<K> FILE=<f> NOTE=\"task=<N> modifying <f>; re-read before your edit\"" \
      >> .claude/parallel-tasks.lock

Exit when one `EVENT=complete` line per task has appeared.
````

## Greppable patterns (cheat sheet)

| Query | Command |
|---|---|
| All events for task N | `grep "TASK=<N>" lock` |
| All events touching file f | `grep "FILE=<f>" lock` |
| Currently-claimed files (active) | `grep -E "EVENT=(claim\|extend)" lock` minus matching `finish` |
| Latest event on file f | `grep "FILE=<f>" lock \| tail -1` |
| Advisories for task K | `grep "FOR_TASK=<K>" lock` |
| Has task N completed? | `grep -q "TASK=<N> EVENT=complete" lock` |

## Failure modes

| Failure | Detection | Recovery |
|---|---|---|
| Agent never logs `complete` | Orchestrator timeout (default: longest scoping × 5) | Kill subagent; mark task failed; rerun with smaller scope |
| Agent stuck in `wait` | `timeout 600` on the `tail -f \| grep` | Re-check lock; if blocker truly hung, escalate |
| Agent skips the protocol | Post-mortem `git diff` shows files not in any `claim` | Treat that agent's output as suspect; rerun with explicit protocol restatement |
| Two agents extend to same file at the same instant | First `extend` line wins; second sees the first's claim on its next check and waits | Inherent in the protocol |
| Deadlock (A waits for B, B waits for A) | Timeout fires on both | Abort by priority — lower-priority task killed |

## Common Mistakes

| Mistake | Fix |
|---|---|
| Dispatching without pre-scoping | Lock file becomes the only conflict mechanism; advisories can't fire (monitor doesn't know planned scopes). Always pre-scope. |
| Subagents skip the protocol | Bake the boilerplate into every dispatched prompt verbatim. Don't paraphrase. |
| No `timeout` on `tail -f \| grep` waits | Hung agent → indefinite wait. Always wrap with `timeout 600` (or similar). |
| Committing inside task agents | Stage commits centrally in priority order after all complete. Inside-agent commits race. |
| Forgetting to gitignore the lock | Each run writes to it; you don't want this in history. Add to `.gitignore`. |
| Free-form lock entries (no `KEY=value`) | Breaks grep patterns. Stick to the format. |
| Monitor doesn't exit | Set `EVENT=complete` count == task count as the exit condition. |
| Treating overlaps as a failure | Overlaps are expected; the protocol exists to handle them gracefully. |
