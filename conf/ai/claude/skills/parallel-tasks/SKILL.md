---
name: parallel-tasks
description: Use when dispatching 2+ tasks (issues, plan items, fixes) for parallel execution across subagents or separate Claude Code sessions, especially when tasks MAY touch overlapping files. Invocation `/parallel-tasks <task1> <task2> ...` or free-form "run these N issues in parallel", "fan out fixing #A, #B, #C". Differs from `superpowers:dispatching-parallel-agents` (which is for strictly INDEPENDENT tasks).
---

# Parallel Tasks with Cooperative Locking

## Overview

When several tasks (issues to fix, plan items, refactors) could run in
parallel but might touch overlapping files, the gold-standard guarantee is
**no surprise merge conflicts, predictable commit order, no hunk surgery
at commit time**. This skill achieves that with four pieces:

1. **Pre-scoping** — every task declares its planned file footprint upfront.
2. **Shared-file owner assignment** — for each file claimed by ≥2 tasks,
   the controller picks one owner end-to-end and delegates the other
   task's intended changes to that owner, so commit-time hunk surgery is
   avoided.
3. **Per-batch cooperative lock file** — agents register file claims,
   extensions, and completions in a shared structured log scoped to ONE
   batch; they wait when another task holds a file they need.
4. **Monitor agent** — watches the lock and posts advisories to any task
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

### 1. Pre-scope

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

**Skip pre-scoping when** the tasks are filed GitHub issues whose bodies
already contain a populated Key Files table (e.g., issues filed via the
`issue-file` skill). The table IS the pre-scoped footprint — re-scoping
duplicates work. Note this choice in the conflict matrix.

### 2. Conflict matrix + owner assignment

Compute pairwise intersections of estimated footprints. For each shared
file, **assign a single owner** (default: the lowest-priority task that
plans to touch it — it would otherwise wait the longest under pure
locking). The owner inherits a *delegation spec* from every other task
that planned to touch the file:

```
Task 1 (priority=1): [src/a.py, src/b.py]
Task 2 (priority=2): [src/c.py, web/screens/Pinboard.tsx, tests/Pinboard.test.tsx]
Task 3 (priority=3): [src/d.py, web/screens/Pinboard.tsx, tests/Pinboard.test.tsx]

Owner assignment:
  web/screens/Pinboard.tsx  → Task 3 (lower priority of the two claimants)
  tests/Pinboard.test.tsx   → Task 3 (same)

Effective planned scopes:
  Task 1: [src/a.py, src/b.py]                                — no overlap, no delegation
  Task 2: [src/c.py]                                          — Pinboard files removed; delegated to Task 3
  Task 3: [src/d.py, web/screens/Pinboard.tsx, tests/Pinboard.test.tsx]
          + DELEGATIONS RECEIVED from Task 2:
            web/screens/Pinboard.tsx: <one-paragraph spec of Task 2's intended changes>
            tests/Pinboard.test.tsx:  <test additions Task 2 would have written>
```

Owner assignment removes the need for hunk-level commit splitting later.
Task 3 commits Pinboard.tsx as a single coherent change containing both
its own and Task 2's edits; the commit body cites both issues.

All N tasks still dispatch in parallel. The lock + advisory mechanism
remains the safety net for any unanticipated overlap discovered at
runtime (`EVENT=extend`).

### 3. Initialize the per-batch lock file

Each invocation gets its OWN lock so multiple Claude instances and prior
sessions never collide on `TASK=N` numbering or stale `claim` events.

Lock path: `.claude/parallel-tasks/<batch-id>.lock` (gitignored), where
`<batch-id> = $(date -u +%Y%m%dT%H%M%SZ)-$$` (UTC stamp + controller PID).
Set it once at init and pass the full path to every agent + the monitor:

```bash
BATCH_ID="$(date -u +%Y%m%dT%H%M%SZ)-$$"
LOCK=".claude/parallel-tasks/${BATCH_ID}.lock"
mkdir -p "$(dirname "$LOCK")"
```

Append `.claude/parallel-tasks/` to `.gitignore` (directory, not the old
single file).

Format: append-only, single line per event, `KEY=value` fields, greppable.

Header (write once at init):

```
# parallel-tasks v2 — batch=20260524T182959Z-1234 started <ISO-ts>
# task=1 priority=1 owner_of=src/a.py,src/b.py title="<short>"
# task=2 priority=2 owner_of=src/c.py title="<short>" delegates=Pinboard.tsx,Pinboard.test.tsx→task=3
# task=3 priority=3 owner_of=src/d.py,web/screens/Pinboard.tsx,tests/Pinboard.test.tsx title="<short>"
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

### 4. Dispatch (all in parallel)

Spawn the monitor first (background), then all N task agents in parallel.
Each task agent gets the boilerplate below baked into its prompt, with
the lock path, task number, planned scope, AND any delegation specs
inlined.

### 5. Integrate

Wait for all `EVENT=complete` lines (one per task). Then:

1. Run `scripts/summarize-lock.sh "$LOCK"` for per-task and batch elapsed
   (sanity check on agent efficiency; surface in the final report).
2. Run a thin cross-task verification — NOT a full suite re-run. Each
   agent already gated its own scoped tests; the controller only needs
   to catch leaks BETWEEN tasks (e.g., Task 2 changed a constant that
   Task 3's tests asserted by literal). A grep for cross-task touched
   symbols + the smallest test set covering them suffices. Falling back
   to a full suite is acceptable but adds 30s–3min depending on project.
3. Stage commits in declared priority order. With shared-file ownership,
   no hunk surgery is needed; each commit is `git add <task-N-files>`
   + commit citing the issue(s). The owner's commit body cites every
   delegating task's issue as well.

## Task agent prompt boilerplate

Every task agent dispatched under this skill MUST be given this protocol
verbatim. Replace `<N>`, `<LOCK>`, scope list, and delegations block with
the task's own values.

````
You are Task <N> in a parallel-tasks dispatch.

Goal: <task description>
Planned scope (owner): <file list>
Lock file: <LOCK>            ← per-batch path, e.g. .claude/parallel-tasks/20260524T182959Z-1234.lock
Priority: <K> (lower wins ties)

Delegations RECEIVED from other tasks (apply these alongside your own
changes when you own the shared file):
  - <file>: <one-paragraph spec of what task <M> needed; cite their
    issue # so your commit body can reference it>
  - <file>: <…>
(empty if no delegations)

Delegations YOU SENT to other tasks (do NOT touch these files; the named
owner will apply your changes):
  - <file> → owner=task=<M>: <one-paragraph spec you authored>
(empty if no delegations)

PROTOCOL — mandatory:

(a) Before reading or modifying any file `<f>`, check the lock:

    last=$(grep -E " FILE=<f>$" <LOCK> | tail -1)

    If $last is an EVENT=claim or EVENT=extend by another task (not yours)
    with no matching EVENT=finish after it, you MUST wait:

      timeout 600 tail -f <LOCK> 2>/dev/null \
        | grep -m 1 -E "TASK=<other> EVENT=finish FILE=<f>"

    Then re-check (another task may have claimed it during your wait).

(b) When you start work on a file in your planned scope, append:

    echo "TS=$(date -u +%Y-%m-%dT%H:%M:%SZ) TASK=<N> EVENT=claim FILE=<f>" >> <LOCK>

(c) When you discover a needed file BEYOND your planned scope, append:

    echo "TS=$(date -u +%Y-%m-%dT%H:%M:%SZ) TASK=<N> EVENT=extend FILE=<f> NOTE=\"<why>\"" >> <LOCK>

(d) When done with any file (saves written), append:

    echo "TS=$(date -u +%Y-%m-%dT%H:%M:%SZ) TASK=<N> EVENT=finish FILE=<f>" >> <LOCK>

(e) Subscribe to monitor advisories addressed to you. Periodically run:

    grep -E "EVENT=advisory FOR_TASK=<N>" <LOCK> | tail -5

    Any line you haven't seen before: read the NOTE, re-read the cited file,
    adapt your plan (your in-memory view is stale).

(f) When fully done, append:

    echo "TS=$(date -u +%Y-%m-%dT%H:%M:%SZ) TASK=<N> EVENT=complete" >> <LOCK>

Do NOT commit. The orchestrator stages commits in priority order after all
tasks complete.
````

## Monitor agent prompt

Dispatched once at init, runs for the lifetime of the batch:

````
You are the monitor for a parallel-tasks dispatch.

Lock file: <LOCK>
Planned scopes (post owner-assignment):
  Task 1: <files>
  Task 2: <files>
  ...

Stream the lock with:

    tail -n0 -f <LOCK> 2>/dev/null \
      | grep --line-buffered -E "EVENT=(claim|extend|complete)"

On every new claim/extend by task=<N> on file <f>:
- For each OTHER task K whose planned scope contains <f> AND which has
  NOT yet logged EVENT=complete, append:

    echo "TS=$(date -u +%Y-%m-%dT%H:%M:%SZ) TASK=monitor EVENT=advisory FOR_TASK=<K> FILE=<f> NOTE=\"task=<N> modifying <f>; re-read before your edit\"" >> <LOCK>

  (Skip the advisory if task=<K> already has a complete event — retro
  advisories are noise.)

Exit when one `EVENT=complete` line per task has appeared.
````

## Greppable patterns (cheat sheet)

| Query | Command |
|---|---|
| All events for task N | `grep "TASK=<N> " <LOCK>` |
| All events touching file f | `grep "FILE=<f>" <LOCK>` |
| Currently-claimed files (active) | `grep -E "EVENT=(claim\|extend)" <LOCK>` minus matching `finish` |
| Latest event on file f | `grep "FILE=<f>" <LOCK> \| tail -1` |
| Advisories for task K | `grep "FOR_TASK=<K>" <LOCK>` |
| Has task N completed? | `grep -q "TASK=<N> EVENT=complete" <LOCK>` |
| Per-task + batch elapsed | `scripts/summarize-lock.sh <LOCK>` |

## Failure modes

| Failure | Detection | Recovery |
|---|---|---|
| Agent never logs `complete` | Orchestrator timeout (default: longest scoping × 5) | Kill subagent; mark task failed; rerun with smaller scope |
| Agent stuck in `wait` | `timeout 600` on the `tail -f \| grep` | Re-check lock; if blocker truly hung, escalate |
| Agent skips the protocol | Post-mortem `git diff` shows files not in any `claim` | Treat that agent's output as suspect; rerun with explicit protocol restatement |
| Two agents extend to same file at the same instant | First `extend` line wins; second sees the first's claim on its next check and waits | Inherent in the protocol |
| Deadlock (A waits for B, B waits for A) | Timeout fires on both | Abort by priority — lower-priority task killed |
| Two parallel-tasks invocations in the same repo | Each gets its own `<batch-id>` lock | None — by design |
| Pre-scope missed a constant/fixture coupling (e.g. test asserts a literal that another task changed) | Cross-task verification in Phase 5 catches it | Controller fixes the leak directly (one-line) and rolls it into the owning task's commit |

## Common Mistakes

| Mistake | Fix |
|---|---|
| Dispatching without pre-scoping | Lock file becomes the only conflict mechanism; advisories can't fire (monitor doesn't know planned scopes). Always pre-scope (or extract from issue-body Key Files tables). |
| Subagents skip the protocol | Bake the boilerplate into every dispatched prompt verbatim. Don't paraphrase. |
| Sharing a single lock file across batches/instances | Use per-batch path `.claude/parallel-tasks/<batch-id>.lock`. Stale events from a prior crashed run will otherwise look "currently held" to fresh agents. |
| No `timeout` on `tail -f \| grep` waits | Hung agent → indefinite wait. Always wrap with `timeout 600` (or similar). |
| Committing inside task agents | Stage commits centrally in priority order after all complete. Inside-agent commits race. |
| Forgetting to gitignore the lock directory | Each run writes new files; you don't want this in history. `.gitignore`: `.claude/parallel-tasks/`. |
| Free-form lock entries (no `KEY=value`) | Breaks grep patterns. Stick to the format. |
| Monitor doesn't exit | Set `EVENT=complete` count == task count as the exit condition. |
| Treating overlaps as a failure | Overlaps are expected; the protocol exists to handle them gracefully. |
| Hunk-splitting commits because two tasks edited the same file | You forgot owner assignment in Phase 2. Re-do Phase 2 next time — assign a single owner per shared file and pass the loser's spec as a delegation. |
| Re-running the full test suite in Phase 5 | Agents already gated their scoped tests. Verify only cross-task leak surface; full suite is a costly fallback, not the default. |
