-- M6 — دورة حياة الـ person: حظر (block) + إيقاف/حذف ناعم (deactivate) للوحة السوبر أدمن.
-- أعمدة nullable فقط => متوافقة رجعيًا (كل الصفوف الحالية = active، مفيش backfill).
-- الحظر والإيقاف حقيقتان مستقلتان (واحد قابل للعكس بسرعة، التاني حذف ناعم بيحفظ السجلّ).
-- الإنفاذ الفعلي للحظر بيتم في migration 0007 (بوّابة private.current_person_id/has_role)
-- + على مستوى Auth (ban + إنهاء الجلسات) من Edge function block-user.

alter table public.person
  add column if not exists blocked_at         timestamptz,
  add column if not exists blocked_by         uuid references public.person (id) on delete set null,
  add column if not exists blocked_reason     text,
  add column if not exists deactivated_at     timestamptz,
  add column if not exists deactivated_by     uuid references public.person (id) on delete set null,
  add column if not exists deactivated_reason text;

-- فهارس جزئية صغيرة (الأقلية غير النشطة بس).
create index if not exists person_blocked_idx
  on public.person (blocked_at) where blocked_at is not null;
create index if not exists person_deactivated_idx
  on public.person (deactivated_at) where deactivated_at is not null;

-- عمود محسوب للعرض في اللوحة (الإيقاف بيغلب الحظر).
alter table public.person
  add column if not exists lifecycle_status text
    generated always as (
      case when deactivated_at is not null then 'deactivated'
           when blocked_at      is not null then 'blocked'
           else 'active' end
    ) stored;

comment on column public.person.blocked_at is
  'لو مش NULL: الحساب محظور — RLS بتشوفه كأنه بلا هوية/أدوار، و Auth banned.';
comment on column public.person.deactivated_at is
  'لو مش NULL: حذف ناعم (إيقاف) — بيحفظ السجلّ الأكاديمي/المالي، قابل للاسترجاع.';
