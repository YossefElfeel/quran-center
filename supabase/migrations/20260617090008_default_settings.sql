-- Phase 1 — إعدادات النظام الافتراضية (idempotent، في migration عشان تتطبّق على الريموت).
-- قابلة للتغيير من لوحة السوبر أدمن لاحقًا.
insert into public.system_settings (key, value) values
  ('daily_pass_threshold', '7'::jsonb),     -- حد نجاح التسميع /10
  ('struggle_failed_attempts', '3'::jsonb), -- تنبيه التعثّر بعد كام رسوب
  ('subscription_amount_egp', '10'::jsonb), -- اشتراك الأسرة الشهري
  ('subscription_grace_days', '7'::jsonb),  -- فترة سماح الاشتراك
  ('circle_max_size', '30'::jsonb)          -- الحد الأقصى للحلقة
on conflict (key) do nothing;
