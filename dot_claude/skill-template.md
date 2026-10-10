---
# Skill template. Not loaded by Claude Code from here.
# Use: mkdir ~/.claude/skills/<name> && cp ~/.claude/skill-template.md ~/.claude/skills/<name>/SKILL.md
# Then fill it in, delete every comment and unused field, and run: chezmoi add ~/.claude/skills/<name>
# Field reference: https://code.claude.com/docs/en/skills

name: my-skill                  # kebab-case; becomes /my-skill. Never "synced" (reserved).
description: >-
  What it does in one sentence, then when to use it: the situations or phrases that should
  trigger it. Claude reads only this to decide whether to load the skill, so lead with the
  key use case. description + when_to_use are cut at 1,536 characters.
# when_to_use: Extra trigger phrases or example requests, appended to description.
# argument-hint: "[issue-number] [branch]"   # shown in autocomplete after /my-skill
# arguments: [issue, branch]                 # named args: $issue, $branch in the body

# Who can invoke it (default: both you and Claude):
# disable-model-invocation: true   # only you, via /my-skill. Use for side effects: deploy, commit, posting.
# user-invocable: false            # only Claude. Use for background knowledge, not an action.

# Permissions and tools (both reset when you send your next message):
# allowed-tools: Bash(pnpm test *) Read Grep   # pre-approved during the invoking turn; doesn't restrict others
# disallowed-tools: AskUserQuestion            # removed while the skill is active

# Execution:
# model: sonnet            # override for the rest of the turn; "inherit" keeps the session model
# effort: high             # low | medium | high | xhigh | max
# context: fork            # run in a forked subagent (keeps the main context clean)
# agent: Explore           # subagent type when context: fork
# paths: "src/**/*.ts"     # auto-load only when working on matching files
---

# My skill

One or two sentences: the goal, and what "done" looks like.

<!-- Write intent and reasons, not ALL-CAPS commands: Claude 5 models follow instructions literally,
     and "do X because Y" generalises better than "ALWAYS do X". One skill = one job. -->

## Inputs

Arguments from the user: $ARGUMENTS

<!-- What to do when an argument is missing: ask, infer, or use a default. -->

## Steps

1. <First step. Name the exact command or file where it matters.>
2. <Next step.>
3. <Verification: how to prove it worked. Point to the `verify` skill when it applies.>

<!-- Bundle long reference material or scripts as separate files in this skill's folder and
     reference them here, e.g. ${CLAUDE_SKILL_DIR}/scripts/check.sh or ${CLAUDE_SKILL_DIR}/reference.md.
     The body stays short and the extras load only when read. -->

## Rules

- <Constraint and its reason.>
- <What NOT to do, if the model tends to overreach here, and why.>

## Output

<!-- The exact shape of the result: a table, paste-ready text, a file path, a short report. -->
