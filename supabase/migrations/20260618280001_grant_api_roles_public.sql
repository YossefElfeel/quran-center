-- Table-level grants for the PostgREST API roles on `public`.
--
-- Supabase's posture: grant coarse table DML to anon/authenticated and let RLS do
-- the row-level gating. On the hosted project these grants come from Supabase's
-- ambient default privileges (configured for the admin role at project setup), so
-- they were never in a migration. A fresh `supabase db reset` applies migrations
-- as `postgres`, whose newly-created tables don't inherit those defaults — leaving
-- `authenticated` without even SELECT (the RLS CI suite hit "permission denied for
-- table enrollment"). Grant explicitly so the committed schema reproduces the
-- hosted access model from scratch. Idempotent; redundant (no-op) on hosted.
--
-- Tables + sequences ONLY — deliberately NOT routines, to preserve the
-- function-execute lockdown from 20260617090009 / the private-schema move
-- (security advisor 0029). RLS remains the real access gate; these grants just let
-- the API roles reach the tables so policies can filter rows.
grant select, insert, update, delete on all tables in schema public
  to authenticated, service_role;
grant select on all tables in schema public to anon;
grant usage, select on all sequences in schema public
  to anon, authenticated, service_role;
