---
name: review-mr
description: Review a colleague's GitHub PR and hand back paste-ready review comments for the user to post. Wraps the built-in /code-review. Use when asked to review someone else's PR by number, URL or branch. For your own uncommitted diff, run /code-review directly.
argument-hint: "<PR number | URL | branch> [low|medium|high|xhigh|max]"
---

# Review a PR

The built-in `/code-review` does the review. This skill adds what it doesn't: context gathering, never posting, and paste-ready drafts. The user posts them; never post, approve or edit the PR, and never pass `--comment` or `--fix`. Push to the author's branch only when the user explicitly asks for a fix.

## 1. Gather (in parallel)

- `gh pr view <id> --comments`
- `gh pr checks <id>`
- `git fetch origin <branch>` and note the head SHA. Any manual reading happens at that SHA (`git show <sha>:<path>`, `git grep -n <pattern> <sha>`), not in the working tree.
- Read the description and any linked issue or design for intent.

## 2. Review

Invoke `/code-review <id> <level> --max-findings all` (level from the arguments, default `high`). Report everything it finds; the user decides what to post.

Then check existing bot comments against the head SHA. They often reference earlier iterations. Keep the still-valid part.

## 3. Output

One block per finding, highest severity first, each ready to paste:

````markdown
**`path/to/file.ts:42`** · severity: blocking | important | minor · confidence: CONFIRMED | PLAUSIBLE

```
issue (blocking): <one-sentence problem, then the concrete consequence for users/business>

<optional: ```suggestion block or a short snippet>
```
````

- Conventional Comments labels: `issue`, `suggestion`, `question`, `nitpick`, `praise`, plus `(blocking)` / `(non-blocking)`.
- End with a 2-3 line verdict (approve / approve with nits / request changes) and what couldn't be verified.
