import { createSupabaseServerClient } from "@/lib/supabase/server";

// يسجّل عملية إدارية في audit_log بهوية المستخدم الحالي (عبر RLS — سياسة
// audit_admin_insert بتفرض إنه سوبر أدمن/أدمن و actor = شخصه). للعمليات العادية
// في اللوحة. العمليات الحسّاسة (حظر/حذف مستخدم/أدوار) بتسجّل نفسها داخل Edge functions.
// best-effort: لو الإدراج اتمنع/فشل مابيرميش استثناء (مابيكسرش العملية الأصلية).
export async function logAudit(entry: {
  action: string;
  targetTable?: string;
  targetId?: string;
  meta?: Record<string, unknown>;
}): Promise<void> {
  const supabase = await createSupabaseServerClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) return;
  const { data: appUser } = await supabase
    .from("app_user")
    .select("person_id")
    .eq("auth_user_id", user.id)
    .maybeSingle();
  const personId = appUser?.person_id as string | undefined;
  if (!personId) return;
  await supabase.from("audit_log").insert({
    actor_person_id: personId,
    action: entry.action,
    target_table: entry.targetTable ?? null,
    target_id: entry.targetId ?? null,
    meta: entry.meta ?? {},
  });
}
