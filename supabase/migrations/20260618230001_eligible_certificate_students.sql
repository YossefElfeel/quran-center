-- M1.5 — قائمة الطلبة المؤهّلين لشهادة إتمام (نفس منطق is_certificate_eligible):
-- عدّوا مقطع واحد على الأقل ومفيش أي مقطع لسه مش passed. للمشرف/الأدمن لشاشة الإصدار.
-- بيتطبّق عبر MCP/CLI. مفيش تعديل هدّام.
create or replace function public.eligible_certificate_students()
returns table(id uuid, full_name text)
language sql stable security definer set search_path = ''
as $$
  select p.id, p.full_name
  from public.person p
  where exists (
    select 1 from public.portion_ledger_entry l
    where l.student_person_id = p.id and l.state = 'passed'
  ) and not exists (
    select 1 from public.portion_ledger_entry l
    where l.student_person_id = p.id and l.state <> 'passed'
  )
  order by p.full_name;
$$;
revoke all on function public.eligible_certificate_students() from public, anon;
grant execute on function public.eligible_certificate_students() to authenticated;
