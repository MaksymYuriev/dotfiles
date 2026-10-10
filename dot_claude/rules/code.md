---
paths:
  - "**/*.{ts,tsx,js,jsx,mjs,cjs,css,scss}"
  - "**/*.{sh,py}"
  - "**/package.json"
---

# Coding rules

These load when code files are read or edited. Project conventions win when they conflict.

## Before changing code

- Read the README and package.json scripts before running anything.
- Look for an existing helper or component by concept, not by the name you would give it (a "slider" may live as a carousel or swiper). Inherit a mechanism the codebase already ships before inventing one; extract its pure core rather than forking it.
- For structural decisions (fork vs extend, where state lives, which layer owns what), check project docs and the decision log for precedent and cite it. Without precedent, present options with tradeoffs and one recommendation, then wait.

## Code

- TypeScript strict. Model uncertain shapes with discriminated unions and type guards; `any` and `as` switch off exactly the checks strict mode is there for.
- Validate external data (API responses, env vars, form input) with Zod at the boundary.
- React: Server Components by default, `"use client"` only where needed. Derive state during render rather than syncing it through `useEffect`, which costs an extra render with stale values. Memoize only when measured.
- Keep components under ~300 lines and prop drilling to 2 levels at most.
- Imports: absolute `@/`, grouped external, internal, types, styles.
- Naming: camelCase for values and functions, PascalCase for components and types, SCREAMING_SNAKE_CASE for constants.
- Make failure loud or impossible: exhaustive `Record<Union, …>` and mapped types over stringly switches, discriminated error results over swallowed ones. Treat `Promise.allSettled`, catch-all fallbacks and env-var lists as places where errors hide.
- Implicit contracts (pairing by array position, last-wins merges, magic keys) are a recurring bug class. Make them explicit or assert them at the consumer.
- On live surfaces shared with real users or running experiments, make changes additive and opt-in, with the existing path byte-identical when the new thing is off.
- When editing one of several copy-pasted siblings, grep the others. They drift.

## Comments

This section is the single source for comment rules; the `comment-budget.sh` hook enforces the length and JSDoc parts on added lines.

- Default to none. Reviewers have called agent comments noise.
- A comment must pass the delete test: would the information be lost for good, not recoverable from code, types, call sites or git blame?
- What passes: a decision plus the rejected alternative, a landmine, an invariant the types can't express, or a link to a source of truth.
- One line is the target and two the hook-enforced maximum. No banners. JSDoc only on exported API.
- Notes about how you did the work belong in the PR description. Comments I removed stay removed.

## Checks

- Global hooks (`~/.claude/hooks/verify/`) run eslint --fix, prettier and the package typecheck script on files edited this turn, check comments and `.only(`, and block the turn on red.
- Errors only in files you didn't touch usually point to the environment (stale deps, wrong Node version, worktree symlinks). Reproduce on the main branch before blaming the change.
- Tests: behavior over implementation, integration over unit for UI, MSW for API mocking. If you skip, weaken or delete a test to get green, say so.
