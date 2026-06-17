-- Phase 4 (batch 3b-2) — مقام التقدّم المُجمَّد + حصيلة الحصة + دالة تسميع ذرّية.
-- (أ) snapshot لعدد التسجيلات الفعّالة وقت فتح دورة المقطع = مقام نسبة العدّاية المجمّد.
-- (ب) session_outcome = "اللي اتحفظ فعلاً النهارده" (الماضي)، غير session_plan (الجاي).
-- (ج) record_tasmee = دالة ذرّية idempotent بتسجّل المحاولة وتحدّث الدفتر في معاملة واحدة.
-- بيتطبّق عبر MCP/CLI. مفيش أي تعديل هدّام على الجداول الموجودة.

-- ===== (أ) المقام المجمّد على دورة المقطع =====
-- عدد التسجيلات الفعّالة لحظة فتح الدورة. التقدّم يُقترَح لما > ٥٠٪ من المقام ده يعدّوا.
alter table public.group_portion_cycle
  add column active_at_open integer not null default 0
  check (active_at_open >= 0);

-- ===== (ب) session_outcome — اللي اتحفظ فعلاً في الحصة =====
create table public.session_outcome (
  id uuid primary key default gen_random_uuid(),
  session_id uuid not null references public.circle_session (id) on delete cascade,
  memorized_portion_id uuid references public.portion (id),
  notes text,
  created_at timestamptz not null default now()
);
create index session_outcome_session_idx on public.session_outcome (session_id);

alter table public.session_outcome enable row level security;
create policy session_outcome_read on public.session_outcome
  for select to authenticated
  using (
    public.is_super_admin() or public.is_admin() or public.is_supervisor()
    or exists (
      select 1 from public.circle_session cs
      where cs.id = session_outcome.session_id
        and public.teaches_circle(cs.circle_id)
    )
  );
create policy session_outcome_write on public.session_outcome
  for all to authenticated
  using (
    public.is_super_admin() or public.is_admin()
    or exists (
      select 1 from public.circle_session cs
      where cs.id = session_outcome.session_id
        and public.teaches_circle(cs.circle_id)
    )
  )
  with check (
    public.is_super_admin() or public.is_admin()
    or exists (
      select 1 from public.circle_session cs
      where cs.id = session_outcome.session_id
        and public.teaches_circle(cs.circle_id)
    )
  );

-- ===== (ج) record_tasmee — تسجيل تسميع ذرّي وidempotent =====
-- security invoker: الـ RLS بتتطبّق على المعلّم اللي بينده (لازم يدرّس الحلقة/التسجيل).
-- idempotent: لو المفتاح اتكرّر (retry) مايتسجّلش تاني ومايزوّدش العدّاد.
-- المراجعة (kind='revision') مابتمسّش دفتر الدَيْن. التواريخ من السيرفر (current_date).
create or replace function public.record_tasmee(
  p_enrollment_id uuid,
  p_student_person_id uuid,
  p_portion_id uuid,
  p_score smallint,
  p_passed boolean,
  p_idempotency_key uuid,
  p_kind public.tasmee_kind default 'memorization',
  p_session_id uuid default null,
  p_teacher_id uuid default null
) returns public.ledger_state
language plpgsql
security invoker
set search_path = ''
as $$
declare
  v_inserted integer;
  v_state public.ledger_state;
begin
  insert into public.daily_tasmee (
    enrollment_id, portion_id, kind, score, passed,
    teacher_id, session_id, idempotency_key
  ) values (
    p_enrollment_id, p_portion_id, p_kind, p_score, p_passed,
    p_teacher_id, p_session_id, p_idempotency_key
  )
  on conflict (idempotency_key) do nothing;
  get diagnostics v_inserted = row_count;

  -- retry على نفس المفتاح: no-op، رجّع الحالة الحالية من غير ما تزوّد العدّاد.
  if v_inserted = 0 then
    select state into v_state from public.portion_ledger_entry
      where student_person_id = p_student_person_id and portion_id = p_portion_id;
    return coalesce(v_state, 'assigned'::public.ledger_state);
  end if;

  -- المراجعة مابتغيّرش دفتر الحفظ.
  if p_kind = 'revision' then
    select state into v_state from public.portion_ledger_entry
      where student_person_id = p_student_person_id and portion_id = p_portion_id;
    return coalesce(v_state, 'assigned'::public.ledger_state);
  end if;

  -- حفظ: حدّث الدفتر ذرّيًا (مرّة عدّى يفضل عدّى).
  insert into public.portion_ledger_entry (
    student_person_id, portion_id, state, attempts_count, passed_on
  ) values (
    p_student_person_id, p_portion_id,
    (case when p_passed then 'passed' else 'failed_retry' end)::public.ledger_state,
    1,
    (case when p_passed then current_date else null end)
  )
  on conflict (student_person_id, portion_id) do update set
    state = (
      case
        when public.portion_ledger_entry.state = 'passed' then 'passed'
        when p_passed then 'passed'
        else 'failed_retry'
      end
    )::public.ledger_state,
    attempts_count = public.portion_ledger_entry.attempts_count + 1,
    passed_on = (
      case
        when public.portion_ledger_entry.passed_on is not null
          then public.portion_ledger_entry.passed_on
        when p_passed then current_date
        else null
      end
    );

  select state into v_state from public.portion_ledger_entry
    where student_person_id = p_student_person_id and portion_id = p_portion_id;
  return v_state;
end;
$$;

revoke all on function public.record_tasmee(
  uuid, uuid, uuid, smallint, boolean, uuid, public.tasmee_kind, uuid, uuid
) from public, anon;
grant execute on function public.record_tasmee(
  uuid, uuid, uuid, smallint, boolean, uuid, public.tasmee_kind, uuid, uuid
) to authenticated;
