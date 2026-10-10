---
name: verify
description: Checklist for proving a change works at runtime rather than asserting it. Use before reporting done on anything that affects UI, runtime behavior, tracking, data or config; when a probe returns empty or "all clear" and the conclusion matters; and when a change "isn't showing up".
---

# Verify

Static checks (lint, types) run in the Stop hook. This skill covers what they can't prove: that the thing that ships behaves as intended where it runs.

## 1. Pick the observable

Verify the artifact the user or system actually consumes, not the source that should produce it.

| Claim | Weak evidence | Strong evidence |
|---|---|---|
| UI renders correctly | component code, isolated harness | screenshot of the real route, inside the real parent layout, at the real viewport |
| Data or content is right | CMS doc or config file | served HTML/JSON/RSC payload, scoped to the rendered region (payloads often serialize every variant) |
| Tracking fires | code calls `track()` | runtime `window.dataLayer` / pixel state, or the network request |
| Works in prod | dev server passes | prod build (`next build && next start`), preview env, or prod itself for read-only checks |
| Fix works | no error anymore | the original reproduction now passes, and fails again with the fix reverted |

Override layers change what is served: active experiments, feature flags, rollouts, CDN/ISR caches, per-origin storage. Check them before concluding from base config.

## 2. Make sure the probe can see

Before trusting an empty or negative result, run the same probe against a case known to be present. Common blind spots:

- **Auth:** unauthenticated queries return nothing for drafts or private data, and the empty result looks identical to "none exist".
- **Wrong path or shape:** e.g. an array field queried as an object; a filter on a field that isn't populated.
- **Wrong target:** grepping the working tree while reviewing a branch (use `git grep <pattern> <sha>`); reading a stale local clone of another repo (fetch first).
- **Client-rendered content:** `curl` can't see it; use a browser.
- **Network capture:** it starts when the tool is first called, and hard navigations reset it.
- **Retention windows:** logs and analytics expire, so check coverage before planning an investigation around them.
- **Tools that report success they didn't achieve:** a window resize that didn't apply, a 200 that revalidated nothing, a checker that skipped every file (zsh `$FILES` passed as one argument).

After a new check passes, break one input on purpose and confirm it fails.

## 3. "Change isn't showing up": triage in this order

1. **Which process and checkout serve the port?** Worktrees make this the default failure:
   - `ps -ax -o pid=,command= | grep -E "next dev|vite"`
   - `lsof -a -p <pid> -d cwd -Fn`
2. **Is the server alive?** A dead dev server looks like a browser or tool failure.
3. **Did it start after the change?** `ps -o lstart= -p <pid>`. Remember that `NEXT_PUBLIC_*` is inlined at start.
4. **Caches:** framework data cache, ISR/PPR shell, CDN, upstream cache, client router (hard reload).
5. **Origin:** a new port is a new origin, with empty localStorage and cookies.
6. Only then read the code.

## 4. UI checks

- **Mobile layout and fidelity:** use headless Playwright with the system Chrome at 375×812 @2x. It is the only reliable path to a true mobile viewport; the Chrome MCP window can't go below ~500px, whatever the resize call reports. If the repo has `playwright` in node_modules, resolve it from there with `channel: 'chrome'`. Don't install browsers without asking.
- **Interaction, logged-in state, live console and network:** use Chrome MCP.
  - Navigate to a new host standalone before batching.
  - Attach the console reader and then reload.
  - Pass `clear: true` between steps.
  - Never trigger `alert`/`confirm`.
  - Parallel agents share one browser, so keep browser work in one agent.
- **Compare with the design:** export the Figma node as PNG @2x and view both side by side. Compare structure, copy, colors, spacing rhythm and assets. Separate intentional data differences from real mismatches.
- **Layout signals** (IntersectionObserver, sticky, lazy reveal, CLS):
  - Screenshot at first paint, throttled (slow 3G / 4× CPU), without interacting.
  - List everything above the observed element that can change height after paint.
- **Isolated harness pages** must reproduce the real wrapper chain and global styles; a missing parent (a Stack that zeroes margins, a root font-size) confirms fixes that don't work. Delete the harness before committing.
- Read the screenshot. A verification that says "looks fine" without the image having been viewed is not a verification.

## 5. Side effects

Walking a real flow can create real users, orders or events. Prefer:
- routes that don't require auth;
- seeding persisted client state;
- a sandbox or test entity.

Ask before creating anything in a real backend.

## 6. Report

State:
- what was verified: URL or command, environment, viewport, seeded or walked;
- the evidence: screenshot path, payload excerpt, counts;
- console or network deltas against a baseline;
- what is still unverified and why.

If a failure also reproduces on a baseline (main branch, another domain), classify it as environmental, not as a defect of this change.
