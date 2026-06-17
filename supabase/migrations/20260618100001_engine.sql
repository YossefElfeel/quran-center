-- Phase 4 — محرّك الحفظ: جداول الحصة/التسميع/الدَيْن/الحضور/الملاحظات.
-- ملاحظة: بيتطبّق على المشروع عبر MCP/CLI.

create type public.session_status as enum ('open', 'closed');
create type public.tasmee_kind as enum ('memorization', 'revision');
create type public.ledger_state as enum ('assigned', 'failed_retry', 'passed');
create type public.attendance_status as enum (
  'present',
  'absent',
  'absent_excused',
  'late'
);
create type public.note_visibility as enum ('parent', 'internal');

-- مقطع قرآني (نطاق) — يعيد استخدامه المحرّك كوحدة حفظ.
create table public.portion (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  surah_start smallint not null references public.surah (number),
  ayah_start smallint not null check (ayah_start > 0),
  surah_end smallint not null references public.surah (number),
  ayah_end smallint not null check (ayah_end > 0),
  created_at timestamptz not null default now()
);

-- حصة اليوم للحلقة (تُفتح وتُقفل).
create table public.circle_session (
  id uuid primary key default gen_random_uuid(),
  circle_id uuid not null references public.circle (id) on delete cascade,
  session_date date not null default current_date,
  status public.session_status not null default 'open',
  opened_by uuid references public.person (id),
  opened_at timestamptz not null default now(),
  closed_at timestamptz
);
create index circle_session_circle_idx
  on public.circle_session (circle_id, session_date);
-- حصة مفتوحة واحدة بحد أقصى لكل حلقة.
create unique index circle_session_one_open
  on public.circle_session (circle_id)
  where status = 'open';

-- خطة الحصة (الحفظ الجديد + المراجعة) — تتحدّد عند قفل الحصة للي بعدها.
create table public.session_plan (
  id uuid primary key default gen_random_uuid(),
  circle_id uuid not null references public.circle (id) on delete cascade,
  for_session_id uuid references public.circle_session (id) on delete set null,
  memorization_portion_id uuid references public.portion (id),
  revision_portion_id uuid references public.portion (id),
  set_by uuid references public.person (id),
  set_at timestamptz not null default now()
);
create index session_plan_circle_idx on public.session_plan (circle_id);

-- دورة مقطع للمجموعة (الحلقة بتشتغل على مقطع لحد ما >٥٠٪ يعدّوا).
create table public.group_portion_cycle (
  id uuid primary key default gen_random_uuid(),
  circle_id uuid not null references public.circle (id) on delete cascade,
  portion_id uuid not null references public.portion (id),
  ord integer not null,
  opened_at timestamptz not null default now(),
  advanced_at timestamptz,
  pass_rate numeric(4, 3)
);
create index gpc_circle_idx on public.group_portion_cycle (circle_id);
-- دورة مفتوحة واحدة لكل حلقة (المقطع الحالي).
create unique index gpc_one_open
  on public.group_portion_cycle (circle_id)
  where advanced_at is null;

-- التسميع اليومي — كل محاولة بتتحفظ (idempotency_key يمنع التكرار وقت المزامنة).
create table public.daily_tasmee (
  id uuid primary key default gen_random_uuid(),
  enrollment_id uuid not null references public.enrollment (id) on delete cascade,
  portion_id uuid not null references public.portion (id),
  kind public.tasmee_kind not null default 'memorization',
  score smallint not null check (score between 0 and 10),
  passed boolean not null,
  teacher_id uuid references public.person (id),
  attempt_date date not null default current_date,
  idempotency_key uuid not null unique,
  created_at timestamptz not null default now()
);
create index daily_tasmee_enrollment_idx on public.daily_tasmee (enrollment_id);
create index daily_tasmee_portion_idx on public.daily_tasmee (portion_id);

-- دفتر المقاطع لكل طالب = الدَيْن/backlog.
create table public.portion_ledger_entry (
  id uuid primary key default gen_random_uuid(),
  student_person_id uuid not null references public.person (id) on delete cascade,
  portion_id uuid not null references public.portion (id),
  state public.ledger_state not null default 'assigned',
  attempts_count integer not null default 0,
  passed_on date,
  updated_at timestamptz not null default now(),
  unique (student_person_id, portion_id)
);
create index ledger_student_idx on public.portion_ledger_entry (student_person_id);
create trigger ledger_set_updated_at
  before update on public.portion_ledger_entry
  for each row execute function public.set_updated_at();

-- الحضور لكل حصة.
create table public.attendance (
  id uuid primary key default gen_random_uuid(),
  session_id uuid not null references public.circle_session (id) on delete cascade,
  enrollment_id uuid not null references public.enrollment (id) on delete cascade,
  status public.attendance_status not null default 'present',
  excuse_approved_by uuid references public.person (id),
  created_at timestamptz not null default now(),
  unique (session_id, enrollment_id)
);
create index attendance_session_idx on public.attendance (session_id);

-- ملاحظات السلوك (ظاهرة لولي الأمر أو داخلية).
create table public.behavioral_note (
  id uuid primary key default gen_random_uuid(),
  student_person_id uuid not null references public.person (id) on delete cascade,
  teacher_id uuid references public.person (id),
  text text not null,
  visibility public.note_visibility not null default 'parent',
  created_at timestamptz not null default now()
);
create index behavioral_note_student_idx
  on public.behavioral_note (student_person_id);
