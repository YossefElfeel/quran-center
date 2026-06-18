-- M7: let the public site (anon) read OPEN competitions only — so the public page can
-- display the competition and submit via the submit-public-application Edge Function.
-- Non-open competitions stay hidden from anon; authenticated read is unchanged (comp_read).
create policy comp_public_read on public.competition
  for select to anon using (status = 'open');
