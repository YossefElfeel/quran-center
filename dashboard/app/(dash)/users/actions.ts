"use server";

import { revalidatePath } from "next/cache";

import { createSupabaseServerClient } from "@/lib/supabase/server";

export type InviteResult =
  | { ok: true; actionLink: string | null }
  | { ok: false; error: string };

export type ResetResult =
  | { ok: true; actionLink: string | null }
  | { ok: false; error: string };

export type ActionResult = { ok: true } | { ok: false; error: string };

// يدعو مستخدم عبر Edge Function invite-user (بتشتغل بهوية الـ super_admin/admin
// الحالي + service-role داخليًا). بترجّع رابط الدعوة عشان يتبعت للمستخدم.
export async function inviteUser(
  _prev: InviteResult | null,
  formData: FormData,
): Promise<InviteResult> {
  const email = String(formData.get("email") ?? "").trim();
  const fullName = String(formData.get("full_name") ?? "").trim();
  const role = String(formData.get("role") ?? "");

  if (!email || !fullName || !role) {
    return { ok: false, error: "كل الحقول مطلوبة." };
  }

  const supabase = await createSupabaseServerClient();
  const { data, error } = await supabase.functions.invoke("invite-user", {
    body: { email, full_name: fullName, role },
  });

  if (error) {
    return {
      ok: false,
      error:
        "فشل إرسال الدعوة — اتأكد إن وظيفة invite-user منشورة وإن حسابك أدمن/سوبر أدمن.",
    };
  }

  const actionLink =
    (data as { action_link?: string } | null)?.action_link ?? null;
  return { ok: true, actionLink };
}

// ترجمة أكواد الأخطاء القادمة من Edge functions لرسائل عربية.
function mapError(raw: string): string {
  const map: Record<string, string> = {
    "cannot block yourself": "مينفعش تحظر نفسك.",
    "cannot delete yourself": "مينفعش تحذف نفسك.",
    "cannot block the last super_admin": "مينفعش تحظر آخر سوبر أدمن.",
    "cannot delete the last super_admin": "مينفعش تحذف آخر سوبر أدمن.",
    "cannot remove the last super_admin": "مينفعش تشيل آخر سوبر أدمن.",
    "cannot revoke your own super_admin":
      "مينفعش تسحب صلاحية السوبر أدمن من نفسك.",
    "reason required": "السبب مطلوب.",
    "confirm must equal full_name": "اكتب الاسم الكامل بالظبط للتأكيد.",
    forbidden: "غير مصرّح — لازم تكون سوبر أدمن نشط.",
    unauthorized: "محتاج تسجّل دخول.",
    "target not found": "المستخدم مش موجود.",
    "valid role required": "اختر دور صحيح.",
    "subject has no login account": "المستخدم ده ماعندوش حساب دخول.",
    "subject has no email": "المستخدم ده ماعندوش إيميل.",
    "failed to generate link": "فشل توليد الرابط — جرّب تاني.",
  };
  if (map[raw]) return map[raw];
  if (raw.startsWith("cannot hard-delete")) {
    return "فيه سجلّات مرتبطة بالمستخدم — استخدم الإيقاف (حذف ناعم) بدل الحذف النهائي.";
  }
  return "فشل تنفيذ العملية — جرّب تاني.";
}

// بيستخرج رسالة الخطأ التفصيلية من رد Edge function (body JSON: {error}).
async function edgeDetail(error: unknown): Promise<string> {
  try {
    const ctx = (error as { context?: Response }).context;
    if (ctx && typeof ctx.json === "function") {
      const j = (await ctx.json()) as { error?: string };
      return j?.error ?? "";
    }
  } catch {
    // تجاهل.
  }
  return "";
}

// استدعاء Edge function ومعالجة الخطأ (الوظيفة بترجّع JSON: {error} عند الفشل).
async function invokeAdmin(
  fn: string,
  body: Record<string, unknown>,
): Promise<ActionResult> {
  const supabase = await createSupabaseServerClient();
  const { data, error } = await supabase.functions.invoke(fn, { body });

  if (error) {
    const detail = await edgeDetail(error);
    return { ok: false, error: detail ? mapError(detail) : mapError("") };
  }
  if (data && (data as { error?: string }).error) {
    return { ok: false, error: mapError((data as { error: string }).error) };
  }

  revalidatePath("/users");
  return { ok: true };
}

// حظر/فك حظر مستخدم.
export async function blockUser(
  _prev: ActionResult | null,
  formData: FormData,
): Promise<ActionResult> {
  const targetPersonId = String(formData.get("target_person_id") ?? "");
  const block = String(formData.get("block") ?? "true") === "true";
  const reason = String(formData.get("reason") ?? "").trim();
  if (!targetPersonId) return { ok: false, error: "المستخدم مطلوب." };
  if (block && !reason) return { ok: false, error: "السبب مطلوب." };
  return invokeAdmin("block-user", {
    target_person_id: targetPersonId,
    block,
    reason: reason || null,
  });
}

// إيقاف ناعم / استرجاع / حذف نهائي.
export async function deleteUser(
  _prev: ActionResult | null,
  formData: FormData,
): Promise<ActionResult> {
  const targetPersonId = String(formData.get("target_person_id") ?? "");
  const mode = String(formData.get("mode") ?? "soft");
  const reason = String(formData.get("reason") ?? "").trim();
  const confirm = String(formData.get("confirm") ?? "").trim();
  if (!targetPersonId) return { ok: false, error: "المستخدم مطلوب." };
  if (mode !== "restore" && !reason) return { ok: false, error: "السبب مطلوب." };
  return invokeAdmin("delete-user", {
    target_person_id: targetPersonId,
    mode,
    reason: reason || null,
    confirm: confirm || null,
  });
}

// منح/سحب دور.
export async function manageRole(
  _prev: ActionResult | null,
  formData: FormData,
): Promise<ActionResult> {
  const targetPersonId = String(formData.get("target_person_id") ?? "");
  const role = String(formData.get("role") ?? "");
  const op = String(formData.get("op") ?? "grant");
  if (!targetPersonId || !role) return { ok: false, error: "بيانات ناقصة." };
  return invokeAdmin("manage-role", {
    target_person_id: targetPersonId,
    role,
    op,
  });
}

// تسجيل خروج إجباري — عبر RPC admin_force_logout (بيمسح جلسات المستخدم). الدالة
// بتسجّل التدقيق بنفسها (action = force_logout)، فمابنستخدمش guardedAction.
export async function forceLogout(
  _prev: ActionResult | null,
  formData: FormData,
): Promise<ActionResult> {
  const targetPersonId = String(formData.get("target_person_id") ?? "");
  const reason = String(formData.get("reason") ?? "").trim();
  if (!targetPersonId) return { ok: false, error: "المستخدم مطلوب." };
  if (!reason) return { ok: false, error: "السبب مطلوب." };
  const supabase = await createSupabaseServerClient();
  const { error } = await supabase.rpc("admin_force_logout", {
    p_person: targetPersonId,
    p_reason: reason,
  });
  if (error) return { ok: false, error: mapError(error.message) };
  revalidatePath("/users");
  return { ok: true };
}

// إعادة كلمة السر — عبر Edge Function reset-password (بترجّع رابط استرجاع للأدمن).
export async function resetPassword(
  _prev: ResetResult | null,
  formData: FormData,
): Promise<ResetResult> {
  const targetPersonId = String(formData.get("target_person_id") ?? "");
  const reason = String(formData.get("reason") ?? "").trim();
  if (!targetPersonId) return { ok: false, error: "المستخدم مطلوب." };
  if (!reason) return { ok: false, error: "السبب مطلوب." };
  const supabase = await createSupabaseServerClient();
  const { data, error } = await supabase.functions.invoke("reset-password", {
    body: { target_person_id: targetPersonId, reason },
  });
  if (error) {
    const detail = await edgeDetail(error);
    return { ok: false, error: detail ? mapError(detail) : mapError("") };
  }
  if (data && (data as { error?: string }).error) {
    return { ok: false, error: mapError((data as { error: string }).error) };
  }
  const actionLink =
    (data as { action_link?: string } | null)?.action_link ?? null;
  return { ok: true, actionLink };
}
