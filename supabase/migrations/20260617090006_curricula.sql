-- Phase 1 — المناهج والحلقات (نموذج الدُفعة/cohort).
-- ملاحظة: مكتوب لكن لسه ماتطبّقش.

create type public.curriculum_type as enum ('quran', 'arabic_foundation');
create type public.circle_status as enum ('forming', 'active', 'graduated');
create type public.enrollment_status as enum (
  'active', 'paused', 'graduated', 'dropped', 'transferred'
);
create type public.waiting_status as enum (
  'waiting', 'offered', 'accepted', 'declined', 'expired'
);

-- المنهج (قرآن / تأسيس عربي) + versioning.
create table public.curriculum (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  type public.curriculum_type not null default 'quran',
  version integer not null default 1,
  valid_from date,
  valid_to date,
  created_at timestamptz not null default now()
);

-- المستويات داخل المنهج (ترتيب حر).
create table public.level (
  id uuid primary key default gen_random_uuid(),
  curriculum_id uuid not null references public.curriculum (id) on delete cascade,
  ord integer not null,
  name text not null,
  created_at timestamptz not null default now(),
  unique (curriculum_id, ord)
);
create index level_curriculum_idx on public.level (curriculum_id);

-- الحلقة = دُفعة (cohort) مختلطة، ليها معلّم.
create table public.circle (
  id uuid primary key default gen_random_uuid(),
  level_id uuid not null references public.level (id) on delete restrict,
  teacher_id uuid references public.person (id) on delete set null,
  name text not null,
  max_size integer not null default 30 check (max_size > 0),
  status public.circle_status not null default 'forming',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index circle_level_idx on public.circle (level_id);
create index circle_teacher_idx on public.circle (teacher_id);
create trigger circle_set_updated_at
  before update on public.circle
  for each row execute function public.set_updated_at();

-- التسجيل: الطالب في حلقة نشطة واحدة؛ التاريخ بيتبع الطالب.
create table public.enrollment (
  id uuid primary key default gen_random_uuid(),
  student_person_id uuid not null references public.person (id) on delete cascade,
  circle_id uuid not null references public.circle (id) on delete cascade,
  status public.enrollment_status not null default 'active',
  enrolled_at timestamptz not null default now(),
  left_at timestamptz
);
create index enrollment_circle_idx on public.enrollment (circle_id);
create index enrollment_student_idx on public.enrollment (student_person_id);
-- حلقة نشطة واحدة لكل طالب (partial unique).
create unique index enrollment_one_active_per_student
  on public.enrollment (student_person_id)
  where status = 'active';

-- قائمة الانتظار (FIFO + دورة حياة عرض المقعد).
create table public.waiting_list (
  id uuid primary key default gen_random_uuid(),
  student_person_id uuid not null references public.person (id) on delete cascade,
  level_id uuid not null references public.level (id) on delete cascade,
  status public.waiting_status not null default 'waiting',
  created_at timestamptz not null default now()
);
create index waiting_list_level_idx on public.waiting_list (level_id, created_at);

-- اختبار تحديد المستوى (يعمله المشرف).
create table public.placement_test (
  id uuid primary key default gen_random_uuid(),
  student_person_id uuid not null references public.person (id) on delete cascade,
  supervisor_id uuid references public.person (id) on delete set null,
  result_level_id uuid references public.level (id) on delete set null,
  notes text,
  taken_at date not null default current_date
);
create index placement_test_student_idx
  on public.placement_test (student_person_id);
