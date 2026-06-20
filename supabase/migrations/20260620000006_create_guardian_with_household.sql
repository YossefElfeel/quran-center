-- إصلاح الطريق المسدود لولي الأمر: إنشاء ولي أمر + ربطه بطفل + ضمّه لأسرة
-- (household) في معاملة واحدة ذرّية.
--
-- المشكلة: التدفّق القديم (createGuardianAndLink) كان بيعمل person + دور parent +
-- guardian_link بس **من غير** household_member. وبوابة المتابعة بتتحكم بـ
-- person_has_active_subscription اللي بتتطلّب عضوية أسرة + دفعة الشهر الحالي،
-- فولي الأمر اللي اتعمل كده بيتقفل بره البوابة للأبد. الدالة دي بتضيف العضوية
-- الناقصة، فالأدمن يقدر يختار أسرة موجودة (أو يعمل جديدة) في نفس الخطوة.
--
-- كمان بتصلح إن ولي الأمر كان بيتسجّل is_minor=true (الافتراضي) — دلوقتي بالغ.
-- SECURITY DEFINER عشان تكتب عبر الجداول بثبات (تتخطّى RLS) مع فحص أدمن صريح.
-- بيتطبّق عبر MCP/CLI. مفيش تعديل هدّام.

create or replace function public.create_guardian_with_household(
  p_guardian_name text,
  p_child_person_id uuid,
  p_relation text,
  p_household_id uuid default null,
  p_new_household_name text default null
) returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_guardian uuid;
  v_household uuid;
begin
  if not (private.is_admin() or private.is_super_admin()) then
    raise exception 'only admins can create guardians' using errcode = '42501';
  end if;
  if coalesce(btrim(p_guardian_name), '') = '' then
    raise exception 'guardian name required' using errcode = '22023';
  end if;

  -- الأسرة: استخدم الموجودة أو اعمل واحدة جديدة (الاسم الجديد أو اسم ولي الأمر).
  if p_household_id is not null then
    v_household := p_household_id;
    if not exists (select 1 from public.household h where h.id = v_household) then
      raise exception 'household not found' using errcode = '23503';
    end if;
  else
    insert into public.household (name)
    values (
      coalesce(nullif(btrim(p_new_household_name), ''), btrim(p_guardian_name))
    )
    returning id into v_household;
  end if;

  -- ولي الأمر: شخص بالغ + دور parent.
  insert into public.person (full_name, is_minor)
  values (btrim(p_guardian_name), false)
  returning id into v_guardian;

  insert into public.role_assignment (person_id, role)
  values (v_guardian, 'parent');

  insert into public.guardian_link (guardian_person_id, student_person_id, relation)
  values (v_guardian, p_child_person_id, p_relation);

  -- الإصلاح الأساسي: ضمّ ولي الأمر للأسرة كـ guardian.
  insert into public.household_member (household_id, person_id, role)
  values (v_household, v_guardian, 'guardian');

  return v_guardian;
end;
$$;

revoke all on function public.create_guardian_with_household(text, uuid, text, uuid, text)
  from public, anon;
grant execute on function public.create_guardian_with_household(text, uuid, text, uuid, text)
  to authenticated;
