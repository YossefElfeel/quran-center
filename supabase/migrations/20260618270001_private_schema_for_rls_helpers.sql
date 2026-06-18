-- M2.3: move policy-only RLS helper functions to a non-API schema `private` to close
-- security advisor 0029 (SECURITY DEFINER functions exposed as PostgREST RPC). Uses
-- ALTER FUNCTION ... SET SCHEMA (OID preserved => existing policies keep binding, no
-- policy rewrite). Helper-to-helper and public-caller bodies are recreated to call
-- private.* . App RPCs that the client legitimately calls stay in public
-- (eligible_certificate_students, teacher_pass_rate, log_media_access,
-- my_subscription_active, record_tasmee, set_person_national_id, enroll_student, ...).
-- Verified by supabase/tests/rls_isolation.sql ("RLS OK") + get_advisors (0029 reduced
-- to only the intentional public RPCs).

create schema if not exists private;
grant usage on schema private to authenticated, anon;

-- 1) move the 16 policy helpers (OID preserved).
alter function public.current_person_id() set schema private;
alter function public.has_role(public.app_role) set schema private;
alter function public.has_active_media_consent(uuid, public.media_type) set schema private;
alter function public.is_admin() set schema private;
alter function public.is_super_admin() set schema private;
alter function public.is_supervisor() set schema private;
alter function public.is_teacher() set schema private;
alter function public.is_parent() set schema private;
alter function public.is_guardian_of(uuid) set schema private;
alter function public.is_guardian_of_enrollment(uuid) set schema private;
alter function public.teaches_circle(uuid) set schema private;
alter function public.teaches_enrollment(uuid) set schema private;
alter function public.is_competition_judge(uuid) set schema private;
alter function public.is_parent_of_teachers_student(uuid) set schema private;
alter function public.media_consent_ok(uuid, public.media_type) set schema private;
alter function public.is_certificate_eligible(uuid) set schema private;

-- 2) recreate the helpers whose bodies call other helpers, now via private.*
create or replace function private.is_admin() returns boolean language sql stable security definer set search_path = '' as $$ select private.has_role('admin'::public.app_role) $$;
create or replace function private.is_super_admin() returns boolean language sql stable security definer set search_path = '' as $$ select private.has_role('super_admin'::public.app_role) $$;
create or replace function private.is_supervisor() returns boolean language sql stable security definer set search_path = '' as $$ select private.has_role('supervisor'::public.app_role) $$;
create or replace function private.is_teacher() returns boolean language sql stable security definer set search_path = '' as $$ select private.has_role('teacher'::public.app_role) $$;
create or replace function private.is_parent() returns boolean language sql stable security definer set search_path = '' as $$ select private.has_role('parent'::public.app_role) $$;
create or replace function private.is_guardian_of_enrollment(target_enrollment uuid) returns boolean language sql stable security definer set search_path = '' as $$
  select exists (
    select 1 from public.enrollment e
    where e.id = target_enrollment and private.is_guardian_of(e.student_person_id)
  )
$$;
create or replace function private.media_consent_ok(p_student uuid, p_type public.media_type) returns boolean language sql stable security definer set search_path = '' as $$
  select (
    (select p.gender from public.person p where p.id = p_student) is distinct from 'female'::public.gender
    or private.has_active_media_consent(p_student, p_type)
  )
$$;

-- 3) recreate the public callers (triggers + RPCs) to call private.*
create or replace function public.enforce_certificate_eligibility() returns trigger language plpgsql set search_path = '' as $$
begin
  if new.kind <> 'honor' and not private.is_certificate_eligible(new.student_person_id) then
    raise exception 'student not eligible: must pass all portions with zero debt';
  end if;
  return new;
end;
$$;
create or replace function public.enforce_dev_approval() returns trigger language plpgsql set search_path = '' as $$
begin
  if new.status = 'approved' then
    if not (private.is_supervisor() or private.is_admin() or private.is_super_admin()) then
      raise exception 'only supervisor/admin can approve development';
    end if;
    new.approved_by := coalesce(new.approved_by, private.current_person_id());
    new.approved_at := coalesce(new.approved_at, now());
  end if;
  return new;
end;
$$;
create or replace function public.enforce_monthly_eval_approval() returns trigger language plpgsql security invoker set search_path = '' as $$
begin
  if new.status = 'approved' then
    if not (private.is_supervisor() or private.is_admin() or private.is_super_admin()) then
      raise exception 'only supervisor/admin can approve monthly evaluation';
    end if;
    new.approved_by := coalesce(new.approved_by, private.current_person_id());
    new.approved_at := coalesce(new.approved_at, now());
  end if;
  return new;
end;
$$;
create or replace function public.log_media_access(p_media_id uuid) returns void language plpgsql security definer set search_path = '' as $$
declare v_student uuid;
begin
  select student_person_id into v_student from public.media where id = p_media_id;
  insert into public.audit_log (actor_person_id, action, target_table, target_id, meta)
  values (private.current_person_id(), 'media_access', 'media', p_media_id,
          jsonb_build_object('student_person_id', v_student));
end;
$$;
create or replace function public.my_subscription_active() returns boolean language sql stable set search_path = '' as $$
  select public.person_has_active_subscription(private.current_person_id())
$$;
create or replace function public.set_person_national_id(p_person uuid, p_raw text) returns text language plpgsql security definer set search_path = '' as $$
declare v_norm text; v_pepper text; v_hmac text;
begin
  if not (private.is_admin() or private.is_supervisor() or private.is_super_admin()) then
    raise exception 'غير مصرّح بتسجيل الرقم القومي' using errcode = '42501';
  end if;
  v_norm := public.normalize_national_id(p_raw);
  if length(v_norm) <> 14 then
    raise exception 'الرقم القومي لازم يكون ١٤ رقم' using errcode = '22023';
  end if;
  select decrypted_secret into v_pepper from vault.decrypted_secrets where name = 'national_id_pepper';
  if v_pepper is null then raise exception 'national-id pepper not configured'; end if;
  v_hmac := encode(extensions.hmac(v_norm, v_pepper, 'sha256'), 'hex');
  update public.person
     set national_id_hmac = v_hmac,
         national_id_encrypted = extensions.pgp_sym_encrypt(v_norm, v_pepper),
         national_id_last4 = right(v_norm, 4)
   where id = p_person;
  if not found then raise exception 'الشخص مش موجود' using errcode = 'P0002'; end if;
  return right(v_norm, 4);
exception when unique_violation then
  raise exception 'الرقم القومي ده مسجّل قبل كده لشخص تاني' using errcode = '23505';
end;
$$;
create or replace function public.enroll_student(p_circle uuid, p_name text, p_gender text, p_national_id text default null) returns uuid language plpgsql security definer set search_path = '' as $$
declare v_person uuid;
begin
  if not (private.is_admin() or private.is_supervisor() or private.is_super_admin()) then
    raise exception 'غير مصرّح بتسجيل طالب' using errcode = '42501';
  end if;
  insert into public.person (full_name, gender, is_minor) values (p_name, p_gender::public.gender, true) returning id into v_person;
  insert into public.enrollment (student_person_id, circle_id, status) values (v_person, p_circle, 'active');
  if p_national_id is not null and length(trim(p_national_id)) > 0 then
    perform public.set_person_national_id(v_person, p_national_id);
  end if;
  return v_person;
end;
$$;

-- 4) ensure API roles can execute the private helpers (for policy evaluation). private
--    is NOT exposed by PostgREST, so this does NOT make them callable as RPC (closes 0029).
grant execute on all functions in schema private to authenticated, anon;
