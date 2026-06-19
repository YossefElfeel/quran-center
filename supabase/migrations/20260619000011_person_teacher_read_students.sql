-- إصلاح: المعلّم لازم يقدر يقرا أسماء/نوع طلبة حلقاته (روستر "حصة النهارده").
--
-- سياسات public.person الحالية بتسمح بالقراءة لـ: الطاقم (أدمن/سوبر/مشرف)،
-- الشخص لنفسه، وولي الأمر لأبنائه — مفيش سياسة للمعلّم. فلمّا التطبيق بيعمل
-- embed عبر PostgREST: enrollment.select('... student:student_person_id(full_name, gender)')
-- بترجع student = NULL للمعلّم، والعميل بيعمل cast لـ Map فيرمي TypeError =>
-- شاشة الحصة بتكسر بـ "مش قادرين نحمّل الحصة".
--
-- باقي جداول الحصة (circle_session/group_portion_cycle/session_plan/attendance/
-- portion_ledger_entry/daily_tasmee) بتسمح للمعلّم عبر teaches_circle/teaches_enrollment،
-- فالفجوة الوحيدة هي person. بنضيف مساعد مقصور + سياسة قراءة لطلبة حلقاته النشطة بس.
--
-- المساعد بيفوّض فحص "بيدرّس الحلقة دي؟" لـ private.teaches_circle الموجود — فبيرث
-- نفس قواعده (بما فيها إنفاذ المعلّم النشط لو اتطبّق 20260619000007) من غير ما
-- يعتمد على أعمدة blocked_at/deactivated_at مباشرة.

create or replace function private.teaches_student(target_person uuid)
returns boolean language sql stable security definer set search_path = ''
as $$
  select exists (
    select 1
    from public.enrollment e
    where e.student_person_id = target_person
      and e.status = 'active'
      and private.teaches_circle(e.circle_id)
  )
$$;
grant execute on function private.teaches_student(uuid) to authenticated;

create policy person_teacher_read_students on public.person
  for select to authenticated
  using (private.teaches_student(id));
