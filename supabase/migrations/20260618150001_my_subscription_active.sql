-- Phase 7 — دالة بسيطة: هل اشتراكي (كولي أمر) نشط دلوقتي؟ (لبوابة الوصول).
create or replace function public.my_subscription_active()
returns boolean
language sql
security invoker
set search_path = ''
stable
as $$
  select public.person_has_active_subscription(public.current_person_id());
$$;

revoke all on function public.my_subscription_active() from public, anon;
grant execute on function public.my_subscription_active() to authenticated;
