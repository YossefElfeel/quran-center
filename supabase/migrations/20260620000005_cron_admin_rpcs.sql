-- God-mode M6 — تحكّم السوبر أدمن في المهام المجدولة (pg_cron). جداول/دوال cron مش
-- متاحة لأدوار الـ API، فبنوفّر RPCs محروسة (سوبر أدمن + مدقّقة). cron_run_now بيستخدم
-- allow-list (case) على المهام الستّة المعروفة — مفيش SQL ديناميكي على إدخال المستخدم.

-- قائمة المهام.
create or replace function public.cron_jobs()
  returns table(jobid bigint, jobname text, schedule text, active boolean)
  language plpgsql stable security definer set search_path = '' as $$
begin
  if not private.is_super_admin() then
    raise exception 'forbidden' using errcode = '42501';
  end if;
  return query
    select j.jobid, j.jobname, j.schedule, j.active
    from cron.job j order by j.jobname;
end;
$$;

-- تفعيل/تعطيل مهمّة.
create or replace function public.cron_set_active(p_jobname text, p_active boolean, p_reason text)
  returns jsonb language plpgsql security definer set search_path = '' as $$
declare
  v_jobid bigint;
  v_actor uuid := private.current_person_id();
begin
  if not private.is_super_admin() then
    raise exception 'forbidden' using errcode = '42501';
  end if;
  if coalesce(trim(p_reason), '') = '' then
    raise exception 'reason required' using errcode = '22023';
  end if;
  select jobid into v_jobid from cron.job where jobname = p_jobname;
  if v_jobid is null then
    raise exception 'unknown job' using errcode = 'P0002';
  end if;
  perform cron.alter_job(job_id => v_jobid, active => p_active);
  insert into public.audit_log (actor_person_id, action, target_table, target_id, meta)
  values (v_actor, 'cron_set_active', 'cron.job', null,
          jsonb_build_object('jobname', p_jobname, 'active', p_active, 'reason', p_reason));
  return jsonb_build_object('ok', true, 'jobname', p_jobname, 'active', p_active);
end;
$$;

-- تشغيل مهمّة فورًا (allow-list).
create or replace function public.cron_run_now(p_jobname text, p_reason text)
  returns jsonb language plpgsql security definer set search_path = '' as $$
declare
  v_actor uuid := private.current_person_id();
begin
  if not private.is_super_admin() then
    raise exception 'forbidden' using errcode = '42501';
  end if;
  if coalesce(trim(p_reason), '') = '' then
    raise exception 'reason required' using errcode = '22023';
  end if;
  case p_jobname
    when 'monthly-close' then perform public.run_monthly_close();
    when 'media-retention' then perform public.run_media_retention();
    when 'purge-public-registrations' then perform public.purge_public_registrations();
    when 'nominate-certificate-candidates' then perform public.nominate_certificate_candidates();
    when 'escalate-overdue-complaints' then perform public.escalate_overdue_complaints();
    when 'notify-overdue-subscriptions' then perform public.notify_overdue_subscriptions();
    else raise exception 'unknown job' using errcode = 'P0002';
  end case;
  insert into public.audit_log (actor_person_id, action, target_table, target_id, meta)
  values (v_actor, 'cron_run_now', 'cron.job', null,
          jsonb_build_object('jobname', p_jobname, 'reason', p_reason));
  return jsonb_build_object('ok', true, 'jobname', p_jobname);
end;
$$;

revoke all on function public.cron_jobs() from public, anon;
revoke all on function public.cron_set_active(text, boolean, text) from public, anon;
revoke all on function public.cron_run_now(text, text) from public, anon;
grant execute on function public.cron_jobs() to authenticated;
grant execute on function public.cron_set_active(text, boolean, text) to authenticated;
grant execute on function public.cron_run_now(text, text) to authenticated;
