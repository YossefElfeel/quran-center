# Deploy — M6 Super-Admin Control Center

Code is merged to `dev`/`main`, but the **live Supabase project `quzqenavfoqsjupbtiix` ("Quran") is NOT yet updated**. The dashboard's privileged features (block/delete/roles, data console, new RLS) will error until the steps below are done.

## Verified (read-only, 2026-06-20)
Against live `quzqenavfoqsjupbtiix`:
- Lifecycle columns (`person.blocked_at` …) **not present** → `0006` applies fresh.
- All 10 `private.*` helper functions **present** → `0007` recreates/gates them; `enforce_last_super_admin` trigger **absent** (added by `0007`).
- `public.media_write` policy is **byte-for-byte the repo version** → `0010`'s drop+recreate is safe.
- `audit_admin_insert` / `notification_admin_delete` / `notification_admin_read` policies **absent** → `0008`/`0009` apply cleanly.
- **No drift conflicts** with the 5 migrations.

> ⚠️ Do **NOT** run `supabase db push`. The live migration history uses different version timestamps than the repo filenames, so a full diff would try to re-apply already-applied migrations and conflict. **Apply only the 5 new migrations below, individually.**

## 1. Prerequisite (manual, you must do this)
Rotate the previously-exposed **service-role key**: Supabase Dashboard → Project Settings → API → `service_role` → Reset. Update any place that stores it. (Edge functions read it from the runtime env, injected by Supabase — no code change needed.)

## 2. Apply the 5 migrations — in order
Run each file's SQL in **Studio → SQL Editor** (or have the agent apply via MCP `apply_migration` with your explicit go-ahead). Order matters (`0006` before `0007`):
1. `supabase/migrations/20260619000006_person_lifecycle_block_delete.sql`
2. `supabase/migrations/20260619000007_rls_helpers_enforce_active_person.sql`
3. `supabase/migrations/20260619000008_audit_log_admin_insert.sql`
4. `supabase/migrations/20260619000009_notification_admin_delete.sql`
5. `supabase/migrations/20260619000010_media_write_admin_consent_fix.sql`

## 3. Verify (run on the live DB; each is a rolled-back DO-block)
- `supabase/tests/rls_isolation.sql` → must end with `RLS OK …` (raised as an error = success; it rolls back).
- `supabase/tests/role_guardrails.sql` → must end with `GUARDRAILS OK …`.

## 4. Deploy the 4 edge functions
`supabase functions deploy block-user delete-user manage-role data-console-write`
(or via MCP `deploy_edge_function`, `verify_jwt=true`). Each verifies the caller is an active super_admin internally. Secrets `SUPABASE_URL` / `SUPABASE_ANON_KEY` / `SUPABASE_SERVICE_ROLE_KEY` are auto-injected.

## 5. (optional) Regenerate dashboard types
Run `generate_typescript_types` if you add `dashboard/lib/database.types.ts`.

---
The agent can do steps 2–4 via MCP if you explicitly authorize a production write (e.g. "apply the 5 M6 migrations + deploy the edge functions to the Quran project"). Step 1 (key rotation) is dashboard-only and must be done by you.
