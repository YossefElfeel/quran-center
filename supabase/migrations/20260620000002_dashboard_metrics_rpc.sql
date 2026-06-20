-- God-mode M3 — مقاييس اللوحة في نداء واحد + إشارات الشذوذ + بثّ سجل التدقيق مباشرةً.
-- بدل ١٨ نداء COUNT منفصل في صفحة الـ home. SECURITY DEFINER + بوّابة سوبر أدمن.

create or replace function public.dashboard_metrics()
  returns jsonb language plpgsql stable security definer set search_path = '' as $$
declare
  v_month date := date_trunc('month', now())::date;
  v_households int := (select count(*) from public.household);
  v_paid int := (select count(distinct household_id) from public.subscription_payment
                 where voided = false and period_month = v_month);
begin
  if not private.is_super_admin() then
    raise exception 'forbidden' using errcode = '42501';
  end if;

  return jsonb_build_object(
    'active_students', (select count(*) from public.enrollment where status = 'active'),
    'active_circles',  (select count(*) from public.circle where status = 'active'),
    'total_circles',   (select count(*) from public.circle),
    'teachers',        (select count(*) from public.role_assignment where role = 'teacher'),
    'households',      v_households,
    'overdue',         greatest(0, v_households - v_paid),
    'open_complaints', (select count(*) from public.complaint where status = 'open'),
    'waiting',         (select count(*) from public.waiting_list where status = 'waiting'),
    'dev_pending',     (select count(*) from public.teacher_development where status = 'submitted'),
    'mse_pending',     (select count(*) from public.monthly_student_evaluation where status = 'submitted'),
    'excuse_pending',  (select count(*) from public.excuse_request where status = 'pending'),
    'struggling',      (select count(*) from public.portion_ledger_entry
                          where state = 'failed_retry' and attempts_count >= 3),
    'pass_rate',       (select coalesce(round(100.0 * count(*) filter (where passed)
                          / nullif(count(*), 0)), 0) from public.daily_tasmee),
    'att_rate',        (select coalesce(round(100.0 * count(*) filter (where status = 'present')
                          / nullif(count(*), 0)), 0) from public.attendance),
    -- إشارات الشذوذ (god-mode):
    'hard_deletes_24h', (select count(*) from public.audit_log
                          where action like '%hard_delete%' and at >= now() - interval '24 hours'),
    'data_writes_24h',  (select count(*) from public.audit_log
                          where action like 'data_console_%' and at >= now() - interval '24 hours'),
    'open_impersonations', (select count(*) from public.impersonation_session where ended_at is null),
    'maintenance_on',   private.flag_enabled('maintenance_mode'),
    'sessions_frozen',  private.flag_enabled('freeze_sessions'),
    'payments_frozen',  private.flag_enabled('freeze_payments')
  );
end;
$$;

revoke all on function public.dashboard_metrics() from public, anon;
grant execute on function public.dashboard_metrics() to authenticated;

-- بثّ سجل التدقيق للوحة مباشرةً (Realtime). RLS بيضمن إن السوبر أدمن/الأدمن بس
-- اللي بيستقبلوا الصفوف. idempotent.
do $$
begin
  if exists (select 1 from pg_publication where pubname = 'supabase_realtime')
     and not exists (
       select 1 from pg_publication_tables
       where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = 'audit_log'
     ) then
    alter publication supabase_realtime add table public.audit_log;
  end if;
end $$;
