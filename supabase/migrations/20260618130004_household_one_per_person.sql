-- Phase 6 (مراجعة) — كل شخص في أسرة واحدة بس (قرار الخطة: حساب واحد للأسرة).
-- يمنع ازدواج العضوية اللي بيسرّب وصول الاشتراك:
-- شخص في أسرتين = "نشط" لو أي واحدة مدفوعة حتى لو أسرته متأخرة.
-- بيتطبّق عبر MCP/CLI. مفيش تعديل هدّام (الجدول كان فاضي وقت الإضافة).

alter table public.household_member
  add constraint household_member_person_unique unique (person_id);

-- القيد الجديد بيعمل unique index على person_id،
-- فالـ index العادي القديم على نفس العمود بقى زيادة.
drop index if exists public.household_member_person_idx;
