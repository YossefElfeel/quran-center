-- Phase 7 — إشعارات داخل التطبيق (in-app). المستلِم يقرا ويعلّم مقروء؛
-- الطاقم بيبعت (dispatch). المنتِجات (تسميع/تعثّر/عذر/متأخّر...) تتوصّل لاحقًا.
-- بيتطبّق عبر MCP/CLI. مفيش تعديل هدّام.

create table public.notification (
  id uuid primary key default gen_random_uuid(),
  recipient_person_id uuid not null
    references public.person (id) on delete cascade,
  type text not null,
  title text not null,
  body text,
  read_at timestamptz,
  created_at timestamptz not null default now()
);
create index notification_recipient_idx
  on public.notification (recipient_person_id, read_at);

alter table public.notification enable row level security;

-- المستلِم يقرا إشعاراته بس.
create policy notification_read on public.notification
  for select to authenticated
  using (recipient_person_id = public.current_person_id());

-- المستلِم يعلّمها مقروءة بس (مايغيّرش مستلِم).
create policy notification_mark_read on public.notification
  for update to authenticated
  using (recipient_person_id = public.current_person_id())
  with check (recipient_person_id = public.current_person_id());

-- الطاقم يقدر ينشئ إشعارات (توصيل).
create policy notification_staff_insert on public.notification
  for insert to authenticated
  with check (
    public.is_super_admin() or public.is_admin()
    or public.is_supervisor() or public.is_teacher()
  );
