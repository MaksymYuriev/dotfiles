---
name: independent-review
description: >-
  Review your own finished change with independent reviewers and fix only what a script allows: CONFIRMED
  correctness findings on lines this change added, outside any out-of-scope hunk. Everything else goes to the
  user as a list. Use at the end of a task, when the user runs /independent-review, or from a task-brief executor step.
argument-hint: "[--brief <file>] [--security] [--base <ref>]"
disable-model-invocation: true
---

# Independent review

The point is that you, the author, don't decide which findings matter. Fresh `claude -p` processes find and
verify issues, and `gate.sh` decides what gets fixed. Done means: fixes applied for `fix.json` only, one recheck
round run, and the report shown to the user. Design and eval results: `${CLAUDE_SKILL_DIR}/DESIGN.md`.

## Inputs

Arguments: $ARGUMENTS

- `--brief <file>`: the task brief with acceptance criteria. Without it the scope lens is skipped, and the report
  says so. Don't write a brief yourself from the conversation; the scope check is only independent if the
  criteria come from the user.
- `--security`: also runs `/security-review`. The user chooses it; don't add it on your own.

## Steps

1. Run `${CLAUDE_SKILL_DIR}/run.sh $ARGUMENTS` from the repo. It takes 1–3 minutes, and the last stdout line is the
   run directory (`$RUN`). If it stops on untracked files, run `git add -N` on the files you created for this
   task and leave the rest to the user. Then rerun.
2. Read `$RUN/fix.json` and fix exactly those findings, with the smallest change that removes each defect. Do
   not open `human.json` or `findings.json` before or while fixing. Do not fix anything else you notice: if
   something seems wrong, mention it in your reply instead.
3. Run the project's checks on the touched files (typecheck, tests) as usual.
4. Run `${CLAUDE_SKILL_DIR}/recheck.sh "$RUN"`. Run it once; don't fix its findings and loop. Its findings
   go to the user.
5. Run `${CLAUDE_SKILL_DIR}/report.sh "$RUN"` and show its output to the user verbatim, then add the result of
   step 3.

## Rules

- `fix.json` empty means nothing gets auto-fixed. That is a valid outcome, so don't go looking for something to fix.
- If a script fails, report the error and the `$RUN` path. Don't hand-build the JSON files it would have made:
  then the gate would be run by the author again.
- Reviewers run on the user's Claude quota. A run on a ~3-file diff measured about $1.6–2.5 API-equivalent and
  2 minutes, so don't rerun just to get a different answer.
