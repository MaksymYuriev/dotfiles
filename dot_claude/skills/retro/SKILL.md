---
name: retro
description: End-of-session retrospective. Extracts durable learnings from the current session into the knowledge vault at ~/vault (decision log, project notes), corrects notes the session proved wrong, and commits the vault.
argument-hint: "[optional focus, e.g. \"the payment bug root cause\"]"
disable-model-invocation: true
---

Do a retrospective of the current session and persist the durable learnings into `~/vault`. Read `~/vault/AGENTS.md` first and follow it.

Focus hint from the user (may be empty): $ARGUMENTS

## 1. Extract

Collect only durable, non-obvious knowledge:

- **Decisions:** what was decided, why, and what was rejected.
- **Root causes:** the actual cause of a failure, not the symptom, plus the probe that proved it.
- **Patterns and gotchas:** traps that cost time, and places where docs or instructions say X but reality is Y.
- **Cross-system knowledge:** anything spanning repos or services that no single codebase records.
- **Corrections:** vault notes this session proved stale or wrong.

Don't save:
- what the code or git history already records;
- session details with no future value;
- restatements of existing notes;
- secrets, tokens or personal data.

If nothing durable came out of the session, say so and stop. Noise in the vault costs more than a gap.

## 2. Route

- **Vault:** narrative, investigations, project and cross-project knowledge.
- **Auto-memory:** only a short rule about how the user wants the agent to work in one project. Mention it to the user; don't write it silently.
- **Tooling:** a lesson that is really a missing lint rule, hook, skill or CLAUDE.md line (the same mistake happened twice) gets proposed to the user as that change, in addition to the note.

## 3. Write

- **Decisions:** append to `~/vault/Decisions/YYYY-MM.md` for the current month, newest at the bottom, using `~/vault/Templates/decision-entry.md`. Fill Confidence, Rejected and Residual honestly. When a decision replaces an earlier one, add `Supersedes:` and append a `Superseded YYYY-MM-DD by …` line under the old entry.
- **Project knowledge:** add a dated section to the relevant existing note (search `~/vault/01-Projects/` first) and bump its `updated:` field. Create a new note (kebab-case, `~/vault/Templates/note.md` frontmatter) only when no existing note fits.
- **Corrections:** fix the wrong statement in place and leave a `Superseded YYYY-MM-DD: <what was wrong, what is true, how it was proven>` line next to it. Don't restructure the note.
- Link with `[[note-name]]` wiki-links, including to notes that don't exist yet.
- **Marked tables** (`<!-- …:… -->` markers) are living registries: edit rows inside the markers, then run the regeneration command documented in that note, if any.

## 4. Commit

```bash
git -C ~/vault add -A && git -C ~/vault commit -m "retro: <one-line summary of what was learned>"
```

## 5. Report

Tell the user in 2-5 bullets:
- what was saved, and where;
- what was corrected;
- what you skipped as not durable;
- any proposed tooling or memory change, waiting for their yes.
