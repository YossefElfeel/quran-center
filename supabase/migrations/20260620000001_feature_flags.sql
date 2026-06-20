-- God-mode M2 — مفاتيح الميزات (feature flags) + كِل سويتشات النظام.
-- جدول key→enabled + helper private.flag_enabled() يُستخدم من سياسات RLS، فالتجميد
-- بيتفرض على مستوى قاعدة البيانات (التطبيق نفسه بيتمنع من الكتابة، مش بس واجهة اللوحة).
-- السوبر أدمن دايمًا مستثنى من التجميد عشان اللوحة تفضل شغّالة ومايقفلش على نفسه.
-- idempotent: create-if-not-exists + drop policy if exists + create or replace.

create table if not exists public.feature_flag (
  key         text primary key,
  enabled     boolean not null default false,
  description text,
  updated_at  timestamptz not null default now(),
  updated_by  uuid references public.person(id)
);

alter table public.feature_flag enable row level security;

drop trigger if exists feature_flag_set_updated_at on public.feature_flag;
create trigger feature_flag_set_updated_at
  before update on public.feature_flag
  for each row execute function public.set_updated_at();

-- قراءة: أي مستخدم مسجّل (حالة المفاتيح مش سرّية). كتابة: سوبر أدمن بس.
drop policy if exists feature_flag_read on public.feature_flag;
create policy feature_flag_read on public.feature_flag
  for select to authenticated using (true);

drop policy if exists feature_flag_superadmin_write on public.feature_flag;
create policy feature_flag_superadmin_write on public.feature_flag
  for all to authenticated
  using (private.is_super_admin())
  with check (private.is_super_admin());

-- helper قابل للاستخدام من سياسات RLS (private = مش مكشوف كـ RPC).
create or replace function private.flag_enabled(p_key text)
  returns boolean language sql stable security definer set search_path = '' as $$
  select coalesce((select enabled from public.feature_flag where key = p_key), false)
$$;
grant execute on function private.flag_enabled(text) to authenticated, anon;

-- المفاتيح الافتراضية (كلها مقفولة عند الإنشاء عدا التسجيل العام).
insert into public.feature_flag (key, description, enabled) values
  ('maintenance_mode',   'وضع الصيانة — يجمّد كتابة الجلسات والمدفوعات من التطبيق', false),
  ('freeze_sessions',    'تجميد جلسات التسميع/الحضور (إنشاء/تعديل)',              false),
  ('freeze_payments',    'تجميد تسجيل/تعديل مدفوعات الاشتراك',                    false),
  ('write_impersonation','تفعيل التقمّص بصلاحية الكتابة (كِل سويتش — M5)',          false),
  ('public_registration','استقبال طلبات التسجيل العامّة',                          true)
on conflict (key) do nothing;

-- ─────────────────────────────────────────────────────────────────────────────
-- سياسات التجميد (RESTRICTIVE): بتتقاطع (AND) مع السياسات المسموحة الموجودة، فمش
-- بتوسّع صلاحية أبدًا — بس بتمنع الكتابة وقت التجميد. لكل أمر على حدة (مش for all)
-- عشان مانقفلش القراءة. لمّا المفاتيح false: not(false) = true → مفيش أي تأثير
-- (فالاختبارات CI تفضل خضراء). السوبر أدمن مستثنى دايمًا.
-- ─────────────────────────────────────────────────────────────────────────────

-- جلسات التسميع
drop policy if exists tasmee_freeze_insert on public.daily_tasmee;
create policy tasmee_freeze_insert on public.daily_tasmee as restrictive for insert to authenticated
  with check (private.is_super_admin()
    or not (private.flag_enabled('maintenance_mode') or private.flag_enabled('freeze_sessions')));
drop policy if exists tasmee_freeze_update on public.daily_tasmee;
create policy tasmee_freeze_update on public.daily_tasmee as restrictive for update to authenticated
  using (private.is_super_admin()
    or not (private.flag_enabled('maintenance_mode') or private.flag_enabled('freeze_sessions')))
  with check (private.is_super_admin()
    or not (private.flag_enabled('maintenance_mode') or private.flag_enabled('freeze_sessions')));

-- الحضور
drop policy if exists attendance_freeze_insert on public.attendance;
create policy attendance_freeze_insert on public.attendance as restrictive for insert to authenticated
  with check (private.is_super_admin()
    or not (private.flag_enabled('maintenance_mode') or private.flag_enabled('freeze_sessions')));
drop policy if exists attendance_freeze_update on public.attendance;
create policy attendance_freeze_update on public.attendance as restrictive for update to authenticated
  using (private.is_super_admin()
    or not (private.flag_enabled('maintenance_mode') or private.flag_enabled('freeze_sessions')))
  with check (private.is_super_admin()
    or not (private.flag_enabled('maintenance_mode') or private.flag_enabled('freeze_sessions')));

-- الجلسة اليومية (فتح/قفل)
drop policy if exists session_freeze_insert on public.circle_session;
create policy session_freeze_insert on public.circle_session as restrictive for insert to authenticated
  with check (private.is_super_admin()
    or not (private.flag_enabled('maintenance_mode') or private.flag_enabled('freeze_sessions')));
drop policy if exists session_freeze_update on public.circle_session;
create policy session_freeze_update on public.circle_session as restrictive for update to authenticated
  using (private.is_super_admin()
    or not (private.flag_enabled('maintenance_mode') or private.flag_enabled('freeze_sessions')))
  with check (private.is_super_admin()
    or not (private.flag_enabled('maintenance_mode') or private.flag_enabled('freeze_sessions')));

-- مدفوعات الاشتراك
drop policy if exists subpay_freeze_insert on public.subscription_payment;
create policy subpay_freeze_insert on public.subscription_payment as restrictive for insert to authenticated
  with check (private.is_super_admin()
    or not (private.flag_enabled('maintenance_mode') or private.flag_enabled('freeze_payments')));
drop policy if exists subpay_freeze_update on public.subscription_payment;
create policy subpay_freeze_update on public.subscription_payment as restrictive for update to authenticated
  using (private.is_super_admin()
    or not (private.flag_enabled('maintenance_mode') or private.flag_enabled('freeze_payments')))
  with check (private.is_super_admin()
    or not (private.flag_enabled('maintenance_mode') or private.flag_enabled('freeze_payments')));
