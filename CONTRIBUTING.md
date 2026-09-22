# Contributing to 매물온 (maemul-on)

Thanks for your interest in the project. This document covers the **GitHub-facing
workflow**: branches, commits, pull requests, and reviews.

The engineering rules themselves — product invariants, folder responsibilities,
the definition of done — live in [`AGENTS.md`](AGENTS.md) and the `AGENTS.md` of
each area. Those documents are written in Korean and are the source of truth;
this file does not duplicate them.

> **Language policy.** Issues, pull requests, commit messages, code comments,
> and identifiers are written in **English**. Internal design documents under
> `docs/` are written in Korean. Do not translate one into the other — keep each
> in its own language so there is exactly one copy of every rule.

---

## Table of contents

- [Before you start](#before-you-start)
- [Getting set up](#getting-set-up)
- [Branching](#branching)
- [Commit messages](#commit-messages)
- [Pull requests](#pull-requests)
- [Review](#review)
- [Reporting bugs and requesting features](#reporting-bugs-and-requesting-features)
- [Security](#security)

---

## Before you start

Read, in this order:

1. [`AGENTS.md`](AGENTS.md) — product centre, invariants, commands, prohibitions, definition of done
2. The `docs/tasks/TASK-xxxx.md` for your work — if it does not exist, create it from [`TASK-TEMPLATE.md`](docs/tasks/TASK-TEMPLATE.md) **first**
3. The requirement sections and ADRs the task points at
4. The `AGENTS.md` of the area you are changing
5. The code you are about to modify

Two rules are worth repeating here, because they are the ones most often broken
in a pull request:

- **Code does not win against requirements.** If the implementation needs to
  differ from [`docs/product/requirements.md`](docs/product/requirements.md),
  write an ADR in [`docs/decisions/`](docs/decisions/) and update the
  requirements and tests together. Do not change the code first.
- **A skipped gate is not a pass.** Deleting a test or adding a skip to make
  `make verify` green does not count as done.

## Getting set up

```bash
make doctor   # check required tooling, and print install commands for whatever is missing
make init     # prepare the Python runtime (uv), dependencies, and .env — idempotent
make smoke    # quick liveness check
make dev      # web (5173) + api (8000)
```

On Windows without `make`, run the same targets as `./make.ps1 <target>`. Both
paths call the same `scripts/*.sh`, so results are identical.

Requires Node ≥ 20, pnpm, uv, and git. Python is installed and managed by uv —
do not use a system Python.

## Branching

Branch off `main`. One branch, one vertical slice.

```text
<type>/<short-kebab-description>
<type>/<issue-number>-<short-kebab-description>
```

Examples:

```text
feat/12-owner-scoped-property-repository
fix/expiry-list-keeps-contacted-properties
docs/adr-0004-naver-calendar-failure-policy
chore/bump-vitest-to-3
```

Use the same `<type>` vocabulary as commits. Keep branches short-lived; rebase
onto `main` rather than merging `main` into your branch.

## Commit messages

This repository follows [Conventional Commits 1.0.0](https://www.conventionalcommits.org/en/v1.0.0/).

```text
<type>(<scope>): <subject>

<body>

<footer>
```

### Rules

| Part | Rule |
| --- | --- |
| `type` | Required. One of the types below, lowercase. |
| `scope` | Optional but encouraged. One of the scopes below, lowercase. |
| `subject` | Required. Imperative mood ("add", not "added" or "adds"), lowercase, no trailing period. The whole header line stays ≤ 72 characters. |
| body | Optional. Wrap at 72 columns. Explain **why**, not what — the diff already says what. |
| footer | Optional. `Closes #12`, `Refs #12`, `BREAKING CHANGE: …`, `Co-Authored-By: …`. |

### Types

| Type | Use for |
| --- | --- |
| `feat` | A new user-facing capability |
| `fix` | A bug fix |
| `docs` | Documentation only (requirements, ADRs, runbooks, README) |
| `style` | Formatting only, no code meaning changed |
| `refactor` | Code change that neither fixes a bug nor adds a feature |
| `perf` | A **measured** performance improvement |
| `test` | Adding or correcting tests |
| `build` | Build system, dependencies, package manager |
| `ci` | CI configuration and workflows |
| `chore` | Developer harness and other maintenance |
| `revert` | Reverting a previous commit |

### Scopes

Derived from the repository layout: `web`, `api`, `api-client`, `ai`, `evals`,
`tests`, `scripts`, `docs`, `deps`, `release`.

### Examples

```text
feat(api): add owner-scoped property repository

Every query now takes owner_user_id from the server session instead of the
request body, so a forged client payload cannot reach another user's rows.

Closes #14
Refs INV-06
```

```text
fix(web): keep expiring properties visible after a contact is logged

The list filtered out properties whose latest contact was complete, which
hid work the agent still had to finish. INV-03 requires them to stay.

Closes #21
```

```text
refactor(api)!: replace fixed 90-day window with a calendar-month range

BREAKING CHANGE: ExpiryWindow.days is gone. Callers pass a calendar range
with both ends inclusive, per INV-02.
```

```text
chore(scripts): make make.ps1 reject the WSL bash on PATH
```

### Breaking changes

Mark them either with a `!` after the type/scope (`feat(api)!: …`) **or** with a
`BREAKING CHANGE:` footer describing the migration. Prefer both.

### Enforcement

A commit message template and an optional local hook ship with the repository:

```bash
git config commit.template .gitmessage.txt   # prefill the format in your editor
git config core.hooksPath .githooks          # reject non-conforming messages locally
```

You can also validate a file directly:

```bash
bash scripts/check-commit-msg.sh .git/COMMIT_EDITMSG
```

## Pull requests

1. **One slice per PR.** "Expiry domain function → API → one card → boundary
   tests" is a pull request. "Implement the home screen" is not.
2. **Title follows Conventional Commits**, same grammar as a commit subject.
   The squash-merge commit is built from it.
3. **Fill in the template.** Every section. `Remaining problems` says "none" or
   lists what is still failing — it is never left blank.
4. **Run `make verify` and paste the real output.** List every gate that
   reported `SKIPPED` and the task that will cover it.
5. **Mark it as a draft** while it is still moving.
6. **Update the records**: `feature-list.json` status and
   [`progress.md`](progress.md), plus an ADR if the design changed.

Before requesting review, re-read your own diff looking specifically for:

- a missing ownership filter, or an `owner_user_id` that came from the client
- PII in logs, prompts, or error tracking
- dates computed by hand instead of through the calendar-range helper
- schema validation bypassed on one of the two registration paths (manual, Excel)
- an external write (calendar, contract change) without explicit user confirmation

These five are the recurring defects in this codebase, and reviewers check them
first.

### Merging

Pull requests are **squash-merged**. The squash commit message is the PR title
plus a cleaned-up body, so a good title is not optional. Delete the branch after
merge.

## Review

- Review the change against the requirement or ADR it claims to implement, not
  against personal preference.
- Comments that request a change say what is wrong and what would be right.
- Approving means you believe the definition of done in `AGENTS.md` is met.
- The author resolves conversations; the reviewer confirms they were addressed.

## Reporting bugs and requesting features

Open an issue with one of the [templates](.github/ISSUE_TEMPLATE). Before you do:

- search existing issues,
- check [`docs/product/deprecated.md`](docs/product/deprecated.md) — the
  behaviour may have been removed on purpose,
- **redact all personal data**. No phone numbers, customer names, consultation
  text, uploaded workbooks, tokens, or authorization codes, anywhere in an
  issue, a pull request, a commit message, or a screenshot.

## Security

Do not open a public issue for a vulnerability. Follow [`SECURITY.md`](SECURITY.md).

---

By contributing you agree that your contributions are licensed under the
[MIT License](LICENSE), and that you will follow the
[Code of Conduct](CODE_OF_CONDUCT.md).
