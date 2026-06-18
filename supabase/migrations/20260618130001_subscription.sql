-- Phase 6 — اشتراك الأسرة (كاش) + دوال "اشتراك نشط؟" لبوابة وصول ولي الأمر.
-- الحالة تُشتق من الدفعات (append-only)؛ الدوال بترجّع نشط/لأ للبوابة.
-- بيتطبّق عبر MCP/CLI. مفيش تعديل هدّام.

create table public.household (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  monthly_amount numeric(8, 2) not null default 10,
  created_at timestamptz not null default now()
);

create table public.household_member (
  id uuid primary key default gen_random_uuid(),
  household_id uuid not null references public.household (id) on delete cascade,
  person_id uuid not null references public.person (id) on delete cascade,
  role text not null check (role in ('guardian', 'student')),
  created_at timestamptz not null default now(),
  unique (household_id, person_id)
);
create index household_member_person_idx
  on public.household_member (person_id);

-- دفعات الاشتراك (append-only؛ الإلغاء سطر voided مش حذف).
create table public.subscription_payment (
  id uuid primary key default gen_random_uuid(),
  household_id uuid not null references public.household (id) on delete cascade,
  amount numeric(8, 2) not null check (amount >= 0),
  period_month date not null,
  paid_at timestamptz not null default now(),
  recorded_by uuid references public.person (id),
  receipt_no text,
  voided boolean not null default false,
  void_reason text,
  created_at timestamptz not null default now()
);
create index subscription_payment_household_idx
  on public.subscription_payment (household_id);

-- ===== دوال البوابة =====
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
      and sp.period_month = date_trunc('month', current_date)::date
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
      and sp.period_month = date_trunc('month', current_date)::date
  );
$$;

revoke all on function public.household_has_active_subscription(uuid)
  from public, anon;
grant execute on function public.household_has_active_subscription(uuid)
  to authenticated;
revoke all on function public.person_has_active_subscription(uuid)
  from public, anon;
grant execute on function public.person_has_active_subscription(uuid)
  to authenticated;

-- ===== RLS (مفيش recursion: السياسات بتلمس household_member المفلتر بالشخص الحالي) =====
alter table public.household enable row level security;
alter table public.household_member enable row level security;
alter table public.subscription_payment enable row level security;

create policy household_admin_all on public.household
  for all to authenticated
  using (public.is_super_admin() or public.is_admin())
  with check (public.is_super_admin() or public.is_admin());
create policy household_member_read on public.household
  for select to authenticated
  using (
    exists (
      select 1 from public.household_member hm
      where hm.household_id = household.id
        and hm.person_id = public.current_person_id()
    )
  );

create policy hmember_admin_all on public.household_member
  for all to authenticated
  using (public.is_super_admin() or public.is_admin())
  with check (public.is_super_admin() or public.is_admin());
create policy hmember_self_read on public.household_member
  for select to authenticated
  using (person_id = public.current_person_id());

create policy payment_admin_all on public.subscription_payment
  for all to authenticated
  using (public.is_super_admin() or public.is_admin())
  with check (public.is_super_admin() or public.is_admin());
create policy payment_member_read on public.subscription_payment
  for select to authenticated
  using (
    exists (
      select 1 from public.household_member hm
      where hm.household_id = subscription_payment.household_id
        and hm.person_id = public.current_person_id()
    )
  );
