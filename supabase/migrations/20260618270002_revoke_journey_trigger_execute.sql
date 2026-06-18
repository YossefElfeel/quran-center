-- The M5.2 journey trigger functions are SECURITY DEFINER but should never be callable
-- as a PostgREST RPC (advisor 0028/0029). They run only via their triggers, which do
-- not require EXECUTE on the function for the triggering role, so revoking is safe.
revoke all on function public.accrue_journey_on_ledger_pass() from public, anon, authenticated;
revoke all on function public.close_journey_on_enrollment_end() from public, anon, authenticated;
