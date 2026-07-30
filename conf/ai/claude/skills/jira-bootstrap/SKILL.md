---
name: jira-bootstrap
argument-hint: "<PROJECT-NNN e.g. PROJ-123> [--delegate] [--light]"
description: >
  Use when starting work on a Jira story — loads the ticket's context
  (summary, description, acceptance criteria, comments, attachments)
  into the conversation and downloads attachments by default.
  --delegate also writes a self-contained context doc for agent handoff.
  Trigger phrases: "bootstrap PROJ-123", "load jira ticket PROJ-123",
  "start work on PROJ-123", "jira-bootstrap PROJ-123".
---

# Jira Bootstrap

Load a Jira story into the conversation so the agent has full context
before starting investigation, implementation, or planning.

Attachments are downloaded by default — pass `--light` to skip.

## Usage

```
/jira-bootstrap <ticket-id>             # fetch + download attachments
/jira-bootstrap <ticket-id> --delegate  # also write a context handoff doc
/jira-bootstrap <ticket-id> --light     # fetch only, skip downloading
```

`--delegate` and `--light` are mutually exclusive — if both are passed, ignore
`--light` and proceed as if only `--delegate` was given (downloading is required
for the handoff doc to have local file links).

## Tool Detection

Before fetching, detect which Jira integration is available and use the best one:

1. **Rovo MCP** — if `mcp__claude_ai_Atlassian_Rovo__` tools are present in the
   session, use them. They provide the richest integration (no env var setup,
   native auth). Use Rovo tools to fetch the issue and its attachments.

2. **jira-cli** — if Rovo is unavailable, check:
   ```bash
   which jira
   ```
   If found, use `jira issue view <ticket-id>` to fetch the story.

3. **jira_issue.py** (fallback) — if neither of the above is available, use the
   bundled script as described in the procedure below.

## Procedure (jira_issue.py fallback)

### Step 1: Fetch the story

Run:
```bash
python3 ~/.claude/scripts/jira_issue.py <ticket-id>
```

**If the script errors on missing env vars** (`JIRA_URL`, `JIRA_EMAIL`, `JIRA_AUTH_TOKEN`):
- For `JIRA_URL` or `JIRA_EMAIL`: ask the user for the values, then invoke `update-config`
  to write them into `conf/ai/claude/settings.json` under `env`.
- For `JIRA_AUTH_TOKEN`: do NOT prompt for the value — guide the user:
  1. Log into Jira in the browser; confirm the avatar email matches `id.atlassian.com`
  2. Go to `https://id.atlassian.com/manage-profile/security/api-tokens`
  3. Click **"Create API token"** (plain — NOT "with scopes"), copy immediately
  4. Add to `~/.claude/settings.local.json`: `{ "env": { "JIRA_AUTH_TOKEN": "<token>" } }`
  5. Start a new Claude Code session so the var is loaded, then retry.

Read the full Markdown output. This gives you: summary, status, type,
priority, assignee, reporter, description (ADF converted to Markdown),
attachment list, and all comments with author and date.

### Step 2: Download attachments (skip if --light)

Run:
```bash
python3 ~/.claude/scripts/jira_issue.py <ticket-id> download
```

Files land in `/tmp/jira/<ticket-id>/`. Read relevant ones (specs, screenshots,
logs) and include their content in your working context.

### Step 3: Write context handoff doc (if --delegate)

Run the fetch again with `--attachment-dir` so the output includes resolved
local file links, then save it to `docs/context/<ticket-id>.md`:

```bash
python3 ~/.claude/scripts/jira_issue.py <ticket-id> \
  --attachment-dir /tmp/jira/<ticket-id>
```

Write the output to `docs/context/<ticket-id>.md`. This file is
self-contained: description, comments, and a `## Local Files` section with
image embeds (`![name](path)`) and file links (`[name](path)`) pointing to
the downloaded attachments. A delegated agent can read this file and work
entirely from it without Jira access.

### Step 4: Surface context to the conversation

Summarize the ticket in 3–5 sentences: what needs to be done, acceptance
criteria extracted from the description or comments, any blockers or open
questions visible in the thread. Make this the working frame for the session.

### Step 5: Create a working branch

Skip this step entirely if the working directory is not a git repo:

```bash
git rev-parse --is-inside-work-tree 2>/dev/null
```

Otherwise, before writing any code:

1. **Check for uncommitted changes.** Run `git status`. If the tree is
   dirty with work unrelated to this ticket, stop and ask the user how to
   proceed (stash, commit, or abandon) rather than switching branches out
   from under it.

2. **Check whether a branch for this ticket already exists** (resuming
   prior work):
   ```bash
   git branch -a | grep -i <ticket-id>
   ```
   If found, check it out and skip to step 5 below instead of creating a
   new one.

3. **Determine the base branch.** Usually `main`/`master`, sometimes a
   `develop` branch. If it's not obvious from the repo or the ticket,
   check the remote's default:
   ```bash
   git remote show origin | sed -n '/HEAD branch/s/.*: //p'
   ```
   If still ambiguous, ask the user rather than guessing — branching from
   the wrong base is expensive to undo later.

4. **Make sure the base branch is up to date** before branching from it:
   ```bash
   git fetch origin <base-branch>
   git checkout <base-branch>
   git pull --ff-only
   ```
   If `--ff-only` fails (local base has diverged), stop and ask the user
   how to reconcile — don't force or rebase on their behalf.

5. **Determine the branch naming convention.** Look for one already in
   use before inventing something new:
   ```bash
   git branch -a --sort=-committerdate | head -20
   ```
   Also check `CONTRIBUTING.md` or the project's `CLAUDE.md` for an
   explicit convention. If a pattern is visible (e.g.
   `feature/<ticket-id>-<slug>`, `<username>/<ticket-id>-<slug>`,
   `<ticket-id>/<slug>`), match it exactly, including case and separators.

   If no convention is discernible, default to:
   ```
   <ticket-id>-<kebab-case-slug-of-summary>
   ```
   e.g. `PROJ-123-fix-login-timeout`. Keep the ticket ID casing as Jira
   reports it; derive the slug from the ticket summary, truncated to a
   few words.

6. **Create the branch from the up-to-date base:**
   ```bash
   git checkout -b <branch-name> <base-branch>
   ```
   If the user wants workspace isolation (or the project conventionally
   uses worktrees), use the `using-git-worktrees` skill instead of a bare
   `checkout -b` — it handles worktree placement and setup.

7. **Confirm before proceeding**: report the branch name and its base to
   the user, e.g. "Created `PROJ-123-fix-login-timeout` from `main`
   (up to date)." so a wrong base is caught immediately rather than
   discovered at merge time.

### Step 6: Proceed

With context loaded, attachments downloaded (unless --light), and a
branch checked out, proceed with the work the ticket describes. If
`--delegate` was passed, hand off `docs/context/<ticket-id>.md` (and the
branch name) to the target agent.
