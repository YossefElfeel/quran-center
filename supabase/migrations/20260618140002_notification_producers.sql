-- Phase 7 — موصّلات الإشعارات (triggers سيرفر-سايد، SECURITY DEFINER).
-- بتولّد إشعارات in-app من أحداث حقيقية. SECURITY DEFINER عشان تكتب لأي
-- مستلِم بثبات (تتخطّى سياسة الإدراج)، مع search_path='' للأمان.
-- بيتطبّق عبر MCP/CLI. مفيش تعديل هدّام.

-- ===== (١) تقييم المشرف لطالب → أولياء أمره =====
-- بنطلق على معيار 'memorization' بس (صف واحد لكل طالب لكل تقييم) → إشعار واحد.
create or replace function public.notify_guardians_on_eval()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_child_name text;
begin
  if new.criterion <> 'memorization' then
    return new;
  end if;
  select full_name into v_child_name
    from public.person where id = new.student_person_id;
  insert into public.notification (recipient_person_id, type, title, body)
  select gl.guardian_person_id, 'supervisor_eval', 'تقييم المشرف متاح',
         'في تقييم جديد من المشرف لـ ' || coalesce(v_child_name, 'ابنك')
  from public.guardian_link gl
  where gl.student_person_id = new.student_person_id;
  return new;
end;
$$;

create trigger eval_score_notify_guardians
  after insert on public.eval_score
  for each row execute function public.notify_guardians_on_eval();

-- ===== (٢) انتقال الحلقة لمقطع جديد → المشرفين =====
-- أول دورة للحلقة = بداية مش انتقال → نطلق بس لو فيه دورة سابقة.
create or replace function public.notify_supervisors_on_advance()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_circle_name text;
begin
  if not exists (
    select 1 from public.group_portion_cycle gpc
    where gpc.circle_id = new.circle_id and gpc.id <> new.id
  ) then
    return new;
  end if;
  select name into v_circle_name from public.circle where id = new.circle_id;
  insert into public.notification (recipient_person_id, type, title, body)
  select ra.person_id, 'advance', 'انتقال حلقة',
         'حلقة ' || coalesce(v_circle_name, '') || ' اتنقلت للمقطع الجديد'
  from public.role_assignment ra
  where ra.role = 'supervisor';
  return new;
end;
$$;

create trigger gpc_notify_supervisors
  after insert on public.group_portion_cycle
  for each row execute function public.notify_supervisors_on_advance();

-- ===== (٣) تعثّر الطالب → المعلّم + المشرفين + أولياء الأمر =====
-- بيطلق مرة واحدة لما الدفتر يعدّي ٣ محاولات وهو لسه راسب (failed_retry).
create or replace function public.notify_on_struggling()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_child_name text;
  v_body text;
begin
  if not (
    new.state = 'failed_retry'
    and new.attempts_count >= 3
    and old.attempts_count < 3
  ) then
    return new;
  end if;
  select full_name into v_child_name
    from public.person where id = new.student_person_id;
  v_body := coalesce(v_child_name, 'الطالب')
            || ' متعثّر — رسب ٣ مرات في نفس المقطع';
  insert into public.notification (recipient_person_id, type, title, body)
  select distinct r.person_id, 'struggling', 'طالب متعثّر', v_body
  from (
    select gl.guardian_person_id as person_id
      from public.guardian_link gl
      where gl.student_person_id = new.student_person_id
    union
    select ra.person_id
      from public.role_assignment ra where ra.role = 'supervisor'
    union
    select c.teacher_id
      from public.enrollment e
      join public.circle c on c.id = e.circle_id
      where e.student_person_id = new.student_person_id
        and e.status = 'active'
        and c.teacher_id is not null
  ) r;
  return new;
end;
$$;

create trigger ledger_notify_struggling
  after update on public.portion_ledger_entry
  for each row execute function public.notify_on_struggling();

-- ===== (٤) ملاحظة سلوك ظاهرة لولي الأمر → أولياء الأمر =====
create or replace function public.notify_guardians_on_note()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_child_name text;
begin
  if new.visibility <> 'parent' then
    return new;
  end if;
  select full_name into v_child_name
    from public.person where id = new.student_person_id;
  insert into public.notification (recipient_person_id, type, title, body)
  select gl.guardian_person_id, 'behavior_note', 'ملاحظة جديدة',
         'في ملاحظة جديدة عن ' || coalesce(v_child_name, 'ابنك')
  from public.guardian_link gl
  where gl.student_person_id = new.student_person_id;
  return new;
end;
$$;

create trigger behavioral_note_notify_guardians
  after insert on public.behavioral_note
  for each row execute function public.notify_guardians_on_note();

-- دوال الـ triggers مش RPCs — اسحب التنفيذ من العامة/المصرّح لهم (advisor 0029).
revoke all on function public.notify_guardians_on_eval() from public, anon, authenticated;
revoke all on function public.notify_supervisors_on_advance() from public, anon, authenticated;
revoke all on function public.notify_on_struggling() from public, anon, authenticated;
revoke all on function public.notify_guardians_on_note() from public, anon, authenticated;
