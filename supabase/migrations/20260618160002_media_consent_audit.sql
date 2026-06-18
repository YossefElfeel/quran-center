-- Phase 7a — الوسائط + الموافقة + التدقيق.
-- وسائط البنات تتطلب موافقة ولي الأمر (opt-in)؛ وسائط الأولاد عادية.
-- مصدر الموافقة الوحيد = consent_record. كل وصول حسّاس يتسجّل في audit_log.
-- بيتطبّق عبر MCP/CLI. مفيش تعديل هدّام.
-- ملاحظة: سياسات media بتتحدّث في 160003 (إصلاح ثغرة الـ subquery).

create type public.media_type as enum ('photo', 'video');

-- ===== الموافقة (مصدر الحقيقة الوحيد) =====
create table public.consent_record (
  id uuid primary key default gen_random_uuid(),
  student_person_id uuid not null references public.person (id) on delete cascade,
  scope public.media_type not null,
  granted_by uuid not null default public.current_person_id()
    references public.person (id),
  granted_at timestamptz not null default now(),
  revoked_at timestamptz
);
create index consent_record_student_idx
  on public.consent_record (student_person_id);
create unique index consent_record_active_uniq
  on public.consent_record (student_person_id, scope)
  where revoked_at is null;

-- ===== الوسائط =====
create table public.media (
  id uuid primary key default gen_random_uuid(),
  student_person_id uuid not null references public.person (id) on delete cascade,
  type public.media_type not null,
  storage_path text not null,
  watermarked boolean not null default false,
  retained boolean not null default true,
  uploaded_by uuid references public.person (id),
  created_at timestamptz not null default now()
);
create index media_student_idx on public.media (student_person_id, created_at desc);

-- ===== سجل التدقيق =====
create table public.audit_log (
  id uuid primary key default gen_random_uuid(),
  actor_person_id uuid references public.person (id),
  action text not null,
  target_table text,
  target_id uuid,
  meta jsonb not null default '{}'::jsonb,
  at timestamptz not null default now()
);
create index audit_log_at_idx on public.audit_log (at desc);

-- ===== دوال =====
create or replace function public.has_active_media_consent(
  p_student uuid, p_type public.media_type
) returns boolean
language sql stable security definer set search_path = ''
as $$
  select exists (
    select 1 from public.consent_record cr
    where cr.student_person_id = p_student
      and cr.scope = p_type
      and cr.revoked_at is null
  );
$$;
revoke all on function public.has_active_media_consent(uuid, public.media_type)
  from public, anon;
grant execute on function public.has_active_media_consent(uuid, public.media_type)
  to authenticated;

create or replace function public.log_media_access(p_media_id uuid)
returns void
language plpgsql security definer set search_path = ''
as $$
declare v_student uuid;
begin
  select student_person_id into v_student from public.media where id = p_media_id;
  insert into public.audit_log (actor_person_id, action, target_table, target_id, meta)
  values (public.current_person_id(), 'media_access', 'media', p_media_id,
          jsonb_build_object('student_person_id', v_student));
end;
$$;
revoke all on function public.log_media_access(uuid) from public, anon;
grant execute on function public.log_media_access(uuid) to authenticated;

-- bucket خاص (الوصول عبر signed URLs من Edge Function سيرفر-سايد).
insert into storage.buckets (id, name, public)
values ('media', 'media', false)
on conflict (id) do nothing;

-- ===== RLS =====
alter table public.consent_record enable row level security;
alter table public.media enable row level security;
alter table public.audit_log enable row level security;

create policy consent_read on public.consent_record
  for select to authenticated
  using (
    public.is_super_admin() or public.is_admin() or public.is_supervisor()
    or public.is_guardian_of(student_person_id)
  );
create policy consent_insert on public.consent_record
  for insert to authenticated
  with check (
    public.is_guardian_of(student_person_id)
    and granted_by = public.current_person_id()
  );
create policy consent_update on public.consent_record
  for update to authenticated
  using (public.is_guardian_of(student_person_id))
  with check (public.is_guardian_of(student_person_id));

create policy media_read on public.media
  for select to authenticated
  using (
    public.is_super_admin() or public.is_admin() or public.is_supervisor()
    or exists (
      select 1 from public.enrollment e
      where e.student_person_id = media.student_person_id
        and public.teaches_circle(e.circle_id)
    )
    or (
      public.is_guardian_of(media.student_person_id)
      and (
        (select p.gender from public.person p where p.id = media.student_person_id)
          is distinct from 'female'::public.gender
        or public.has_active_media_consent(media.student_person_id, media.type)
      )
    )
  );
create policy media_write on public.media
  for all to authenticated
  using (
    public.is_super_admin() or public.is_admin()
    or exists (
      select 1 from public.enrollment e
      where e.student_person_id = media.student_person_id
        and public.teaches_circle(e.circle_id)
    )
  )
  with check (
    (
      public.is_super_admin() or public.is_admin()
      or exists (
        select 1 from public.enrollment e
        where e.student_person_id = media.student_person_id
          and public.teaches_circle(e.circle_id)
      )
    )
    and (
      (select p.gender from public.person p where p.id = media.student_person_id)
        is distinct from 'female'::public.gender
      or public.has_active_media_consent(media.student_person_id, media.type)
    )
  );

create policy audit_read on public.audit_log
  for select to authenticated
  using (public.is_super_admin() or public.is_admin());
