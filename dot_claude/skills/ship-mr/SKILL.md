---
name: ship-mr
description: Open a GitHub PR for the current branch with pre-flight checks, a Conventional Commits title and a lean body, then report the URL. Also covers merge-state traps. Use when the user asks to create/open a PR (or MR), or asks why a merged PR didn't deploy.
argument-hint: "[target branch, default: repo default branch]"
---

# Ship a PR

Project-level PR skills and repo conventions (templates, labels, commitlint scopes) take precedence. Read `CONTRIBUTING.md`, the PR template and the commitlint config if they exist.

## 1. Pre-flight (run in parallel)

```bash
git status --short                                  # must be clean
git log --oneline origin/<target>..HEAD             # the commits being proposed
git diff origin/<target>...HEAD --stat              # files + size
git rev-parse --abbrev-ref --symbolic-full-name '@{u}'   # pushed?
```

- If the tree is dirty, stop and ask.
- Diff every file you touched while debugging against the target, to confirm no temporary flags, logs or disabled guards remain.
- Check whether this branch already had a PR that got merged: `gh pr list --head <branch> --state all`.

  After a squash-merge with source-branch deletion, pushing recreates the branch with no open PR. The `* [new branch]` line in push output is the tell. Rebase onto the target (the squashed commits drop out), rename the branch to the remaining scope, and open a fresh one.
- Run the formatter on every touched file (never lock files) and the repo's lint and typecheck scripts. CI's format check fails on files edited after their last format pass.
- Pushing needs the user's approval (it's in the ask list). Never force-push. On your own feature branch, `--force-with-lease` is allowed only when the user asks.

## 2. Title

- Format: `<type>(<scope>): <subject>`, following Conventional Commits.
- Types: `feat`, `fix`, `refactor`, `perf`, `style`, `test`, `docs`, `build`, `ci`, `chore`.
- The scope follows the repo's convention; omit it for cross-cutting changes.
- The subject is imperative, starts lowercase, has no trailing period, and the whole title stays under ~72-100 characters.
- No ticket prefix unless the repo uses one. With squash merges, the title becomes the commit message.

## 3. Body

Keep it lean. It's for reviewers:

```markdown
### Description

**1. <headline change>** — what changed and why; call out non-obvious preserved behaviour.

### Testing

How it was verified: tests added/updated, the environment checked (preview URL, prod build), what remains unverified.
```

- Don't add points for incidental cleanup, don't dump config or JSON, and don't invent links or sections.
- Say plainly what is detected versus what is prevented, and list known residuals. Don't overclaim.
- No AI attribution line.

## 4. Create

```bash
gh pr create --base <target> --title "<title>" --body-file <file>
```

- Add `--draft` when the user says it isn't ready.
- Return the URL. Don't request reviewers, add labels or comment unless asked.

## 5. After merge: traps worth checking when something "didn't deploy"

- **Fast-forward-only repos:** a branch containing a merge commit can't be rebased server-side. Collapse it:
  - `git reset --soft origin/<target>`
  - check `git diff --cached --stat`: only your files;
  - commit, then `--force-with-lease`, with the user's OK.
- **Deploy skew:** one merge can trigger several deploys, so check each environment's deployed SHA.
