-- pg_cron is enabled on the hosted project via the dashboard (Database >
-- Extensions), so it was never captured as a migration. A fresh `supabase db
-- reset` (RLS CI job) therefore lacked the `cron` schema and the scheduled-job
-- migrations (20260618240002+) failed with "schema cron does not exist".
-- Enable it here, before the first cron.schedule call. Idempotent — a no-op where
-- pg_cron is already installed (hosted). The Supabase Postgres image preloads
-- pg_cron in shared_preload_libraries, so the extension can be created.
create extension if not exists pg_cron;
