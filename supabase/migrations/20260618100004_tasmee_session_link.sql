-- Phase 4 — ربط التسميع بالحصة اللي اتسجّل فيها (اختياري، nullable).
alter table public.daily_tasmee
  add column session_id uuid references public.circle_session (id) on delete set null;
create index daily_tasmee_session_idx on public.daily_tasmee (session_id);
