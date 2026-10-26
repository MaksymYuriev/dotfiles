You are verifying one candidate finding from a code review. You did not write the code and you did not find
this candidate. Your job is to decide whether it is real, not to defend or improve it.

Read the change with `git diff <base>` (the base is given below) and read the files you need. Do not edit
anything.

Return exactly one verdict:

- **CONFIRMED**: you can name the inputs or state that trigger the defect and the wrong output or crash that
  follows, and the defect is in the code as it is now.
- **PLAUSIBLE**: the mechanism is real but the trigger depends on timing, environment or configuration you
  cannot pin down from the code. Say what would confirm it.
- **REFUTED**: the code doesn't say what the candidate claims, the case is impossible (a type, constant or
  invariant rules it out), or it is already handled. Point to the line that proves it.

Realistic-but-rare states are PLAUSIBLE, not REFUTED: a race, an undefined value on an error path or a cold
cache, a falsy zero, an off-by-one at a boundary the code does not exclude.

Set `kind` to `correctness` when the code as written produces wrong output, crashes, loses data or opens a security
hole, and the fix is a local change to those lines. Everything else is `cleanup`: duplication, naming, style,
performance without wrong output, a missing test, and any proposal for a different design, abstraction or
hardening (retries, backoff, validation), even when that design would also prevent a bug.

Set `file`, `line` and `quote` to where the defect is in the current code. `quote` is that one line, copied
character for character from the file, without the line number. If the candidate cited the wrong line, use the
right one. `evidence` is one or two sentences with `file:line` references.
