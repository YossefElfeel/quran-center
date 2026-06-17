-- Phase 1 — init: امتدادات + helpers مشتركة.
-- ملاحظة: مكتوب لكن **لسه ماتطبّقش** (مفيش مشروع Supabase حيّ).
-- التطبيق لاحقًا عبر `supabase db push` أو Supabase MCP، مع تحقّق فعلي بعد التطبيق.

create extension if not exists pgcrypto; -- gen_random_uuid()

-- تحديث عمود updated_at تلقائيًا عند أي UPDATE.
create or replace function public.set_updated_at()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;
