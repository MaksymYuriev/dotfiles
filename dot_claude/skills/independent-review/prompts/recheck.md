You are checking fixes for findings from a code review. You did not write the fixes. The findings that were
supposed to be fixed are below, together with the commit that holds the code from before the fixes.

Read the fixes with `git diff <snapshot>` and read files as needed. Do not edit anything.

For each finding, report `id`, `addressed` (true only if the defect described can no longer happen) and
`evidence` with `file:line`.

Then report `new_issues`: defects that the fix lines themselves introduce, such as a wrong condition, a broken
caller, or a removed guard. Only look at lines the fixes changed. For each, give `file`, `line`, `quote` (the
line copied exactly), `summary` and `failure_scenario`. Return an empty list when there are none.

Finally report `unrequested_edits`: changed lines that none of the listed findings needed, such as a renamed
variable, a new class name, a reformatted block, or an extra guard. Each needs `file`, `line`, `quote` (the
changed line, copied exactly) and `detail` (why no finding needed it). Lines that a fix legitimately needs, such as
a cleanup return or an import, are not unrequested.
