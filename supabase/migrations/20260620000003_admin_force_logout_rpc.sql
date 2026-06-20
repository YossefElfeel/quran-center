-- God-mode M4 — تسجيل خروج إجباري لمستخدم (سوبر أدمن فقط، مدقّق).
-- بيمسح كل جلسات المستخدم من auth.sessions (بتسحب refresh tokens بالـ cascade)، فمايقدرش
-- يجدّد التوكن؛ التوكن الحالي (≤ساعة) بيخلص لوحده. أخفّ من الحظر (مابيمنعش الدخول تاني).
-- SECURITY DEFINER عشان يقدر يلمس schema auth. البوّابة جوّه الدالة (سوبر أدمن).
create or replace function public.admin_force_logout(p_person uuid, p_reason text)
  returns jsonb language plpgsql security definer set search_path = '' as $$
declare
  v_uid uuid;
  v_count int;
  v_actor uuid := private.current_person_id();
begin
  if not private.is_super_admin() then
    raise exception 'forbidden' using errcode = '42501';
  end if;
  if coalesce(trim(p_reason), '') = '' then
    raise exception 'reason required' using errcode = '22023';
  end if;

  select auth_user_id into v_uid from public.app_user where person_id = p_person;
  if v_uid is null then
    raise exception 'subject has no login account' using errcode = 'P0002';
  end if;

  delete from auth.sessions where user_id = v_uid;
  get diagnostics v_count = row_count;

  insert into public.audit_log (actor_person_id, action, target_table, target_id, meta)
  values (v_actor, 'force_logout', 'person', p_person,
          jsonb_build_object('reason', p_reason, 'sessions_revoked', v_count));

  return jsonb_build_object('ok', true, 'sessions_revoked', v_count);
end;
$$;

revoke all on function public.admin_force_logout(uuid, text) from public, anon;
grant execute on function public.admin_force_logout(uuid, text) to authenticated;
