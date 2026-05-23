Stricter variant of `/ensure_code_quality`: review every quality violation in the changes you introduced this session and fix them, with two extra teeth — the automated Python guard-clause checker runs in rule 8, and rule 6 (no in-function / mid-module imports) applies to `tests/` too, not just source. **Default scope:** only the lines you added — the `+` lines from `git diff` (staged and unstaged), plus the full contents of any untracked files you created. Pre-existing lines stay out of scope.

**Extend mode (opt-in):** if the invocation includes `extend` (or `--full-files`) as an argument, broaden the scope to every line of the touched files (`git diff --name-only` + untracked), including flaws that predate your changes. Use this when the user wants the broader cleanup pass.

Identify in-scope content from git, not from memory — memory drifts after a long session or a context summary. Edits stay confined to in-scope content; reading, though — rule 5 especially — may range across the whole codebase to spot existing abstractions.

These checks are written with Python examples because most of this project is Python, but the underlying principles apply to every language. For touched files in other languages (TypeScript, shell, etc.), translate each rule into its idiomatic analog rather than skipping it — the per-rule notes below point out where the Python syntax most needs translation. The rule for any language-specific tooling (like the guard-clause script at the end) is called out where it applies.

Apply the checks in the order listed below. Blank-line discipline (rule 8) is intentionally the last *fix* step so that any other refactors (which often add or remove statements) settle first — fixing whitespace before the substantive checks just creates churn you'd have to redo. Rule 9 is verification and reporting only.

## 1. No speculative .get() on dicts

Use dict[key] when the key is guaranteed to exist. Reserve .get() for cases where the key genuinely may be absent. Guessing at keys and masking their absence behind a default value introduces silent bugs that are hard to trace.

If you cannot establish from a type hint, a schema/model, or the producing code that the key is guaranteed present, flag it rather than rewriting it — a wrong `[]` swap turns a silent default into a crash.

**Other languages:** the same principle applies to any "safe accessor" that swallows absence — TS `obj?.foo` and `obj.foo ?? default`, Rust `HashMap::get(...).unwrap_or(...)`, Go's two-value map read with `ok` discarded. Use them only when absence is a real, considered case.

## 2. Audit unnecessary `| None` on model fields

When you see a model field typed `X | None` (or `Optional[X]`) with a `None` default — pydantic `Field(default=None)`, dataclass `field: X | None = None`, SQLAlchemy `nullable=True` columns — check whether the field is genuinely nullable or merely marked nullable for construction convenience. LLMs often default fields to nullable to avoid having to think about a value at the call site; this contaminates every consumer with a None-handling branch that never fires.

Verify by:
- Reading all writers (constructors, factory helpers, `update()` calls, migration scripts): if every code path always provides a value, the field is not actually nullable.
- Reading the upstream contract (DB schema, API spec, message contract): if the source guarantees a value, the model is over-permissive.

If verified non-nullable, drop the `| None` and the `= None` default; make the field required. If you cannot establish nullability from a finite scan of writers + schema, flag rather than rewrite — mirrors rule 1's caution.

**Why:** every spurious `| None` forces downstream code into defensive null-checks for a state that cannot occur, and dilutes the meaning of the cases where None genuinely matters.

**Other languages:** TS — `field?: T`, `T | null | undefined`. Rust — `Option<T>` fields. Go — pointer types as nullable markers. Same principle: if it cannot be null at runtime, drop the wrapper.

**Sister rule:** rule 1 catches the same or a closely related anti-pattern at lookup sites. Both reject using a "maybe-absent" construct (`.get()`, `X | None`, `Optional[X]`, defensive defaults) when the surrounding contract — a schema, a model declaration, a function signature, or execution conditions (an upstream check, a control-flow guarantee) — promises the value is there. Defensive optionality contaminates downstream callers with null-checks for impossible states.

## 3. Prefer truthiness over `is None` / `is not None` for non-falsy types

When a variable is `SomeType | None` and `SomeType` cannot be falsy (e.g. `datetime`, `list[T]` that is never empty, custom objects), use `if x:` instead of `if x is not None:` and `if not x:` instead of `if x is None:`. Reserve `is None` / `is not None` for types whose value range includes falsy values (`int | None` where 0 is valid, `str | None` where `""` is valid, `bool | None`).

When you cannot determine the static type, leave the check as-is and flag it.

**Why:** `is not None` is easy to confuse with `is None` at a glance. Plain truthiness (`if x:` / `if not x:`) is shorter and reads more naturally.

**Other languages:** in TS/JS, prefer `if (x)` over `if (x !== null && x !== undefined)` when the non-null type cannot be falsy (objects, arrays, class instances). Keep explicit null/undefined checks for types where `0`, `""`, or `false` are legitimate values. Same logic in any language with a "value or null" type.

## 4. No shallow try-except blocks

A try-except block must meet two criteria:

- Specific exception type. Catching bare Exception is almost never correct outside a top-level handler or middleware. Name the exact exception you expect.
- Meaningful handler. The except branch must _do_ something: set a control variable, run recovery logic, re-raise with context. Swallowing with pass or logging alone rarely justifies the block. If you cannot define a concrete recovery action, let the exception propagate — you can add handling later once you understand the failure mode.

**Other languages:** the rule is universal — `try/catch` in TS/JS, `recover` in Go, `match` on `Result` in Rust, `rescue` in Ruby. Catch the narrowest type the runtime/language allows, and never write an empty handler. In TS, avoid `catch (e: any) {}` and `catch { /* ignore */ }`. In Go, never discard `err` with `_`.

## 5. No duplication; reuse existing abstractions

Check that the code does not duplicate helpers, utilities, or patterns that already exist in the codebase. If an established mechanism (cache layer, error wrapper, formatting helper, etc.) fits the current logic, use it rather than reinventing it.

## 6. No in-function or mid-module imports

All imports belong at the top of the module. Do not place import statements inside functions, methods, or halfway through the file. Deferred imports are almost never a genuine necessity — they usually paper over circular dependencies that signal a deeper architectural problem. If a circular import exists, fix the dependency structure instead of hiding the cycle with a local import.

**Other languages:** TS/JS — no `require()` or dynamic `import()` mid-file unless you are genuinely lazy-loading a heavy module behind a feature flag. Rust — `use` statements at the top of the module. Go enforces this at the language level; do not work around it with `init()` indirection.

**Scope:** Apply this check to every touched file, **including `tests/`**. If a test file places imports mid-function to work around a fixture-construction issue or to isolate a heavy module, fix the fixture (or move the import to module top with a `pytest.importorskip` if the module is optional) rather than keep the deferred import.

## 7. Consistency with established patterns

Follow conventions already present in the project: if surrounding code uses a particular caching strategy, validation style, or control-flow pattern and it fits the new context, adopt the same approach. Do not introduce a one-off alternative without a clear reason.

## 8. Blank-line discipline

Use blank lines to separate logical groups, not individual statements. A guard clause ending in return/raise/continue gets a blank line after it to visually detach it from the main flow. Consecutive statements that belong to the same logical unit (e.g. variable setup followed by the call that uses it) stay together.

When a multiline expression ends with a closing parenthesis/bracket on its own line, do not add a blank line after it — the hanging closer already provides enough visual separation, whether the next line belongs to the same logical unit or a new one.

Ruff (black-style formatter) handles the rest for Python — just avoid trailing commas, which force vertical spreading regardless of line length. For other languages, lean on the project's formatter (Prettier for TS/JS, gofmt, rustfmt) for whitespace beyond the guard-clause rule above.

To detect guard-clause violations automatically (Python only), run:

```bash
python3 ~/.claude/scripts/check_guard_clauses.py <file1.py> [file2.py ...]
```

Fix every reported violation before proceeding. For non-Python files, apply the same guard-clause / closing-bracket discipline by eye — no script exists for those languages yet.

## 9. Verify, then report

Once all fixes are in, confirm they did not break anything. If the project defines a `code_checks` skill (or equivalent), use it — it already encodes the correct invocation. Otherwise:

**Formatting and lint (Python: ruff).** Run ruff in an ephemeral env via `uvx`, scoped to the source tree — pass the touched files directly, or the enclosing source folder (e.g. `src/`). Never run it at the repo root: that drags in `node_modules/`, build artifacts, and vendored code, an unnecessary blast radius.

```bash
uvx ruff format <touched-files-or-src-dir>
uvx ruff check --fix <touched-files-or-src-dir>
```

**Type checking (Python: mypy).** When the project has a Docker setup, run mypy inside the container — that is where its dependencies and type stubs are resolved, so a host-side run gives misleading results: `docker compose exec -T <svc> mypy <src-dir>`. Only run mypy on the host when no container exists.

Fixing rule 4 in particular can introduce unbound names or type errors, so do not skip the type check.

**Other languages.** Use the equivalent tools — Prettier/ESLint (and `tsc` for types) for TS/JS, `gofmt`/`go vet` for Go, `rustfmt`/`clippy` for Rust, etc. — under the same discipline: scope to the touched files or source dir (never the repo root), and prefer running them inside the container when the project is Dockerized.

Then report concisely: the files reviewed; per rule, what was fixed; anything you flagged but deliberately did **not** change (rules 1, 2, 3) with the reason; and the verification result. A silent diff is not an acceptable outcome.
