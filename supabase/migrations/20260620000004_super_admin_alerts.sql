-- God-mode M7 — تنبيهات فورية للسوبر أدمن على العمليات الحسّاسة.
-- trigger على audit_log بيولّد صف تنبيه تلقائيًا لأي عملية حسّاسة (حذف نهائي، كتابة
-- مباشرة، خروج إجباري، تبديل مفتاح، تشغيل مجدول، بدء تقمّص...). فالتنبيه أوتوماتيكي
-- لأي حاجة بتتسجّل في التدقيق — من غير ما نوصّل كل نداء يدويًا.

create table if not exists public.super_admin_alert (
  id              uuid primary key default gen_random_uuid(),
  severity        text not null default 'warn',
  action          text not null,
  actor_person_id uuid references public.person(id),
  meta            jsonb not null default '{}',
  created_at      timestamptz not null default now(),
  acknowledged_at timestamptz
);

alter table public.super_admin_alert enable row level security;

-- قراءة + تأكيد (ack): سوبر أدمن بس. الإدراج بيتم من الـ trigger (security definer)
-- أو service-role — فمفيش سياسة insert عامّة.
drop policy if exists saa_super_read on public.super_admin_alert;
create policy saa_super_read on public.super_admin_alert
  for select to authenticated using (private.is_super_admin());

drop policy if exists saa_super_ack on public.super_admin_alert;
create policy saa_super_ack on public.super_admin_alert
  for update to authenticated
  using (private.is_super_admin()) with check (private.is_super_admin());

create or replace function public.raise_sensitive_alert()
  returns trigger language plpgsql security definer set search_path = '' as $$
begin
  if new.action in (
       'data_console_insert','data_console_update','data_console_delete',
       'force_logout','password_force_set','password_reset_link',
       'flag_toggle','cron_run_now','cron_set_active','impersonation_started'
     )
     or new.action like '%hard_delete%' then
    insert into public.super_admin_alert (severity, action, actor_person_id, meta)
    values (
      case when new.action like '%delete%' or new.action = 'password_force_set'
           then 'critical' else 'warn' end,
      new.action, new.actor_person_id,
      jsonb_build_object('target_table', new.target_table,
                         'target_id', new.target_id, 'audit', new.meta)
    );
  end if;
  return new;
end;
$$;

-- دالة trigger — مش المفروض تتنده كـ RPC. نمنع التنفيذ المباشر (الـ trigger بيشتغل
-- بصلاحية المالك بغضّ النظر عن الـ grant) عشان مايقدرش حد يحقن تنبيهات وهمية.
revoke all on function public.raise_sensitive_alert() from public, anon, authenticated;

drop trigger if exists audit_log_alert on public.audit_log;
create trigger audit_log_alert after insert on public.audit_log
  for each row execute function public.raise_sensitive_alert();

-- بثّ التنبيهات مباشرةً للوحة (RLS بيقصرها على السوبر أدمن). idempotent.
do $$
begin
  if exists (select 1 from pg_publication where pubname = 'supabase_realtime')
     and not exists (
       select 1 from pg_publication_tables
       where pubname = 'supabase_realtime' and schemaname = 'public'
         and tablename = 'super_admin_alert'
     ) then
    alter publication supabase_realtime add table public.super_admin_alert;
  end if;
end $$;
