-- M4.6: daily reminder for households whose monthly subscription is overdue.
-- Overdue = "now" is past the grace window (subscription_grace_days after the 1st of
-- the current month) AND no non-voided payment exists for the current period month.
-- Guardians get one in-app notice per (household, month); idempotency is tracked in
-- subscription_overdue_notice.

create table if not exists public.subscription_overdue_notice (
  household_id uuid not null references public.household(id) on delete cascade,
  period_month date not null,
  notified_at timestamptz not null default now(),
  primary key (household_id, period_month)
);
-- System-only table (no policies => deny-all for API roles; cron writes via definer).
alter table public.subscription_overdue_notice enable row level security;

create or replace function public.notify_overdue_subscriptions()
returns integer
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_grace int;
  v_period date := date_trunc('month', now())::date;
  v_count int := 0;
  v_household uuid;
begin
  select coalesce((select value::int from public.system_settings
                   where key = 'subscription_grace_days'), 7)
    into v_grace;

  for v_household in
    select h.id
    from public.household h
    where now()::date > (v_period + (v_grace || ' days')::interval)::date
      and coalesce((
            select max(sp.period_month)
            from public.subscription_payment sp
            where sp.household_id = h.id and sp.voided = false
          ), 'epoch'::date) < v_period
      and not exists (
            select 1 from public.subscription_overdue_notice n
            where n.household_id = h.id and n.period_month = v_period
          )
  loop
    insert into public.notification (recipient_person_id, type, title, body)
    select hm.person_id, 'subscription_overdue', 'الاشتراك متأخّر',
           'اشتراك الشهر ده لسه متدفعش. لو سمحت سدّد عشان تكمّل المتابعة في التطبيق.'
    from public.household_member hm
    where hm.household_id = v_household and hm.role = 'guardian';

    insert into public.subscription_overdue_notice (household_id, period_month)
    values (v_household, v_period);

    v_count := v_count + 1;
  end loop;
  return v_count;
end;
$$;

revoke all on function public.notify_overdue_subscriptions() from public, anon, authenticated;

select cron.schedule(
  'notify-overdue-subscriptions',
  '0 6 * * *',
  $cron$ select public.notify_overdue_subscriptions(); $cron$
);
