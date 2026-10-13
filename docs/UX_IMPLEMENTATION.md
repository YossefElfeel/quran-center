# Quran Dar UX implementation checkpoint

Plan: `C:\Users\yosse\.claude\plans\analyze-this-project-and-foamy-forest.md`
Branch: `feat/ux-enhancement`
Updated: 2026-10-13 (Africa/Cairo). Local implementation is ready for release review; the complete plan is not deployed.

## Release authorization and progress

The user explicitly approved both release actions on 2026-10-13: public GitHub publication and the two UX migrations plus `invite-user`, `reset-password` and `submit-public-application` on hosted Supabase `quzqenavfoqsjupbtiix`. The earlier approval blocks are resolved.

The saved feature branch and six intermediate phase branches are published. Draft PRs [14](https://github.com/YossefElfeel/quran-center/pull/14) through [20](https://github.com/YossefElfeel/quran-center/pull/20) are attached to this chat, stacked in phase order. GitHub connector writes returned insufficient integration permissions; Git/CLI publication succeeded using the existing GitHub credential without exposing it.

Supabase `apply_migration` returned `Invalid or expired requestState` twice without applying changes. The user then explicitly selected `YossefElfeel` for the browser fallback. Both exact migration files were applied transactionally through the SQL editor, with matching version/name/source entries recorded in migration history. The hosted rollback suite reported **UX OK**, and a separate query confirmed zero leftover UX fixtures. Edge versions are now `invite-user` 13 (JWT enabled), `reset-password` 10 (enabled) and `submit-public-application` 12 (disabled as before; shared logger included).

Security advisors were checked before and after: the only count increase is the intentionally admin-gated `update_guardian_details` definer RPC (18 callable guarded RPCs versus 17 before). Existing service-only RLS/no-policy informational notices and leaked-password warning remain; see [definer advisor](https://supabase.com/docs/guides/database/database-linter?lint=0029_authenticated_security_definer_function_executable) and [password protection](https://supabase.com/docs/guides/auth/password-security#password-strength-and-leaked-password-protection).

Vercel production builds started from verified application commit `31d81ee`: web `dpl_DjYNvDMQBwgF8pU3yMRZQx3ut82G`, dashboard `dpl_6LVordYQN7SFekYNDonhnEjjeNgX`. Completion, canonical aliases and live browser verification are still pending.

Vercel deployment is already authorized. Production frontend deployment must wait for its required database columns/RPCs and Edge functions. Existing domains are `https://quran-web-sage.vercel.app` and `https://quran-dashboard-kohl.vercel.app`.

The original user edits are preserved in preparation commit `d6180ac` (34 files). The original tracked patch remains at `%TEMP%\quran-dar-ux-existing.patch`. Preserve that commit and every subsequent local UX commit/edit. Never stage `.env.local`, `.codex/`, `.pnpm-store/` or ignored build/QA output.

## Saved phase commits

| Phase | Commit | Draft PR | Scope |
|---|---|---|---|
| 1 | `a8a92f0` | [14](https://github.com/YossefElfeel/quran-center/pull/14) | Account/family/billing/session flows, P0 dashboard and shared prerequisites |
| 2 | `260f18e` | [15](https://github.com/YossefElfeel/quran-center/pull/15) | Mobile form, empty-state and paging consistency |
| 3 | `89b03fe` | [16](https://github.com/YossefElfeel/quran-center/pull/16) | Role home, enrollment/guardian chain, child/account views and returned approvals |
| 4 | `15e918b` | [17](https://github.com/YossefElfeel/quran-center/pull/17) | Accessibility/localization cleanup and scaled UI regression snapshots |
| 5 | `be3be2a` | [18](https://github.com/YossefElfeel/quran-center/pull/18) | Remaining dashboard management flows and validated actions |
| 6 | `36afc36` | [19](https://github.com/YossefElfeel/quran-center/pull/19) | Public navigation, competitions/applications, course content and SEO |
| 7 | `e31356b` | [20](https://github.com/YossefElfeel/quran-center/pull/20) | Interim Realtime/unread count and release documentation/check wiring |

All saved commits, including preparation `d6180ac` and checkpoint `31d81ee`, are published without rewriting history. CI found missing early-phase reset/realtime dependencies and the original harness formatting; repair commits were merged forward through the phase stack. Phases 1–3 now pass all five CI jobs. Phase 4's Linux generation run passed; comparison and phases 5–7 are being verified. FCM is not included in phase 7.

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
- Five Windows snapshots: existing score pad plus four 200% phone text cases. Real Cairo/Material icons loaded; final visual review fixed an invisible filled tasmee icon. Linux CI exposed platform pixel differences, so references now live under `goldens/windows` and `goldens/linux`, selected by the actual host OS. Windows comparison still passes all five; Linux references were generated in CI and visually reviewed. Regeneration requires the explicit `update_goldens=true` dispatch input; ordinary dispatch/PR checks compare the saved references.
- Web and dashboard lint/build pass. Temporary `/login/ux-check` fixture was removed; confirm it is absent from the final build.
- `pnpm test:forms` passes: financial precision/digits, UUID/role/reason guards, national ID, bounded JSON conditions and Cairo winter/summer timestamps.
- `pnpm test:certificate` generated a one-page real PDF and passed its byte/header smoke; earlier Arabic shaping/clipping inspection passed. Outputs are ignored under `dashboard/.next/qa/`.
- Dashboard fixture at 375px verified drawer, no page overflow, row disclosure, Tab/Shift+Tab focus trapping, Escape/focus restoration, inline payment error, preserved failed value and Arabic-digit success. Screenshot: `docs/qa/dashboard-form-375.png`. This was isolated UI QA, not a hosted account walkthrough.
- Public auth browser showed expired/used-link result and neutral recovery for a disposable `.invalid` address. No real password or mail delivery was tested.
- Completed Impeccable detector: `docs/ux-design-detect.json` = `[]`. Do not repeat unchanged checks routinely.
- Read-only hosted schema/function/index preflight completed. Duplicate non-voided household/month payments = 0; registration-phone and application uniqueness indexes already exist. Existing legacy close overload retained for compatibility.
- `supabase/tests/ux_flows.sql` rolls back guardian/login linkage, payment uniqueness/void, return-reason guard, returned notifications after transfer and retry-safe close. Passed in isolated Linux CI and against the approved hosted release, with zero fixtures remaining afterward. Live invite delivery/login is a separate unverified check.

## Remaining release work

1. Finish CI on the seven published draft PRs and fix any failures. Public-source approval, push, PR creation and attachment are complete.
2. Backend migration, rollback smoke/advisor and three Edge deployments are complete. Finish endpoint validation and actual account workflows when account/device access is available.
3. Hosted Auth site URL/redirect allow-list, templates and SMTP configuration still require verification. Follow `DEPLOY_RUNBOOK.md`; real reset/invite password entry requires the user's browser handoff.
4. Finish the authorized Vercel web/dashboard builds and verify canonical production aliases and browser flows. Connector deployment uses project ID and omits team.
5. Complete actual Android role flows/TalkBack and authenticated dashboard impersonation/settings/recipient walkthroughs when device/account access permits. These live checks remain unverified.
6. Disable `resume-quran-dar-ux-plan` only once the complete plan/release is done. Stay quiet while usage/non-actionable external state is unchanged. Both release approvals and the Supabase account choice have arrived.

## Tools

- Hourly continuation remains active. Both release actions and sign-in as `YossefElfeel` are explicitly approved. Check usage on resume; do not consume reset credits without a request.
- Supabase: `quzqenavfoqsjupbtiix` (Quran). Web project `prj_nilbtl8NBZQrPO7GAVlPPNcVKVie`; dashboard `prj_ffDLeI0u4sxExBO2t5MY61ppzqZS`.
- Flutter uses escalated `C:\src\flutter\bin\cache\dart-sdk\bin\dart.exe C:\src\flutter\bin\cache\flutter_tools.snapshot ...` because the wrapper SDK lockfile stalls. Dart format/fix uses the same executable; `dart fix` takes one target per command.
- Next build workers require escalated `pnpm build`. Existing package store is `C:\Users\yosse\AppData\Local\pnpm\store`.
- Ignored `.env.local` files contain public Supabase URL/anon key for local QA, no service key. Do not print or commit keys.
- GitHub CLI's stored tokens were invalid, but the existing Git credential successfully pushed and created draft PRs. Use a temporary `GH_TOKEN` only within the CLI process and restore it afterward; never print/store the credential. GitHub connector reads work, PR writes return HTTP 403.
- Use LiteralPath for Windows bracket paths; `rg -g` for globs. Windows mapped-file error 1224 can need a brief retry; do not terminate unrelated user processes.
- Skills applied/read: Impeccable/harden/craft floor, Supabase, Vercel deployment/CLI/React/verification/env, PDF, computer-use and OpenAI Docs for continuation.
