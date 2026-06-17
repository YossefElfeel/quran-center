-- Phase 1 — تفعيل RLS + سياسات جداول الهوية.
-- (سياسات أولية؛ تتدقّق وتتوسّع بعد التطبيق على مشروع حيّ وباختبارات pgTAP.)
-- مفيش سياسات لدور anon → ممنوع افتراضيًا.

-- ===== person =====
alter table public.person enable row level security;

-- الطاقم الإشرافي: قراءة الكل.
create policy person_staff_read on public.person
  for select to authenticated
  using (public.is_super_admin() or public.is_admin() or public.is_supervisor());

-- الشخص يقرا نفسه.
create policy person_self_read on public.person
  for select to authenticated
  using (id = public.current_person_id());

-- ولي الأمر يقرا أبناءه.
create policy person_guardian_read on public.person
  for select to authenticated
  using (public.is_guardian_of(id));

-- الكتابة (إنشاء/تعديل/حذف الأشخاص): سوبر أدمن/أدمن.
create policy person_admin_write on public.person
  for all to authenticated
  using (public.is_super_admin() or public.is_admin())
  with check (public.is_super_admin() or public.is_admin());

-- ===== app_user =====
alter table public.app_user enable row level security;

create policy app_user_self_read on public.app_user
  for select to authenticated
  using (person_id = public.current_person_id());

create policy app_user_admin_all on public.app_user
  for all to authenticated
  using (public.is_super_admin() or public.is_admin())
  with check (public.is_super_admin() or public.is_admin());

-- ===== role_assignment =====
alter table public.role_assignment enable row level security;

create policy role_self_read on public.role_assignment
  for select to authenticated
  using (person_id = public.current_person_id());

create policy role_admin_read on public.role_assignment
  for select to authenticated
  using (public.is_super_admin() or public.is_admin());

-- السوبر أدمن يدير كل الأدوار (بما فيها super_admin).
create policy role_superadmin_write on public.role_assignment
  for all to authenticated
  using (public.is_super_admin())
  with check (public.is_super_admin());

-- الأدمن يدير الأدوار عدا super_admin.
create policy role_admin_write on public.role_assignment
  for all to authenticated
  using (public.is_admin() and role <> 'super_admin'::public.app_role)
  with check (public.is_admin() and role <> 'super_admin'::public.app_role);

-- ===== guardian_link =====
alter table public.guardian_link enable row level security;

create policy guardian_link_admin_all on public.guardian_link
  for all to authenticated
  using (public.is_super_admin() or public.is_admin())
  with check (public.is_super_admin() or public.is_admin());

create policy guardian_link_guardian_read on public.guardian_link
  for select to authenticated
  using (guardian_person_id = public.current_person_id());

create policy guardian_link_supervisor_read on public.guardian_link
  for select to authenticated
  using (public.is_supervisor());

-- ===== system_settings =====
alter table public.system_settings enable row level security;

-- قراءة الإعدادات متاحة لأي مستخدم مسجّل (التطبيق محتاج العتبات).
create policy settings_read on public.system_settings
  for select to authenticated
  using (true);

create policy settings_superadmin_write on public.system_settings
  for all to authenticated
  using (public.is_super_admin())
  with check (public.is_super_admin());

-- ===== impersonation_session =====
alter table public.impersonation_session enable row level security;

-- السوبر أدمن بس (إنشاء/قراءة/إنهاء جلسات التقمّص).
create policy impersonation_superadmin_all on public.impersonation_session
  for all to authenticated
  using (public.is_super_admin())
  with check (public.is_super_admin());
