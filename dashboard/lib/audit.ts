import { createSupabaseServerClient } from "@/lib/supabase/server";
import { getDataIdentity } from "@/lib/supabase/data-client";

// يسجّل عملية إدارية في audit_log بهوية المستخدم الحالي (عبر RLS — سياسة
// audit_admin_insert بتفرض إنه سوبر أدمن/أدمن و actor = شخصه). للعمليات العادية
// في اللوحة. العمليات الحسّاسة (حظر/حذف مستخدم/أدوار) بتسجّل نفسها داخل Edge functions.
// best-effort: لو الإدراج اتمنع/فشل مابيرميش استثناء (مابيكسرش العملية الأصلية).
export async function logAudit(entry: {
  action: string;
  targetTable?: string;
  targetId?: string;
  meta?: Record<string, unknown>;
  // System tools run with the operator's own client even while impersonating; don't attribute them to the subject.
  asOperator?: boolean;
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
  let impersonationMeta:Record<string,unknown>={};
  if (!entry.asOperator) try {
    const effective=await getDataIdentity();
    if(effective.impersonationSessionId)impersonationMeta={effective_actor_person_id:effective.personId,impersonation_session_id:effective.impersonationSessionId};
  } catch { /* Audit metadata must not turn a committed write into a failed save. */ }
  await supabase.from("audit_log").insert({
    actor_person_id: personId,
    action: entry.action,
    target_table: entry.targetTable ?? null,
    target_id: entry.targetId ?? null,
    // The operator remains accountable; retain the verified subject and session too.
    meta: {...entry.meta,...impersonationMeta},
  });
}
