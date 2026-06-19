-- M6 P4 — السوبر أدمن/الأدمن يقدر يحذف (يسحب) إشعار مُرسَل.
-- جدول notification أصلًا insert-only (مفيش سياسة delete) — بنضيف سياسة حذف للطاقم
-- الأعلى عشان السحب من لوحة التحكّم. الدوال في schema private بعد النقل (20260618270001).
create policy notification_admin_delete on public.notification
  for delete to authenticated
  using (private.is_super_admin() or private.is_admin());

-- وكمان قراءة: notification_read الأصلية للمستلِم نفسه بس، فالأدمن مكنش يشوف الإشعارات
-- اللي بعتها لغيره (فالسحب من اللوحة مكانش بيلاقي صفوف). بنضيف قراءة للطاقم الأعلى.
create policy notification_admin_read on public.notification
  for select to authenticated
  using (private.is_super_admin() or private.is_admin());
