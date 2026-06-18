-- Phase 6 (batch 2a) — قايمة الأسر مع آخر شهر مدفوع (لعرض حالة الاشتراك للأدمن).
-- security invoker: الأدمن بيقرا كل الأسر والدفعات عبر RLS.
create or replace function public.households_with_status()
returns table (
  id uuid,
  name text,
  monthly_amount numeric,
  last_paid_month date
)
language sql
security invoker
set search_path = ''
stable
as $$
  select
    h.id,
    h.name,
    h.monthly_amount,
    (
      select max(sp.period_month)
      from public.subscription_payment sp
      where sp.household_id = h.id and sp.voided = false
    )
  from public.household h
  order by h.name;
$$;

revoke all on function public.households_with_status() from public, anon;
grant execute on function public.households_with_status() to authenticated;
