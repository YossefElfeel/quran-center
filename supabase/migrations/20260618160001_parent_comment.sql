-- Phase 7 — تعليقات ولي الأمر على ملف ابنه (تواصل من البيت للمركز).
-- ولي الأمر بيكتب؛ المعلّم/المشرف/الأدمن بيقروا. append-only.
-- المؤلّف default = current_person_id() سيرفر-سايد (العميل مايبعتوش → يمنع الانتحال).
-- بيتطبّق عبر MCP/CLI. مفيش تعديل هدّام.

create table public.parent_comment (
  id uuid primary key default gen_random_uuid(),
  student_person_id uuid not null references public.person (id) on delete cascade,
  author_guardian_id uuid not null default public.current_person_id()
    references public.person (id),
  body text not null check (length(btrim(body)) > 0),
  created_at timestamptz not null default now()
);
create index parent_comment_student_idx
  on public.parent_comment (student_person_id, created_at desc);

alter table public.parent_comment enable row level security;

-- قراءة: أولياء أمر الطالب + معلّم حلقته + المشرف/الأدمن/السوبر.
create policy parent_comment_read on public.parent_comment
  for select to authenticated
  using (
    public.is_super_admin() or public.is_admin() or public.is_supervisor()
    or public.is_guardian_of(student_person_id)
    or exists (
      select 1 from public.enrollment e
      where e.student_person_id = parent_comment.student_person_id
        and public.teaches_circle(e.circle_id)
    )
  );

-- كتابة: ولي أمر الطالب بس، والمؤلّف لازم يكون هو نفسه.
create policy parent_comment_insert on public.parent_comment
  for insert to authenticated
  with check (
    public.is_guardian_of(student_person_id)
    and author_guardian_id = public.current_person_id()
  );
