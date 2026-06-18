-- Phase 13 — كورسات مجانية للعامة + توسيع التسجيل العام (موافقة + موبايل مطبّع).
-- الصفحة العامة (Flutter Web) + cron حذف TTL = نشر خارجي مؤجّل.
-- بيتطبّق عبر MCP/CLI. مفيش تعديل هدّام.

create table public.course (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  video_url text not null,
  description text,
  is_free boolean not null default true,
  created_at timestamptz not null default now()
);

alter table public.public_registration
  add column consent_ack boolean not null default false;
alter table public.public_registration
  add column normalized_phone text;
update public.public_registration
  set normalized_phone = regexp_replace(phone, '\D', '', 'g')
  where normalized_phone is null;

alter table public.course enable row level security;

-- الكورسات المجانية: anon + authenticated يقروا (يدعم الصفحة العامة)؛ الأدمن يدير.
create policy course_public_read on public.course
  for select to anon, authenticated
  using (is_free);
create policy course_admin_all on public.course
  for all to authenticated
  using (public.is_super_admin() or public.is_admin())
  with check (public.is_super_admin() or public.is_admin());
