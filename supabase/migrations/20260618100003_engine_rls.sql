-- Phase 4 — تفعيل RLS + سياسات بيانات المحرّك.
-- المعلّم يدير بيانات حلقاته؛ المشرف/الأدمن يقروا؛ ولي الأمر يقرا بتاع ابنه.

-- ===== portion (مرجع مقاطع) =====
alter table public.portion enable row level security;
create policy portion_read on public.portion
  for select to authenticated using (true);
create policy portion_staff_write on public.portion
  for all to authenticated
  using (
    public.is_super_admin() or public.is_admin()
    or public.is_supervisor() or public.is_teacher()
  )
  with check (
    public.is_super_admin() or public.is_admin()
    or public.is_supervisor() or public.is_teacher()
  );

-- ===== circle_session =====
alter table public.circle_session enable row level security;
create policy circle_session_read on public.circle_session
  for select to authenticated
  using (
    public.is_super_admin() or public.is_admin() or public.is_supervisor()
    or public.teaches_circle(circle_id)
  );
create policy circle_session_write on public.circle_session
  for all to authenticated
  using (
    public.teaches_circle(circle_id)
    or public.is_admin() or public.is_super_admin()
  )
  with check (
    public.teaches_circle(circle_id)
    or public.is_admin() or public.is_super_admin()
  );

-- ===== session_plan =====
alter table public.session_plan enable row level security;
create policy session_plan_read on public.session_plan
  for select to authenticated
  using (
    public.is_super_admin() or public.is_admin() or public.is_supervisor()
    or public.teaches_circle(circle_id)
  );
create policy session_plan_write on public.session_plan
  for all to authenticated
  using (
    public.teaches_circle(circle_id)
    or public.is_admin() or public.is_super_admin()
  )
  with check (
    public.teaches_circle(circle_id)
    or public.is_admin() or public.is_super_admin()
  );

-- ===== group_portion_cycle =====
alter table public.group_portion_cycle enable row level security;
create policy gpc_read on public.group_portion_cycle
  for select to authenticated
  using (
    public.is_super_admin() or public.is_admin() or public.is_supervisor()
    or public.teaches_circle(circle_id)
  );
create policy gpc_write on public.group_portion_cycle
  for all to authenticated
  using (
    public.teaches_circle(circle_id)
    or public.is_admin() or public.is_super_admin()
  )
  with check (
    public.teaches_circle(circle_id)
    or public.is_admin() or public.is_super_admin()
  );

-- ===== daily_tasmee =====
alter table public.daily_tasmee enable row level security;
create policy tasmee_read on public.daily_tasmee
  for select to authenticated
  using (
    public.is_super_admin() or public.is_admin() or public.is_supervisor()
    or public.teaches_enrollment(enrollment_id)
    or public.is_guardian_of_enrollment(enrollment_id)
  );
create policy tasmee_write on public.daily_tasmee
  for all to authenticated
  using (
    public.teaches_enrollment(enrollment_id)
    or public.is_admin() or public.is_super_admin()
  )
  with check (
    public.teaches_enrollment(enrollment_id)
    or public.is_admin() or public.is_super_admin()
  );

-- ===== portion_ledger_entry (الدَيْن) =====
alter table public.portion_ledger_entry enable row level security;
create policy ledger_read on public.portion_ledger_entry
  for select to authenticated
  using (
    public.is_super_admin() or public.is_admin() or public.is_supervisor()
    or public.is_guardian_of(student_person_id)
    or exists (
      select 1 from public.enrollment e
      where e.student_person_id = portion_ledger_entry.student_person_id
        and public.teaches_circle(e.circle_id)
    )
  );
create policy ledger_write on public.portion_ledger_entry
  for all to authenticated
  using (
    public.is_super_admin() or public.is_admin()
    or exists (
      select 1 from public.enrollment e
      where e.student_person_id = portion_ledger_entry.student_person_id
        and public.teaches_circle(e.circle_id)
    )
  )
  with check (
    public.is_super_admin() or public.is_admin()
    or exists (
      select 1 from public.enrollment e
      where e.student_person_id = portion_ledger_entry.student_person_id
        and public.teaches_circle(e.circle_id)
    )
  );

-- ===== attendance =====
alter table public.attendance enable row level security;
create policy attendance_read on public.attendance
  for select to authenticated
  using (
    public.is_super_admin() or public.is_admin() or public.is_supervisor()
    or public.teaches_enrollment(enrollment_id)
    or public.is_guardian_of_enrollment(enrollment_id)
  );
create policy attendance_write on public.attendance
  for all to authenticated
  using (
    public.teaches_enrollment(enrollment_id)
    or public.is_supervisor() or public.is_admin() or public.is_super_admin()
  )
  with check (
    public.teaches_enrollment(enrollment_id)
    or public.is_supervisor() or public.is_admin() or public.is_super_admin()
  );

-- ===== behavioral_note =====
alter table public.behavioral_note enable row level security;
create policy note_read on public.behavioral_note
  for select to authenticated
  using (
    public.is_super_admin() or public.is_admin() or public.is_supervisor()
    or (visibility = 'parent' and public.is_guardian_of(student_person_id))
    or exists (
      select 1 from public.enrollment e
      where e.student_person_id = behavioral_note.student_person_id
        and public.teaches_circle(e.circle_id)
    )
  );
create policy note_write on public.behavioral_note
  for all to authenticated
  using (
    public.is_super_admin() or public.is_admin()
    or exists (
      select 1 from public.enrollment e
      where e.student_person_id = behavioral_note.student_person_id
        and public.teaches_circle(e.circle_id)
    )
  )
  with check (
    public.is_super_admin() or public.is_admin()
    or exists (
      select 1 from public.enrollment e
      where e.student_person_id = behavioral_note.student_person_id
        and public.teaches_circle(e.circle_id)
    )
  );
