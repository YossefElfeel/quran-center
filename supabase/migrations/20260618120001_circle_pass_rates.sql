-- Phase 5 (تحسين) — نسبة نجاح كل حلقة على مقطعها الحالي (للوحة "محتاج انتباه").
-- security invoker: الـ RLS بتتطبّق على اللي بينده (المشرف يشوف كل الحلقات).
-- المقام = المقام المجمّد للدورة المفتوحة؛ البسط = اللي عدّوا المقطع من النشطين.
create or replace function public.circle_pass_rates()
returns table (
  circle_id uuid,
  circle_name text,
  active_at_open integer,
  passed_count integer,
  pass_rate numeric
)
language sql
security invoker
set search_path = ''
as $$
  select
    c.id,
    c.name,
    coalesce(gpc.active_at_open, 0)::integer,
    coalesce(p.cnt, 0)::integer,
    case
      when coalesce(gpc.active_at_open, 0) > 0
        then round(coalesce(p.cnt, 0)::numeric / gpc.active_at_open, 3)
      else null
    end
  from public.circle c
  left join public.group_portion_cycle gpc
    on gpc.circle_id = c.id and gpc.advanced_at is null
  left join lateral (
    select count(*)::integer as cnt
    from public.portion_ledger_entry ple
    join public.enrollment e
      on e.student_person_id = ple.student_person_id
      and e.circle_id = c.id
      and e.status = 'active'
    where gpc.portion_id is not null
      and ple.portion_id = gpc.portion_id
      and ple.state = 'passed'
  ) p on true
  order by pass_rate asc nulls last, c.name;
$$;

revoke all on function public.circle_pass_rates() from public, anon;
grant execute on function public.circle_pass_rates() to authenticated;
