-- Phase 1 — الهوية والأدوار (Person واحد بأدوار متعددة).

-- الأدوار (super_admin أعلى دور، للوحة الويب).
create type public.app_role as enum (
  'super_admin',
  'admin',
  'supervisor',
  'teacher',
  'parent'
);

create type public.gender as enum ('male', 'female');

-- الهوية الموحّدة: طالب/طاقم/ولي أمر. النوع مجرد بيان (مفيش فصل بسببه).
-- الأطفال = person بدون صف في app_user (مفيش دخول).
create table public.person (
  id uuid primary key default gen_random_uuid(),
  full_name text not null,
  gender public.gender,
  photo_url text,
  national_id_hmac text, -- blind index للـ dedup فقط (مش مفتاح)
  national_id_encrypted bytea, -- للعرض المقنّع
  national_id_last4 text,
  phone text,
  dob date,
  is_minor boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- dedup الرقم القومي لمّا يكون موجود (UNIQUE جزئي).
create unique index person_national_id_hmac_key
  on public.person (national_id_hmac)
  where national_id_hmac is not null;

create trigger person_set_updated_at
  before update on public.person
  for each row execute function public.set_updated_at();

-- ربط حساب الدخول (auth.users) بالـ Person. الأطفال مالهمش صف هنا.
create table public.app_user (
  auth_user_id uuid primary key references auth.users (id) on delete cascade,
  person_id uuid not null unique references public.person (id) on delete cascade,
  created_at timestamptz not null default now()
);

-- الأدوار لكل person (هوية واحدة بأدوار متعددة) + صلاحيات granular.
create table public.role_assignment (
  id uuid primary key default gen_random_uuid(),
  person_id uuid not null references public.person (id) on delete cascade,
  role public.app_role not null,
  granular_permissions jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  unique (person_id, role)
);
create index role_assignment_person_idx on public.role_assignment (person_id);

-- ولي أمر ↔ طالب (many-to-many: الأب والأم لنفس الطالب).
create table public.guardian_link (
  guardian_person_id uuid not null references public.person (id) on delete cascade,
  student_person_id uuid not null references public.person (id) on delete cascade,
  relation text,
  created_at timestamptz not null default now(),
  primary key (guardian_person_id, student_person_id)
);
create index guardian_link_student_idx
  on public.guardian_link (student_person_id);

-- إعدادات النظام (يضبطها السوبر أدمن، يقراها التطبيق):
-- عتبة النجاح الافتراضية، N التعثّر، قيمة الاشتراك/السماح، حد الحلقة...
create table public.system_settings (
  key text primary key,
  value jsonb not null,
  updated_at timestamptz not null default now(),
  updated_by uuid references public.person (id)
);
create trigger system_settings_set_updated_at
  before update on public.system_settings
  for each row execute function public.set_updated_at();

-- سجل تقمّص الدور (impersonation) من لوحة السوبر أدمن — مدقّق ومحدّد بوقت.
create table public.impersonation_session (
  id uuid primary key default gen_random_uuid(),
  super_admin_person_id uuid not null references public.person (id),
  subject_person_id uuid not null references public.person (id),
  reason text,
  ip inet,
  started_at timestamptz not null default now(),
  ended_at timestamptz,
  actions_count integer not null default 0
);
create index impersonation_active_idx
  on public.impersonation_session (super_admin_person_id)
  where ended_at is null;
