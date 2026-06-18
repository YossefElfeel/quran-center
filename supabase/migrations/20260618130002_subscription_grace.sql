-- Phase 6 (مراجعة) — دوال البوابة تحترم فترة السماح + الدفع المقدّم،
-- عشان تطابق منطق الدومين (نشط/سماح = وصول مسموح).
--   نشط لو فيه دفعة غير ملغاة للشهر الحالي أو شهر بعده،
--   أو دفعة للشهر اللي فات وإحنا لسه في أول ٧ أيام (سماح).

create or replace function public.household_has_active_subscription(
  p_household_id uuid
) returns boolean
language sql
security invoker
set search_path = ''
stable
as $$
  select exists (
    select 1 from public.subscription_payment sp
    where sp.household_id = p_household_id
      and sp.voided = false
      and (
        sp.period_month >= date_trunc('month', current_date)::date
        or (
          sp.period_month
            = (date_trunc('month', current_date) - interval '1 month')::date
          and extract(day from current_date) <= 7
        )
      )
  );
$$;

create or replace function public.person_has_active_subscription(
  p_person_id uuid
) returns boolean
language sql
security invoker
set search_path = ''
stable
as $$
  select exists (
    select 1
    from public.household_member hm
    join public.subscription_payment sp on sp.household_id = hm.household_id
    where hm.person_id = p_person_id
      and sp.voided = false
      and (
        sp.period_month >= date_trunc('month', current_date)::date
        or (
          sp.period_month
            = (date_trunc('month', current_date) - interval '1 month')::date
          and extract(day from current_date) <= 7
        )
      )
  );
$$;
