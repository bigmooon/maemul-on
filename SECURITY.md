# Security Policy

## Supported versions

This project is pre-release. Only the `main` branch receives fixes.

| Version | Supported |
| --- | --- |
| `main` | ✅ |
| Tagged releases | ❌ (none yet) |

## Reporting a vulnerability

**Do not open a public issue, pull request, or discussion for a security problem.**

Report it privately through
[GitHub Security Advisories](https://github.com/bigmooon/maemul-on/security/advisories/new).
If that is unavailable to you, email <bigmooon1215@gmail.com> with `SECURITY` in
the subject line.

Please include:

- the affected component (`apps/web`, `apps/api`, `ai`, `scripts`, …) and commit SHA,
- what an attacker can do, and what they need in order to do it,
- reproduction steps or a proof of concept,
- **no real personal data** — redact phone numbers, customer names, consultation
  text, workbooks, tokens, and authorization codes from anything you attach.

You can expect an acknowledgement within 72 hours and a status update within
seven days. Please give a reasonable window for a fix before disclosing publicly.
Reporters are credited in the advisory unless they ask not to be.

## What counts as a vulnerability here

This application manages a single real-estate agent's **private** property,
customer, and consultation records. The following are in scope, and each maps to
a product invariant in [`AGENTS.md`](AGENTS.md):

- **Cross-user data exposure** — reaching another signed-in user's data through
  the API, search, a chatbot citation, a file, or a calendar entry (INV-06).
- **Trusting a client- or model-supplied user identity** — `owner_user_id` must
  be injected from the server session only.
- **Arbitrary SQL through the chatbot**, or any write path from the chatbot
  (INV-07).
- **PII leakage** — phone numbers, customer names, consultation text, raw
  workbooks, tokens, or authorization codes appearing in logs, LLM prompts, or
  error tracking.
- **Public or shared URLs** for what is meant to be private data (INV-11).
- **OAuth problems** — Naver login or Naver Calendar token handling, refresh,
  scope, or redirect validation.
- **Prompt injection that escalates privilege** — instructions embedded in an
  uploaded document or a consultation note are data, never authority.
- **Secrets committed to the repository.**

## Out of scope

- Findings that require physical access to an already-unlocked machine.
- Denial of service from unrealistic traffic volumes against a single-user app.
- Missing hardening headers with no demonstrated impact.
- Automated scanner output without a working proof of concept.
- Vulnerabilities in third-party dependencies with no exploitable path in this
  codebase — report those upstream, and open a normal issue here so the version
  can be bumped.
