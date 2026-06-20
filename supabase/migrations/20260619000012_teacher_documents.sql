-- ميزة: ملف المعلّم القابل للتخصيص — يكتب نبذة عنه ويرفع سيرته الذاتية وشهاداته.
--
-- (١) bucket تخزين خاص للمستندات + سياسات: المعلّم يدير فولدره (مفتاح الفولدر =
--     auth.uid())، والأدمن/السوبر يقرا الكل (للمراجعة).
-- (٢) جدول teacher_document بيربط كل ملف مرفوع بالمعلّم (نوعه: سيرة/شهادة).
--
-- المسارات في الـ bucket: '<auth_uid>/<uuid>.<ext>' عشان سياسة الفولدر تشتغل.

-- ===== (١) bucket + سياسات التخزين =====
insert into storage.buckets (id, name, public)
values ('teacher-docs', 'teacher-docs', false)
on conflict (id) do nothing;

drop policy if exists teacher_docs_owner_all on storage.objects;
create policy teacher_docs_owner_all on storage.objects
  for all to authenticated
  using (
    bucket_id = 'teacher-docs'
    and (storage.foldername(name))[1] = auth.uid()::text
  )
  with check (
    bucket_id = 'teacher-docs'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

drop policy if exists teacher_docs_admin_read on storage.objects;
create policy teacher_docs_admin_read on storage.objects
  for select to authenticated
  using (
    bucket_id = 'teacher-docs'
    and (private.is_admin() or private.is_super_admin())
  );

-- ===== (٢) جدول المستندات =====
create table if not exists public.teacher_document (
  id uuid primary key default gen_random_uuid(),
  teacher_person_id uuid not null references public.person (id) on delete cascade,
  kind text not null check (kind in ('cv', 'certificate')),
  title text not null,
  storage_path text not null,
  mime text,
  created_at timestamptz not null default now()
);
create index if not exists teacher_document_idx
  on public.teacher_document (teacher_person_id, kind);

alter table public.teacher_document enable row level security;

-- المعلّم يدير مستنداته؛ الأدمن/السوبر يقرا (مراجعة)؛ المشرف برضه يقرا.
drop policy if exists tdoc_owner_all on public.teacher_document;
create policy tdoc_owner_all on public.teacher_document
  for all to authenticated
  using (teacher_person_id = private.current_person_id())
  with check (teacher_person_id = private.current_person_id());

drop policy if exists tdoc_staff_read on public.teacher_document;
create policy tdoc_staff_read on public.teacher_document
  for select to authenticated
  using (
    private.is_admin() or private.is_super_admin() or private.is_supervisor()
  );
