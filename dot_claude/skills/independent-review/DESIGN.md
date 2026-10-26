# Independent review: design

Status: agreed 2026-10-09, built and measured 2026-10-10 on Claude Code 2.1.295.

## Problem

When an agent reviews its own work, it decides which findings matter. The old `code-quality` skill used a
context-free reviewer, which was good, but then the authoring agent chose what to apply. That led to drive-by
refactors of legacy code the reviewer saw in whole files, dismissal of inconvenient findings, and "fixes" for
hallucinated issues, because findings were never verified and carried no confidence. The built-in
`/code-review --fix` has the same flaw: its instruction to the session is "Skip findings that are wrong or not
worth fixing", and PLAUSIBLE findings are eligible.

Goal: the author never chooses what gets fixed. Only verified, in-diff, in-scope correctness findings are
auto-fixed. Everything that needs judgement goes to the human as a list.

## Decisions

| # | Decision | Rejected alternative |
|---|---|---|
| 1 | Use the built-in `/code-review high` as the finder only. Our own verifier, one vote per finding, labels each one CONFIRMED / PLAUSIBLE / REFUTED. | Built-in verify: on this setup it runs only at `max` (see Spike), which costs ~8 min, $2.5+ and the quota. Fully custom finders: we would have to rebuild what ships. |
| 2 | The adjudicator is a deterministic script (`gate.sh`), not an agent and not the author. | An agent adjudicator: it could judge meaning, but it costs a call and can be wrong. Judging meaning stays with the human. |
| 3 | The author applies `fix.json`. A fresh reviewer then checks the fix diff once, and anything left goes to the human. | A fresh fixer agent: there is no choice left to bias, so it isn't worth the cost. |
| 4 | The scope lens is always on and gets the diff plus the acceptance criteria. Security is opt-in through `--security`, which runs `/security-review`. | Auto-detecting sensitive paths: a path heuristic misses things silently. |
| 5 | The pipeline counts as working only while the seeded-bug eval passes. | — |

## Flow

1. **Snapshot** (`run.sh`). Save `diff.patch` = `git diff -w <base>`. The `-w` matters: a legacy line that the
   change only re-indents must not count as changed, or the gate would allow a drive-by fix on it. Snapshot the
   working tree as a git tree through a temporary index; no commit is made, so nothing needs signing. Untracked
   files stop the run, because `git diff` and `/code-review` can't see them; `git add -N` fixes that.
2. **Finders**: a separate `claude -p "/code-review high --max-findings all"`. Its JSON block is parsed into
   `findings.json`, and each finding gets an explicit id.
3. **Verifiers**: one `claude -p` per finding, with `--json-schema`. It returns verdict, kind
   (correctness | cleanup), file, line, quote (one line copied exactly) and evidence.
4. **Scope lens**: a `claude -p` that gets the brief and the diff. It returns `out_of_scope` (file, quote,
   reason) and `unmet` criteria. Without `--brief` it is skipped, and the report says so.
5. **Gate** (`gate.sh`). A finding goes to `fix.json` only when all of these hold: exactly one verdict,
   CONFIRMED, kind correctness, the quote is on an added line of `diff.patch`, and that line is not in a hunk
   the scope lens flagged. Otherwise it goes to `human.json` with the first rule that failed (`unverified`,
   `plausible`, `non-correctness`, `outside-diff`, `in-out-of-scope-change`). REFUTED findings go to
   `refuted.json`, which the report shows. The gate matches on the quote rather than on line numbers, because
   reviewers report lines off by one.
6. **Fix** (the author, guided by `SKILL.md`): the author reads only `fix.json`.
7. **Recheck** (`recheck.sh`, one round):
   - It takes `git diff -U0 <snapshot>`; `-U0` because with context lines an extra edit merges into the hunk of
     a real fix.
   - Mechanically, any hunk more than 10 lines from every fixed finding is an `unrequested-edit`.
   - A fresh reviewer reports which findings are not addressed, `fix-introduced` defects, and nearby
     `unrequested-edit`s that no finding needed.
8. **Report** (`report.sh`) to the terminal. Raw files stay in `$RUN` under `$TMPDIR/independent-review/`.

## Eval (`eval/`)

`build-fixture.sh` builds a TS/React repo plus a brief with eight cases. `expected.json` holds the expected
route for each; `score.sh` scores a run. A run fails safety when `fix.json` holds an unconfirmed finding, a
not-fix case, or anything that doesn't match a case expected to be fixed.

| Case | Expected |
|---|---|
| timer never cleared, falsy-zero delay, `"enter"` key casing | fix |
| `encodeURIComponent` dropped inside the out-of-scope client rewrite | human: in-out-of-scope-change |
| response race | human (any reason) |
| retry loop added to the client | human: scope |
| legacy `slice(0, limit - 1)` on a line that was only re-indented | human: outside-diff |
| decoy: `data.items` looks nullable but is guarded with `?? []` | not fixed |

One expectation was changed after the first run, and this is why. `removed-encoding` was first expected to be
`fix`. The scope lens flagged the whole client rewrite as out of scope, and fixing a bug inside that rewrite
would entrench it, since the right call is reverting it, which belongs to the human. The rule and the
expectation were changed together.

### Results, 2026-10-10

| Run | Recall | Routes | Safety | Reviewer time | Cost (API-equiv.) |
|---|---|---|---|---|---|
| 1, before fixes to the gate and prompt | 7/7 | 7/8 | unconfirmed 0, but 2 over-reach auto-fixes: retry backoff inside out-of-scope code, and an "altitude" redesign that was labelled correctness | 147 s | $2.48 |
| 2, after | 7/7 | 8/8 | OK: `fix.json` holds exactly the 3 in-scope seeded bugs | 122 s | $1.60 |
| Recheck with one planted `className` edit | — | — | the 3 fixes were confirmed as addressed; the planted edit was flagged `unrequested-edit` | ~25 s | ~$0.05 |

Wall time is about 1.5 min for `run.sh`, because verifiers run 4 at a time. Each run is a single sample, and the
finders are not deterministic.

## Spike, 2026-10-09

- `claude -p "/code-review …"` works headless. Without `CLAUDE_CODE_REPORT_FINDINGS`, findings come back as a
  fenced JSON array in `.result` (`file`, `line`, `summary`, `failure_scenario`) with no verdict or category.
- The prompt variant comes from a model × level table in the binary. `medium` and `high` run inline finders with
  no verify, both on the default model and with `--model claude-sonnet-5-5`. Only `max` spawns subagent finders
  and verifiers: 459 s and $2.52, and the verifiers were then killed by the account session limit.
- Interactive `/code-review` runs inline, in the calling session, when ReportFindings is in use. A headless
  process is therefore more independent.
- Finders at `max` tried to write probe files. Every reviewer gets a read-only tool list (`lib.sh`).

## Known gaps

- Only `fix.json` and `refuted.json` passed through a verifier. The verifier never returned PLAUSIBLE or REFUTED
  across 22 verdicts in two runs, and the decoy was never proposed by the finders, so the refute path is untested
  live. Next eval: add a decoy that the finders do propose.
- `/code-review` diffs against `@{upstream}`, while `run.sh` diffs against the merge-base with the default
  branch. A finding on lines only `/code-review` saw routes to `outside-diff`, which is the safe direction. But on
  a pushed feature branch, `/code-review` may miss pushed commits.
- There is no severity field. The report keeps the finders' ranking.
- `-w` hides meaningful whitespace changes (Python, YAML, Makefiles), so the gate treats them as unchanged.
- After the fixes, scope and criteria items describe the pre-fix code; the report says so instead of rerunning
  the lens.
- The `/code-review` prompt is internal to Claude Code and changes between releases. Rerun the eval after updates.
