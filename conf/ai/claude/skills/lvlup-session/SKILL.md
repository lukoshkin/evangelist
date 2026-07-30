---
name: lvlup-session
argument-hint: "[bootstrap | session [skill-name] | status]"
description: AI-assisted career skill gap learning sessions driven by EPAM LevelUp career plan data. Bootstrap a career plan from LevelUp, then run structured learning sessions against skill gaps. Invoke as `/lvlup-session bootstrap` or `/lvlup-session session [skill-name]`.
---

# LevelUp Learning Session Skill

## How to invoke

```
/lvlup-session bootstrap             — scrape LevelUp plan, create project files
/lvlup-session session               — run next learning session (auto-picks skill)
/lvlup-session session <skill-name>  — run session for a specific skill (fuzzy match)
/lvlup-session status                — print gap summary and progress
```

---

## Project Discovery

Before any command, resolve the active project directory. Do this silently unless fallback is needed.

1. If `config.json` exists in the current working directory → use it as the project root.
2. Otherwise scan `~/.claude/lvlup_projects/` for `.json` files:
   - **One file** → read its `dir` field; use that as project root; inform user: "Using project: `<plan_title>` at `<dir>`"
   - **Multiple files** → list plan titles and ask the user to choose one
   - **Zero files** → tell user no project is bootstrapped; prompt them to run `/lvlup-session bootstrap`
3. If `--dir <path>` appears in the invocation → use that path directly, skipping 1 and 2.

After resolving the project root, set it as `PROJECT_DIR` for all subsequent steps.

---

## COMMAND: `bootstrap`

### 1 — Collect the plan URL

Ask: "Please paste your LevelUp career plan URL."

Validate it matches: `https://levelup.epam.com/careerPlan/externalUserId=<digits>&planId=<uuid>`

Extract `externalUserId` and `planId` from the URL. If validation fails, explain the expected format and ask again.

### 2 — Resolve target directory

Ask: "Where should I create the project? [default: `./<plan_title_snake_case>/` in current dir, or type a path]"

- Default (blank): create `<sanitized_title>/` in cwd. `sanitized_title` = plan title with spaces and non-alphanumeric characters replaced by underscores, consecutive underscores collapsed.
- User provides path: use it verbatim.

Then check for conflicts (directory and registry must stay in sync):

| Registry entry exists? | Directory exists? | Action |
|---|---|---|
| No | No | Proceed — create both |
| Yes | Yes | Ask: "Project `<plan_title>` already exists at `<dir>`. (O)verwrite all files, (C)ontinue from existing data, or (A)bort?" |
| No | Yes | Proceed — add registry entry after bootstrap |
| Yes | No | Warn: "Registry points to `<dir>` but it is missing. Recreating." Proceed. |

For "Continue": skip writing `entry_state.json` (preserve immutable snapshot); re-scrape and update `gap_skills_raw.json` and `current_state.json` (additive — preserve existing `sessionNotes` and `progressStatus`).

### 3 — Open browser and log in

Navigate to the plan URL using Playwright (`browser_navigate`).

Tell the user: "Please log in to EPAM LevelUp in the browser window. Press Enter here once you see your career plan."

Wait for the user to confirm, then verify the page URL contains `/careerPlan/` to confirm successful login.

### 4 — Write `scripts/bootstrap_query.js` from embedded template

Check if `<PROJECT_DIR>/scripts/bootstrap_query.js` exists. If not:
- Create `<PROJECT_DIR>/scripts/` directory
- Write the file using the canonical template embedded at the bottom of this skill file (section: **Embedded: bootstrap_query.js**)

### 5 — Execute the scrape

Read `<PROJECT_DIR>/scripts/bootstrap_query.js`.

Execute via Playwright `browser_evaluate`:
```
`${scriptContent}; return bootstrapLevelUp(${JSON.stringify({ externalUserId, planId })})`
```

### 6 — Detect and handle discrepancies

Inspect the returned array. Flag discrepancies if:
- Any expected top-level field (`group`, `name`, `skillId`, `currentLevel`, `targetLevel`, `targetLevelProficiency`, `skillDescription`) is missing from any entry
- The array is empty
- Any entry has `targetLevel` that is a raw ID rather than a name

If discrepancies found:
1. Describe the issue clearly to the user
2. Propose a patch to `scripts/bootstrap_query.js`
3. Ask confirmation before applying ("Apply this patch? Y/n")
4. Re-run the scrape after patching
5. Note: "Consider propagating this fix to the skill template (section: Embedded: bootstrap_query.js)"

Skills with empty `targetLevelProficiency` are normal — they are handled at session time via `who_defines_missing_proficiency`.

### 7 — Write data files

**`data/gap_skills_raw.json`** — always write (raw API output).

**`data/entry_state.json`** — write only if it does not already exist. Shape:
```json
[{
  "group": "...", "name": "...", "skillId": "...",
  "skillDescription": "...", "currentLevel": "<name or null>",
  "targetLevel": "...", "currentLevelProficiency": "...", "targetLevelProficiency": "..."
}]
```

**`data/current_state.json`** — write fresh on first bootstrap. On re-bootstrap, merge: preserve `sessionNotes` and `progressStatus` for each skill by `skillId`; update all other fields from the new scrape. Shape per entry:
```json
{
  "group": "...", "name": "...", "skillId": "...",
  "skillDescription": "...", "currentLevel": "<name or null>",
  "targetLevel": "...", "currentLevelProficiency": "...", "targetLevelProficiency": "...",
  "progressStatus": "not_started",
  "sessionNotes": []
}
```

### 7b — Scaffold the learning-corpus notes corpus

Call the `learning-corpus` skill's operations directly (same project root as
`PROJECT_DIR`):

1. `init <PROJECT_DIR> --title "<plan_title>" --source "LevelUp plan: <levelup_url>"`
2. For each gap skill, in `priority.skill_order` order: `add-topic
   <PROJECT_DIR> <slug> "<skill name>" --body "<skillDescription>"`, where
   `<slug>` is the skill name lowercased, non-alphanumeric runs replaced with
   `-`, trimmed of leading/trailing `-`.

This is additive and idempotent (per `learning-corpus`'s own `add-topic`
idempotency rule) — safe to call on every bootstrap, including re-bootstrap;
already-registered topics are left untouched.

### 8 — Write `config.json`

Write `<PROJECT_DIR>/config.json`. Fetch the plan title from the page title or from the plan page heading (the `h1`/`h2` with "Career plan" and the title name). Use the `userId` value returned internally by the script (extract it from the response or make a separate preflight call: `query { user(payload: { externalId: "<id>" }) { id } }`).

```json
{
  "project": {
    "dir": "<absolute PROJECT_DIR>",
    "levelup_url": "<url>",
    "external_user_id": "<externalUserId>",
    "user_id": <userId>,
    "plan_id": "<planId>",
    "plan_title": "<plan title as shown on page>",
    "sanitized_title": "<snake_case title>"
  },
  "session": {
    "mode": "conceptual",
    "auto_update_state": true
  },
  "gaps": {
    "who_defines_missing_proficiency": "claude",
    "acknowledge_claude_defined": true
  },
  "priority": {
    "focus_groups": [],
    "skill_order": "as_listed",
    "custom_order": []
  }
}
```

### 9 — Write registry entry

Write `~/.claude/lvlup_projects/<sanitized_title>.json`:
```json
{
  "dir": "<absolute PROJECT_DIR>",
  "plan_title": "<plan title>",
  "sanitized_title": "<sanitized_title>",
  "bootstrapped_at": "<YYYY-MM-DD>"
}
```

### 10 — Report gap summary

Print a grouped summary:
```
Bootstrap complete — <N> gap skills across <G> groups:

Data Understanding and Preparation (1):
  - Out-of-Core and Distributed Data Processing  [Intermediate → Advanced]

Model Development (7):
  - Classification Metrics for Machine Learning  [Intermediate → Expert]
  ...
```

---

## COMMAND: `session [skill-name?]`

### 1 — Resolve project

Run Project Discovery (see above). Read:
- `config.json` → all config values
- `session_procedure.md` → step config (YAML front-matter) and prose instructions
- `data/current_state.json` → all gap skills and their progress

### 2 — Select target skill

**If a skill name was given** (fuzzy, case-insensitive):
- Find the closest match in `current_state.json` by name
- If ambiguous (multiple close matches), list them and ask user to choose

**If no skill name was given**, apply `priority.skill_order` with `focus_groups` filter:
- Filter: if `focus_groups` is non-empty, exclude skills not in those groups
- `as_listed`: pick the first skill where `progressStatus` ∈ `{in_progress, needs_review, not_started}`, in that priority order
- `by_gap_size`: compute `gap = targetOrdinal - currentOrdinal` (Novice=1, Intermediate=2, Advanced=3, Expert=4; null currentLevel → ordinal 0). Sort descending; pick first with `progressStatus` ≠ `completed`
- `custom`: iterate `priority.custom_order` by skill name; pick first with `progressStatus` ≠ `completed`

If no eligible skill found, tell the user all skills are completed (or all in the focus group are done).

Mark the selected skill as `in_progress` in `current_state.json` before starting.

Announce: "Starting session: **`<skill name>`** (`<currentLevel>` → `<targetLevel>`)"

### 3 — Handle missing target proficiency

If `targetLevelProficiency` is empty for the selected skill:

- `who_defines_missing_proficiency = "claude"`:
  Generate proficiency criteria from the skill description and your knowledge of what Expert (or target) level means for this domain. Structure it as a bulleted list matching the style of other skills' proficiency entries. Persist the generated text to `current_state.json` immediately. If `acknowledge_claude_defined = true`, show the user:
  > "Note: target-level criteria for **`<skill>`** weren't defined in LevelUp — I've inferred them from the skill description. Let me know if you'd like to adjust these before we start."

- `who_defines_missing_proficiency = "operator"`:
  Show the skill description. Ask:
  > "Please define the target-level proficiency criteria for **`<skill>`** as a bulleted list. These will be used for this and all future sessions on this skill."
  Persist the user-provided text to `current_state.json`.

### 4 — Run session procedure steps

Execute each step in `session_procedure.md` in order, following the prose instructions for that step. Respect the YAML front-matter config: `enabled` flags control whether a step runs; `question_count` controls how many questions to ask.

`practice_task.enabled` is overridden to `true` if `config.session.mode` ∈ `{hands_on, mixed}`.

`session_summary.auto_update_state`: `null` inherits from `config.session.auto_update_state`; explicit `true`/`false` overrides it.

### 5 — Write session note and update state

After the session summary step completes, write the session note to `current_state.json` for the skill:

```json
{
  "date": "YYYY-MM-DD",
  "coveredConcepts": ["concept 1", "concept 2"],
  "understoodWell": ["concept 1"],
  "needsRevisit": ["concept 2"],
  "practiceTaskDone": null
}
```

Determine `progressStatus` using these rules (non-linear — any transition valid):

| Condition | progressStatus |
|---|---|
| Session cut short before summary | `in_progress` |
| Summary written, `needsRevisit` non-empty | `needs_review` |
| Summary written, `needsRevisit` empty | `completed` |
| New session on `completed` skill, new gaps found | `needs_review` |

If `auto_update_state` resolves to `true`: write updated `current_state.json`.
If `auto_update_state` resolves to `false`: display the session note in full and tell the user it was not persisted.

### 5b — Update the learning-corpus notes corpus

Regardless of the `auto_update_state` outcome in step 5, always update the
human-readable corpus (it is a parallel, independent artifact from
`current_state.json`):

1. Render the skill's full `sessionNotes` history (every entry, not just the
   one just written) plus its `currentLevelProficiency` /
   `targetLevelProficiency` into markdown, e.g.:
   ```
   **Current level proficiency:**
   <currentLevelProficiency bullets>

   **Target level proficiency:**
   <targetLevelProficiency bullets>

   ## Session: <date>
   **Covered:** <coveredConcepts, comma-joined>
   **Understood well:** <understoodWell, comma-joined>
   **Needs revisit:** <needsRevisit, comma-joined, or "none">
   ```
   (repeat the `## Session: <date>` block per entry in `sessionNotes`, oldest
   first)
2. Map `progressStatus` to `learning-corpus`'s vocabulary: `not_started` →
   `pending`, `in_progress` → `in_progress`, `needs_review` → `needs_review`,
   `completed` → `done`.
3. Call `update-topic <PROJECT_DIR> <slug> "<rendered markdown>" --status
   <mapped status>`, then `render <PROJECT_DIR>`.

### 6 — Suggest next skill

After writing state, suggest what to work on next:
- If `needsRevisit` is non-empty: "Next session: revisit **`<skill>`** — focus on: `<needsRevisit items>`"
- Otherwise: announce the next eligible skill per `priority.skill_order`

---

## COMMAND: `status`

Read `data/current_state.json`. Print a progress table grouped by group:

```
Lead Data Scientist — Gap Progress (as of YYYY-MM-DD)

Group                              Skill                                      Status        Level Gap
─────────────────────────────────────────────────────────────────────────────────────────────────────
Data Understanding and Prep        Out-of-Core and Distributed Data Proc...   not_started   Int → Adv
Model Development                  Classification Metrics for ML              not_started   Int → Exp
...

Summary: 0 completed / 29 total  |  0 in_progress  |  0 needs_review  |  29 not_started
```

---

## Embedded: bootstrap_query.js

The canonical source for `scripts/bootstrap_query.js`. Write this to `<PROJECT_DIR>/scripts/bootstrap_query.js` on first bootstrap if the file does not exist. When you patch a project's copy due to API drift, note to the user that this embedded template should also be updated.

```javascript
/**
 * bootstrapLevelUp — Playwright page.evaluate() payload for EPAM LevelUp career plan scraping.
 *
 * Must be executed inside an authenticated LevelUp plan page (URL contains /careerPlan/).
 * Session cookies are carried automatically via relative fetch.
 *
 * Usage from skill:
 *   const src = readFileContents('scripts/bootstrap_query.js');
 *   const result = await browser_evaluate(
 *     `${src}; return bootstrapLevelUp(${JSON.stringify({ externalUserId, planId })});`
 *   );
 *
 * Returns array of gap skill objects matching current_state.json shape
 * (minus progressStatus and sessionNotes).
 */
async function bootstrapLevelUp({ externalUserId, planId }) {
  const LEVEL_NAME = {
    '7770000000000001001': 'Novice',
    '7770000000000001002': 'Intermediate',
    '7770000000000001003': 'Advanced',
    '7770000000000001004': 'Expert',
    '7770000000000001014': 'B2+',
  };

  const gql = (body) =>
    fetch('/api/query', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(body),
    }).then((r) => r.json());

  // Preflight: resolve internal numeric userId
  const userRes = await gql({
    operationName: 'GetUserId',
    variables: { payload: { externalId: externalUserId } },
    query: 'query GetUserId($payload: InputUserPayload) { user(payload: $payload) { id } }',
  });
  const userId = userRes?.data?.user?.id;
  if (!userId) throw new Error('Could not resolve userId for externalUserId=' + externalUserId);

  // Scrape skill links from DOM
  const links = document.querySelectorAll('a[href*="/skill/skillId="]');
  const allSkills = [];
  links.forEach((link) => {
    const href = link.getAttribute('href');
    const skillIdMatch = href.match(/skillId=(\d+)/);
    const skillLevelIdMatch = href.match(/skillLevelId=(\d+)/);
    if (!skillIdMatch || !skillLevelIdMatch) return;
    const skillId = skillIdMatch[1];
    const targetLevelId = skillLevelIdMatch[1];
    const developed = link.innerText.includes('Developed skill');
    const name = link.innerText.split('\n').map((l) => l.trim()).find((l) => l.length > 0) || '';
    let group = '';
    let el = link.parentElement;
    while (el && el !== document.body) {
      const prev = el.previousElementSibling;
      if (prev) {
        const txt = prev.innerText?.trim();
        if (txt && txt.length < 120 && !txt.includes('Set due') && !txt.includes('Developed')) {
          group = txt;
          break;
        }
      }
      el = el.parentElement;
    }
    allSkills.push({ name, skillId, targetLevelId, targetLevel: LEVEL_NAME[targetLevelId] || targetLevelId, group, developed });
  });

  const gapSkills = allSkills.filter((s) => !s.developed);
  if (gapSkills.length === 0) throw new Error('No gap skills found. Is this the correct plan page?');

  const CURRENT_LEVEL_Q =
    'query Q($p: InputUserSkillPayload) { userSkill(payload: $p) { userSkillLevel { id name seniorityLevel } skill { description } } }';
  const PROFICIENCY_Q =
    'query Q($p: InputSkillProgressPayload) { skillProgress(payload: $p) { skillDetails { proficiency skillLevel { name } } } }';

  const currentResults = await Promise.all(
    gapSkills.map((s) =>
      gql({
        operationName: 'Q',
        variables: { p: { paramsModel: { skillId: s.skillId, externalUserId, planId, isIncludeChildAndRelated: false } } },
        query: CURRENT_LEVEL_Q,
      })
    )
  );

  // Gap skills can span more than one level (e.g. Intermediate → Expert skips
  // Advanced; null → Expert skips Novice, Intermediate, AND Advanced). Fetching
  // only the two endpoints silently drops whatever proficiency criteria the
  // skipped levels define, so walk the full ordinal path instead.
  const LEVEL_PATH = [
    '7770000000000001001', // Novice
    '7770000000000001002', // Intermediate
    '7770000000000001003', // Advanced
    '7770000000000001004', // Expert
  ];

  const currentLevelIds = currentResults.map((r) => r?.data?.userSkill?.userSkillLevel?.id ?? null);

  const levelsToFetch = gapSkills.map((s, i) => {
    const curId = currentLevelIds[i];
    const targetIdx = LEVEL_PATH.indexOf(s.targetLevelId);
    if (targetIdx === -1) return [s.targetLevelId]; // unknown level scheme — fall back to target only
    const curIdx = curId ? LEVEL_PATH.indexOf(curId) : -1;
    const ids = LEVEL_PATH.slice(curIdx + 1, targetIdx + 1);
    return ids.length > 0 ? ids : [s.targetLevelId];
  });

  const pathProfResults = await Promise.all(
    gapSkills.map((s, i) =>
      Promise.all(
        levelsToFetch[i].map((levelId) =>
          gql({
            operationName: 'Q',
            variables: { p: { skillId: s.skillId, skillLevelId: levelId, userId, loadUpdatedContent: false } },
            query: PROFICIENCY_Q,
          })
        )
      )
    )
  );

  const currentProfResults = await Promise.all(
    gapSkills.map((s, i) => {
      const curId = currentLevelIds[i];
      if (curId && curId !== s.targetLevelId) {
        return gql({
          operationName: 'Q',
          variables: { p: { skillId: s.skillId, skillLevelId: curId, userId, loadUpdatedContent: false } },
          query: PROFICIENCY_Q,
        });
      }
      return Promise.resolve(null);
    })
  );

  const stripHtml = (html) => {
    if (!html) return '';
    return html
      .replace(/<li>/g, '\n- ')
      .replace(/<p>/g, '\n')
      .replace(/<[^>]+>/g, '')
      .replace(/&lt;/g, '<')
      .replace(/&gt;/g, '>')
      .replace(/&amp;/g, '&')
      .replace(/&nbsp;/g, ' ')
      .replace(/\n{3,}/g, '\n\n')
      .trim();
  };

  return gapSkills.map((s, i) => {
    const cur = currentResults[i]?.data?.userSkill;
    const currentProf = currentProfResults[i]?.data?.skillProgress?.skillDetails;

    // Concatenate every skipped level's proficiency bullets, labeled by level,
    // so concept coverage during a session doesn't silently skip them.
    const pathIds = levelsToFetch[i];
    const pathResults = pathProfResults[i];
    const targetLevelProficiency = pathIds
      .map((levelId, j) => {
        const details = pathResults[j]?.data?.skillProgress?.skillDetails;
        const bullets = stripHtml(details?.proficiency ?? '');
        return bullets ? `[${LEVEL_NAME[levelId] || levelId}]\n${bullets}` : '';
      })
      .filter(Boolean)
      .join('\n\n');

    const lastLevelDetails = pathResults[pathResults.length - 1]?.data?.skillProgress?.skillDetails;

    return {
      group: s.group,
      name: s.name,
      skillId: s.skillId,
      skillDescription: stripHtml(cur?.skill?.description ?? ''),
      currentLevel: cur?.userSkillLevel?.name ?? null,
      currentLevelId: cur?.userSkillLevel?.id ?? null,
      targetLevel: lastLevelDetails?.skillLevel?.name ?? LEVEL_NAME[s.targetLevelId] ?? s.targetLevelId,
      targetLevelId: s.targetLevelId,
      currentLevelProficiency: stripHtml(currentProf?.proficiency ?? ''),
      targetLevelProficiency,
    };
  });
}
```
