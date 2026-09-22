<!--
  Thanks for the pull request!

  Title must follow Conventional Commits, e.g.
    feat(api): add owner-scoped property repository
    fix(web): keep expiring properties visible after a contact is logged
  See CONTRIBUTING.md for the full grammar.

  Keep the PR to one vertical slice. If you cannot describe it in one sentence,
  it is probably two pull requests.
-->

## Summary

<!-- What changes, and why. Two or three sentences. -->

## Related issues

<!-- `Closes #12` for the issue this finishes; `Refs #12` for related work. -->

- Closes #
- Task document:
- Requirements / ADR:
- Invariants touched:

## Type of change

- [ ] `feat` — new user-facing capability
- [ ] `fix` — bug fix
- [ ] `refactor` — no behaviour change
- [ ] `perf` — measured performance change
- [ ] `docs` — documentation only
- [ ] `test` — tests only
- [ ] `build` / `ci` / `chore` — tooling, dependencies, harness
- [ ] Breaking change (describe the migration below)

## How it was verified

<!--
  Paste the commands you actually ran and their results.
  "Verified it works" is not evidence. Test output and diffs are.
-->

```console
$ make verify
```

| Gate | Result |
| --- | --- |
| `make verify` | |
| New / changed tests | |
| Skipped gates (and why) | |

> A skipped gate is not a pass. List every gate that reported `SKIPPED` and the task that will cover it.

## Screenshots / recordings

<!-- UI changes only. Include loading, empty, error, and success states. Redact any personal data. -->

## Definition of done

<!-- Mirrors AGENTS.md. Tick only what is genuinely true; strike out what does not apply. -->

- [ ] Linked to a requirement ID or an ADR
- [ ] Request / response / error schemas exist
- [ ] Ownership filtering happens **on the server** (`owner_user_id` comes from the session, never from the client or a model)
- [ ] Happy-path, boundary, and failure tests exist
- [ ] No PII in logs, prompts, or error tracking (phone numbers, customer names, consultation text, workbooks, tokens)
- [ ] UI covers loading / empty / error / success states
- [ ] Eval dataset or fixture added where relevant
- [ ] OpenAPI client regenerated and its diff reviewed
- [ ] `make verify` passes
- [ ] No unmeasured improvement numbers claimed in docs
- [ ] `feature-list.json` status and `progress.md` updated

## Risk and rollback

<!-- Migrations, external writes (calendar, OAuth), or anything that needs explicit user confirmation.
     Say how to roll this back. Write "none" if there is no risk beyond the diff. -->

## Remaining problems

<!-- Anything still failing, skipped, or undecided. Do not leave this blank — write "none" if there is nothing. -->
