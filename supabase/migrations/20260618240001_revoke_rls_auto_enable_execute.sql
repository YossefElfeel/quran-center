-- Security advisor 0028/0029: public.rls_auto_enable() is an event-trigger helper
-- (auto-enables RLS on newly created public tables). It must never be callable as
-- a PostgREST RPC by anon/authenticated. Revoke execute from the API roles; the
-- event-trigger firing is internal to Postgres and is unaffected by this.
revoke all on function public.rls_auto_enable() from public, anon, authenticated;
