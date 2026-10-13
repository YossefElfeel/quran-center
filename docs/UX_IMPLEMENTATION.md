# Quran Dar UX implementation checkpoint

Plan: `C:\Users\yosse\.claude\plans\analyze-this-project-and-foamy-forest.md`
Branch: `feat/ux-enhancement`
Updated: 2026-10-13 (Africa/Cairo). Local implementation is ready for release review; the complete plan is not deployed.

## Pending explicit approvals

1. Automatic approval review rejected hosted Supabase migration deployment to `quzqenavfoqsjupbtiix`: implementing the plan/Vercel deployment did not specifically authorize changing this production/shared database. The pending question covers both UX migrations and the matching `invite-user`, `reset-password` and `submit-public-application` functions. **No hosted migration or Edge update has occurred. Do not retry or bypass without a human answer.**
2. Automatic approval review also rejected `git push -u origin feat/ux-enhancement`: publishing the project source to the public `YossefElfeel/quran-center` repository needs explicit approval. **No push or PR creation has occurred. Do not use the GitHub connector or another route to bypass this rejection.**

Vercel deployment is already authorized. Production frontend deployment must wait for its required database columns/RPCs and Edge functions. Existing domains are `https://quran-web-sage.vercel.app` and `https://quran-dashboard-kohl.vercel.app`.

The original user edits are preserved in preparation commit `d6180ac` (34 files). The original tracked patch remains at `%TEMP%\quran-dar-ux-existing.patch`. Preserve that commit and every subsequent local UX commit/edit. Never stage `.env.local`, `.codex/`, `.pnpm-store/` or ignored build/QA output.

## Saved phase commits

| Phase | Local commit | Scope |
|---|---|---|
| 1 | `a8a92f0` | Account/family/billing/session flows, P0 dashboard and shared prerequisites |
| 2 | `260f18e` | Mobile form, empty-state and paging consistency |
| 3 | `89b03fe` | Role home, enrollment/guardian chain, child/account views and returned approvals |
| 4 | `15e918b` | Accessibility/localization cleanup and scaled UI regression snapshots |
| 5 | `be3be2a` | Remaining dashboard management flows and validated actions |
| 6 | `36afc36` | Public navigation, competitions/applications, course content and SEO |
| 7 | `e31356b` | Interim Realtime/unread count and release documentation/check wiring |

These are unpublished local commits. Shared prerequisites span phases; the checks below verify the assembled branch. Intermediate PR heads still need their own CI checks when the approved PR stack is published. FCM is not included in phase 7.

## Implemented locally

- Password confirmation/recovery, branded autofill login, neutral reset response, typed errors, optional Play Store/copy-email results and configurable redirects. Generated invite/reset links are explicitly for sharing; generateLink does not send mail.
- Atomic guardian phone/household/child setup, name-or-phone bounded family search, existing-person invitation, retained identity on failed invitation, edit/unlink and setup checklist.
- Parent billing across multiple households, separate paid-month calculation unaffected by repeated voids, history pages, due-month window, contact, refresh and route gate. Admin payment amount/month/method, review, uniqueness migration and undo.
- None/open/closed-today session views, details/extra session, checked open errors, missing attendance default, cached closed details consistent with queued writes, persisted excuse-request state/reason/busy guard.
- Offline open/attendance/grade/close queue, immediate/connectivity/resume/backoff flushing, multiple-page/concurrent drain safety, long-outage retention, dependent failed open/grade protection, clear retry/discard UI.
- Notification destinations, historical returned-evaluation month/circle, primary-tab switching, interim Realtime and full unread count. Returned monthly/development approval with reason, confirmations and previews.
- Role home, direct enrollment-to-guardian flow, multi-role primary tab, account/settings, role onboarding, child summary/tabs and confirmed consent changes.
- Shared modal/async form/select/search/paged/approval/contact patterns, Arabic/Persian digits, create/contact/refresh/search-reset empty-state actions, paged queues/history, directional icons, contrast tokens, type scale and touch semantics.
- Dashboard authenticated/session-bound impersonation client, subject identity for recorded_by/decided_by fields, operator plus verified subject/session in manual audit metadata, expiry cleanup/countdown and pending controls.
- Dashboard checked single-row write outcomes, read errors, atomic settings, complaints feedback, applicants' phone/contact, grouped responsive sidebar, keyboard-trapped dialogs, row disclosures, per-action schemas, inline field errors, retained failed inputs and Arabic input/date formatting.
- Student/person/household detail and membership flows, eligible certificate prefill, real PDF preview/download, course edit/description, competition rules/deadline/prize, excuse history and full filtered CSV export with formula escaping.
- Public navigation/contact/logo/fonts, all open competitions, validated application/reference/timeline, course descriptions, SEO/sitemap/robots/favicon and preserved public submission rate/duplicate/logging protections.

FCM and push preferences remain explicitly deferred by the plan until a Firebase/start decision.

## Verification

- Flutter analyze: zero findings (`mobile/build/ux-analyze.log`).
- Full non-golden suite: 177 passed (`mobile/build/ux-tests.log`). Focused new tests cover save validation/failure retention/slow double submit, logout/discard/payment confirmations, localized digits, all five palette contrasts, cache states, notification months, RTL, scaling, queue paging/concurrency and failed dependencies.
- Five Windows snapshots: existing score pad plus four 200% phone text cases. Real Cairo/Material icons loaded; final visual review fixed an invisible filled tasmee icon. These are local Windows references; Linux CI comparison is still pending publication.
- Web and dashboard lint/build pass. Temporary `/login/ux-check` fixture was removed; confirm it is absent from the final build.
- `pnpm test:forms` passes: financial precision/digits, UUID/role/reason guards, national ID, bounded JSON conditions and Cairo winter/summer timestamps.
- `pnpm test:certificate` generated a one-page real PDF and passed its byte/header smoke; earlier Arabic shaping/clipping inspection passed. Outputs are ignored under `dashboard/.next/qa/`.
- Dashboard fixture at 375px verified drawer, no page overflow, row disclosure, Tab/Shift+Tab focus trapping, Escape/focus restoration, inline payment error, preserved failed value and Arabic-digit success. Screenshot: `docs/qa/dashboard-form-375.png`. This was isolated UI QA, not a hosted account walkthrough.
- Public auth browser showed expired/used-link result and neutral recovery for a disposable `.invalid` address. No real password or mail delivery was tested.
- Completed Impeccable detector: `docs/ux-design-detect.json` = `[]`. Do not repeat unchanged checks routinely.
- Read-only hosted schema/function/index preflight completed. Duplicate non-voided household/month payments = 0; registration-phone and application uniqueness indexes already exist. Existing legacy close overload retained for compatibility.
- Prepared `supabase/tests/ux_flows.sql` rolls back guardian/login linkage, payment uniqueness/void, return-reason guard, returned notifications after transfer and retry-safe close. CI is wired to run it against an isolated Supabase instance. **Not executed here** (no Docker/psql; hosted mutation approval pending).

## Remaining release work

1. Obtain explicit public-source approval. Then push, create and attach the plan's phase PRs, and run CI. Local phase commits are saved; assembled-branch checks are documented above. Do not claim intermediate PR checks without running them.
2. After explicit backend approval, apply the two migrations in order, run the rollback smoke suite/advisors and deploy the three Edge functions preserving JWT flags. Verify imports and `_shared/log.ts` before publishing.
3. Hosted Auth site URL/redirect allow-list, templates and SMTP configuration still require verification. Follow `DEPLOY_RUNBOOK.md`; real reset/invite password entry requires the user's browser handoff.
4. Deploy authorized Vercel web/dashboard only after backend readiness. CLI authentication is unavailable; use the connector with project ID and omit team.
5. Complete actual Android role flows/TalkBack and authenticated dashboard impersonation/settings/recipient walkthroughs when device/account access permits. These live checks remain unverified.
6. Disable `resume-quran-dar-ux-plan` only once the complete plan/release is done. Stay quiet while approval/usage state is unchanged; do not retry rejected publication or hosted writes automatically.

## Tools

- Hourly continuation remains active. Most recent usage reading: 44% of five-hour, 42% weekly; ordinary usage allowed. Do not consume reset credits without a request.
- Supabase: `quzqenavfoqsjupbtiix` (Quran). Web project `prj_nilbtl8NBZQrPO7GAVlPPNcVKVie`; dashboard `prj_ffDLeI0u4sxExBO2t5MY61ppzqZS`.
- Flutter uses escalated `C:\src\flutter\bin\cache\dart-sdk\bin\dart.exe C:\src\flutter\bin\cache\flutter_tools.snapshot ...` because the wrapper SDK lockfile stalls. Dart format/fix uses the same executable; `dart fix` takes one target per command.
- Next build workers require escalated `pnpm build`. Existing package store is `C:\Users\yosse\AppData\Local\pnpm\store`.
- Ignored `.env.local` files contain public Supabase URL/anon key for local QA, no service key. Do not print or commit keys.
- GitHub CLI reports invalid stored tokens; the read-only GitHub connector works. Git publication itself is approval-blocked regardless of authentication route.
- Use LiteralPath for Windows bracket paths; `rg -g` for globs. Windows mapped-file error 1224 can need a brief retry; do not terminate unrelated user processes.
- Skills applied/read: Impeccable/harden/craft floor, Supabase, Vercel deployment/CLI/React/verification/env, PDF, computer-use and OpenAI Docs for continuation.
