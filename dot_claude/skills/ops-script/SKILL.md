---
name: ops-script
description: Pattern for scripts that change shared or production data — CMS/Sanity migrations, database or Firestore patches, bulk API updates, feature-flag or experiment changes, content localization pipelines. Use before writing or running any such script.
---

# Scripts that mutate shared data

These scripts run against state other people and real users depend on. The user runs the real apply. You build the script, run the read-only parts, and hand over the exact command.

## Shape: plan → apply

1. **Plan (read-only).** Fetch current state, compute the intended changes, and write two files:
   - `plan.json`: exact per-document deltas, plus a SHA-256 of every input (source data, config, overrides) used to compute them.
   - `REPORT.md`: counts, per-target summary, and a **"Needs a human"** section.

   Write the plan only when it is clean, and delete any old plan first, so a failed run can't leave a stale plan behind.

2. **Apply.**
   - Dry-run by default; real writes need an explicit `--apply`. The dry run prints per-document field-level deltas against live state.
   - Refuse a plan whose input hashes no longer match.
   - Refuse to run without an explicit target (`--dataset`, `--project`, `--env`), and never default to production. Print the target before doing anything.
   - Destructive or replacing modes need their own flag (`--replace`, `--force`).
3. **Verify.** Re-read live state after the apply and diff it against the plan. Also run one end-to-end smoke check on the served artifact (see the `verify` skill).

## Guards

- **Idempotent:** use deterministic ids and keys (e.g. uuid v5 of `family:locale:role`) so re-runs replace rather than duplicate.
- **Compare-and-set:** write only if the current value equals the expected source value. Log `already-target` and `unexpected-value-skipped` rather than overwriting.
- **Field-role whitelist:** transform only fields whose role allows it (copy text, for example). Throw on any diff in identity or enum fields (`type`, `_type`, slugs, keys). A translated `type: "email"` once crashed a production step.
- **`mustSet`:** list fields the source never sets but the target needs, and fail until they're provided.
- **Census first:** before changing something shared, count its referrers (`count(*[references($id)])` or the equivalent) and diff target lists in both directions (plan ↔ expected set).
- **Drafts and published** (CMS): handle both, and remember unauthenticated reads can't see drafts.
- **Budgets:** check schema or attribute ceilings before adding fields in bulk.
- **Non-interactive:** use the tool's `--no-confirm` flag rather than piping `y`.
- **Exit codes:** 0 clean, non-zero on any error or "needs a human", plus `--json` for machine-readable output. Chained shell commands don't stop on a failed planner; the applier's hash check is the backstop.

## Housekeeping

- Keep the script. Commit it to the repo's migrations dir, or to a personal tooling repo if the repo gitignores migrations. Scripts that touched production have been lost before, leaving no record of what changed.
- The header states why the script exists, how to run it, and which past bug each guard prevents.
- Use zero-dependency Node `.mjs` where the runner requires plain Node (e.g. `sanity exec`).
- For write access, use the user's CLI login or 1Password (`op run`). Never read `.env*` files.
- Log what was applied (date, target, counts, script path) in the vault decision log through the `retro` skill.
