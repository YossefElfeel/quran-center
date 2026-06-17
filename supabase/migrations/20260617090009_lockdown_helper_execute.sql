-- Phase 1 hardening — قلّل سطح RPC لدوال الـ RLS (security advisor 0028).
-- الدوال SECURITY DEFINER بتتكشف كـ PostgREST RPC؛ بنسحب execute من public/anon
-- ونسيبها للـ authenticated بس (محتاجها الـ RLS وقت تقييم السياسات).
-- ملاحظة: الإصلاح الكامل (نقل الدوال لـ schema خاص غير مكشوف) متجدول في Phase 14.
-- (الدوال دي بترجّع boolean/id للمستخدم الحالي نفسه بس — مفيش تسريب بيانات.)

revoke execute on function public.current_person_id() from public, anon;
grant execute on function public.current_person_id() to authenticated;

revoke execute on function public.has_role(public.app_role) from public, anon;
grant execute on function public.has_role(public.app_role) to authenticated;

revoke execute on function public.is_super_admin() from public, anon;
grant execute on function public.is_super_admin() to authenticated;

revoke execute on function public.is_admin() from public, anon;
grant execute on function public.is_admin() to authenticated;

revoke execute on function public.is_supervisor() from public, anon;
grant execute on function public.is_supervisor() to authenticated;

revoke execute on function public.is_teacher() from public, anon;
grant execute on function public.is_teacher() to authenticated;

revoke execute on function public.is_parent() from public, anon;
grant execute on function public.is_parent() to authenticated;

revoke execute on function public.is_guardian_of(uuid) from public, anon;
grant execute on function public.is_guardian_of(uuid) to authenticated;

revoke execute on function public.teaches_circle(uuid) from public, anon;
grant execute on function public.teaches_circle(uuid) to authenticated;
