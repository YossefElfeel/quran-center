# Mobile app — flow audit (2026-06)

## Re-verification — 2026-10-13

The June findings below are preserved as history. The active plan is
`C:\Users\yosse\.claude\plans\analyze-this-project-and-foamy-forest.md`, on
`feat/ux-enhancement`. Its initial re-check found 6 fixed, 6 partial and 13 open
items. The table below records the assembled local implementation, not a claim
that these changes have been deployed.

| June item | Current evidence / remaining limit |
|---|---|
| 1 Family/paywall | Guardian phone, atomic household/child creation, linked invitation retry and setup checklist implemented. New hosted RPC/Edge deployment awaits approval. |
| 2 Offline loss | Pending/dead records visible; confirm before discard; immediate/resume/backoff flushing; failed grade/open blocks dependent close/writes. Regression tests pass. |
| 3 Teacher name | Existing teacher embed preserved in the preparation snapshot. |
| 4 Null joins | Earlier null-safe model/repository fixes preserved; original regression tests pass. |
| 5 Unknown enums | Historical unknown-value fallback issue is outside the current UX plan; do not call it fixed by moving labels. |
| 6 Document upload | Existing session/20MB checks, error mapping and orphan cleanup preserved. Live storage behavior has not been re-tested. |
| 7 Video processing | Existing explicit upload/service protections preserved. No new video-processing pipeline is claimed. |
| 8 Duplicate routes | Three primary-tab aliases redirect to `/me`; notifications switch tabs with `go`. |
| 9 Navigation | Role home uses the primary tab for those destinations and pushes detail screens. |
| 10 Enrollment | Searchable circle selection with capacity; student save returns ID; guardian linking follows from the success action. Device tap-count walkthrough remains unverified. |
| 11 Theme location | Display preferences and logout live in Settings; More links to Settings. |
| 12 RTL chevrons | Shared drill-in icon and RTL widget regression pass. |
| 13 Icons | Semantic `AppIcons` adopted; filled tasmee icon uses the contrasting foreground. |
| 14 RTL layout | Directional layouts retained; Arabic interface inspected at phone width and 200% text. |
| 15 Feedback | Create/save outcomes, retry-preserving async sheets and dashboard action feedback implemented. |
| 16 Confirmations | Payment, logout and saved-grade discard tests pass; approval/return/consent/destructive sheets share confirmation patterns. |
| 17 Validation | Localized numbers and inline field errors; slow-save/retry regression passes; dashboard action schema regressions pass. |
| 18 Double submit | Busy/disabled controls; async-sheet and concurrent outbox tests pass. |
| 19 Empty/accessibility | Creation/contact/refresh/search-reset actions added; drawer, keyboard focus, Escape, failed-input retention and row disclosure verified in an isolated dashboard fixture. |
| 20 Pagination | Complaints, ratings, excuses, waiting list, monthly/development queues and struggling students use bounded pages; household/person search is bounded; payment history has show-more. |
| 21 Push | Interim Realtime + uncapped unread count implemented. FCM and preferences explicitly remain deferred until the user's Firebase/start decision. |
| 22 Parent billing | Multiple households, paid/due months, paged history, contact and refresh implemented. Hosted uniqueness constraint and device gate walkthrough await release checks. |
| 23 Account center | Name/email/password, display, sync, version/contact and confirmed logout implemented. |
| 24 Localization | Eight enum labels, exception defaults and router fallback titles moved to presentation l10n. PDF labels and some new Arabic UI copy remain Arabic-only. |
| 25 Recovery | Public confirmation/recovery pages, branded mobile login/reset and configurable redirect implemented. Real email delivery/password change await hosted Auth/SMTP configuration and a human walkthrough. |

The current plan's 12 priority dead ends have local implementations, including
three session states, queued default attendance on close, returned evaluations,
payment review/undo, impersonated data access, checked settings/complaint outcomes,
applicant phone links and public navigation. Returned monthly evaluations retain
their month and the original teacher's circle after a student transfers.

Validation: Flutter analyze has zero findings; 177 non-golden tests pass; five
Windows golden snapshots include four 200% text cases. Both Next.js applications
pass lint and production builds. Certificate generation and financial/input schema
smokes pass. `docs/ux-design-detect.json` records the completed detector result.

`supabase/tests/ux_flows.sql` is prepared and wired into isolated CI, but has not
run here: this host has no local Docker/Postgres, and hosted writes need approval.
Live role/device/TalkBack, SMTP, invite identity and impersonation walkthroughs
are not claimed as complete. See `UX_IMPLEMENTATION.md` and `DEPLOY_RUNBOOK.md`.

Verification-grade audit of the Flutter app (`mobile/`, Arabic-first RTL, Supabase + Drift
offline outbox). Each finding is marked **CONFIRMED** (read in code/schema) or **SUSPECTED**
(needs a runtime check), with a severity and `file:line`. Findings drive the phased fix plan in
`.claude/plans/most-of-the-flows-shimmering-wadler.md`.

## Method & headline

Three broad explore passes + targeted direct reads of repositories, migrations, and the
outbox/Drift layer. The app is **structurally complete** — 43 screens, all routed, no orphan
screens, no `TODO`/`UnimplementedError`/"coming soon" stubs, no empty `onPressed`. The real work
is a small set of genuine dead-ends/silent-failure bugs plus broad nav/icon/RTL/polish gaps and
a few incomplete feature layers.

Two earlier "blocker" claims were **disproven** by reading later migrations:
`daily_tasmee.session_id` exists (`20260618100004_tasmee_session_link.sql`) and
`teacher_pass_rate` RPC exists (`20260618190001_teacher_profile_development.sql`). A third agent
claim ("competition detail has no results button") was also wrong — the button exists
(`competition_detail_screen.dart:111`).

## Verified-OK (do not "fix")

- **PDF generation** — all 4 builders (`certificate_pdf`, `progress_card_pdf`,
  `attendance_sheet_pdf`, `monthly_circle_report_pdf`) embed Cairo + Amiri TTFs and set
  `pw.TextDirection.rtl`; Arabic renders correctly; unit tests cover them. No tofu/LTR bug.
- **Progress engine** — pass threshold (>7), advance (>50% of frozen headcount), ledger
  idempotency, `record_tasmee` `on conflict do nothing`, monthly-close null-division guards —
  all correct and well-tested.
- **Curriculum-end advance** — NOT a bug: portions are teacher-entered surah/ayah ranges
  (`setCurrentPortion`/`_insertPortion`), not a fixed list, so there is no "past last portion"
  state. Verify only.
- **`household_member`** — has only `unique(household_id, person_id)`, **no** global
  `unique(person_id)`; a guardian may belong to multiple households.

## P0 — Dead-ends & data loss

1. **Parent locked out by the Family flow.** CONFIRMED · blocker ·
   `mobile/lib/features/family/data/family_repository.dart:47-67`. `createGuardianAndLink`
   inserts `person` + `role_assignment('parent')` + `guardian_link` but **never** inserts a
   `household_member`. The parent portal is gated by `my_subscription_active()` →
   `person_has_active_subscription()`, which requires household membership + a current payment.
   A parent created via Family therefore hits the paywall permanently (an admin *can* fix it via
   Subscriptions → Household Members, but nothing signals that's required).
   **Fix:** atomic `create_guardian_with_household(...)` RPC + household pick/create in the UI +
   show household/subscription status on the links list.

2. **Silent sync data loss.** CONFIRMED · major ·
   `mobile/lib/core/sync/outbox_processor.dart:46-54`. Permanently-failed tasmee/attendance
   writes are dead-lettered correctly (good FIFO handling) but nothing surfaces it — `LocalDb`
   has `pendingCount()` yet it is never shown, and there is no dead-letter query at all. A
   teacher can lose a grade and never know.
   **Fix:** expose pending + dead-letter counts; sync badge/banner + a "sync status" sheet with
   **retry** (requeue).

## P1 — Crash hardening & data hygiene

3. **Eval-circles shows no teacher name.** CONFIRMED · major ·
   `supervisor_eval_repository.dart:28`. `fetchAllCircles` selects `teacher_id` but no
   `teacher:teacher_id(full_name)` join, while `eval_circles_screen.dart` renders
   `c.teacherName` → always blank.
4. **Null-join force-unwraps crash on null embed.** CONFIRMED · major ·
   `supervisor_eval_repository.dart:41` & `:164`, `struggling_student.dart:11-12`,
   `pending_excuse.dart:13`/`:16`, plus parent/feedback repos. `r['student'] as Map<..>`
   (non-nullable) throws if RLS/embed returns null.
5. **Enum `fromDb` silently mislabels unknown server values.** CONFIRMED · medium ·
   `attendance_status.dart`, `tasmee_kind.dart`, `ledger_state.dart`, `certificate_kind.dart`.
   Unknown → a real default (attendance→`present`, etc.). Map to explicit `unknown` + log.
6. **Teacher-docs upload unsafe.** CONFIRMED · high ·
   `teacher_docs_repository.dart:37`. `currentUser!` force-unwrap; no try/catch around
   `uploadBinary`+insert (orphaned file on failure); no size limit.
7. **Video upload accepted but never processed.** CONFIRMED · medium ·
   `media_repository.dart` — video type accepted, watermark/processing skipped (no ffmpeg),
   silent no-op. Block clearly or accept-without-watermark.

## Navigation (keep 4-tab shell)

8. **Duplicate routes** `/teacher/circles`, `/supervisor/eval`, `/parent/children` all re-render
   `PrimaryTabScreen` (`app_router.dart:184/228/283`); reached via More/quick-actions they push
   onto the root navigator and break the back-stack + bottom-nav highlight. CONFIRMED · major.
9. `go` vs `push` inconsistency on dashboard stats. CONFIRMED · minor.
10. Admin's core task (enroll) is **6+ taps** vs 3 for other roles. CONFIRMED · medium.
11. Theme picker lives only in More, not Settings. CONFIRMED · minor.

## Icons & RTL

12. **RTL chevron direction.** CONFIRMED · major · `app_list_card.dart:57` (+ notifications,
    child card, household tile, debt strip, onboarding). `Icons.chevron_left` used as the
    "open/next" affordance points the wrong way in an Arabic RTL UI.
13. Attendance "absent" uses `Icons.cancel` (reads as delete) → `person_off`; `check`/
    `check_circle` and `groups`/`groups_outlined` mixed; behavioral-note icon inconsistent;
    skeleton `Icons.circle` placeholder. CONFIRMED · medium. No central icon definitions exist.
14. **RTL layout bugs.** CONFIRMED · medium. Hardcoded `EdgeInsets.fromLTRB` / `.only(left:/
    right:)` in dashboard/more-hub/sheets; `login_screen.dart` forces `TextDirection.ltr`.

## UX polish

15. Missing success snackbars after create/save (admin-setup sheets, competitions, courses,
    subscriptions). CONFIRMED · major.
16. No confirmation on destructive actions (logout, excuse approve/reject, session close).
    CONFIRMED · major.
17. Silent form-validation failures (submit does nothing, no error). CONFIRMED · major.
18. Submit buttons not disabled while saving → double-submit risk. CONFIRMED · minor.
19. Inconsistent empty-state CTAs, skeletons, error+retry. Accessibility gaps (icon-only buttons
    without semantics/tooltips). CONFIRMED · minor.
20. **Unbounded list queries** (no `.limit`/`.range`): complaints inbox & mine, excuse queue,
    monthly-eval approval, teacher-dev queue, waiting list, struggling students, teacher ratings.
    CONFIRMED · medium (scale risk).

## Feature-layer gaps

21. **No push delivery.** CONFIRMED · major. No FCM/device-token/realtime; server inserts
    `notification` rows but users only see them by opening the app and pull-to-refreshing; the
    unread badge doesn't update live.
22. **No self-serve payment.** CONFIRMED · by-design. Subscriptions exist only when an admin
    records them; a parent cannot pay in-app and cannot even see their own status/history.
23. **Settings is minimal** (theme/text-size/contrast + logout). No account management (change
    password, edit profile), no notification preferences, no about/version. CONFIRMED.
24. **Localization** — Arabic-only with ~20 user-facing strings hardcoded in Dart (errors in
    `app_exception.dart`, PDF labels, enum fallbacks) bypassing the l10n system. CONFIRMED.
25. **Auth** has only `signIn`/`signOut` — no password reset (`auth_repository.dart`). CONFIRMED.

## Test coverage

Engine/scoring/outbox-processor/PDF are tested. Largely **untested**: data-layer repositories,
monthly-close cron, RLS boundaries (`teaches_circle`, `is_guardian_of`), excuse/intake/family
flows, outbox dead-letter+requeue.

## Decisions taken (this audit → fix plan)

- Family flow assigns a household atomically (paywall stays). Offline boundary = attendance +
  tasmee + notes + session-close (advance stays online). Sync failures get a persistent
  indicator + retry. Auth: admin-invite + add password reset. Nav: keep 4-tab shell, fix
  inconsistencies. Icons: central `app_icons.dart` + RTL fixes. Full RTL sweep. Polish: all
  four (feedback, states, motion, a11y). Push: full FCM + live badge, **Android this round**,
  precise deep-links via entity ids on `notification`. Payments: keep admin-recorded, add
  parent-visible status/history. Settings: add about/edit-profile/notification-prefs.
  Localization: move hardcoded strings into l10n, stay Arabic-only. Broad test backfill.

## Delivery

New branch off the real trunk (`feat/mobile-flow-audit-fixes`), one PR per phase.
- **M1 Stabilize:** audit + foundations, P0, P1, navigation, icons+RTL, polish+pagination,
  localization hygiene.
- **M2 Features:** settings/account, password reset, FCM push (Android) + deep-links + live
  badge, parent payment visibility.
- **M3 Offline + motion:** motion/transitions, full teacher-loop offline.
