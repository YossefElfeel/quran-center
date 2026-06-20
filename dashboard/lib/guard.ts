import { logAudit } from "@/lib/audit";
import { getSuperAdmin, type SuperAdmin } from "@/lib/auth";

// نتيجة موحّدة لكل server actions في اللوحة.
export type FormResult = { ok: true } | { ok: false; error: string };

// غلاف server-side للعمليات المباشرة على قاعدة البيانات (مش عبر Edge functions):
// إعدادات/مفاتيح/إشعارات/مجدولات. بيعيد التأكّد إن النده سوبر أدمن، بيفرض سبب،
// بينفّذ العملية، وبيسجّلها في audit_log. تسجيل التدقيق ده هو اللي بيشغّل التنبيهات
// الفورية لاحقًا (trigger على audit_log في M7) — فاسم الـ action مهم.
export async function guardedAction(opts: {
  action: string;
  reason: string;
  targetTable?: string;
  targetId?: string;
  meta?: Record<string, unknown>;
  run: (
    admin: SuperAdmin,
  ) => Promise<{ error?: { message?: string } | string | null } | void>;
}): Promise<FormResult> {
  const admin = await getSuperAdmin();
  if (!admin) {
    return { ok: false, error: "غير مصرّح — لازم تكون سوبر أدمن نشط." };
  }
  const reason = opts.reason?.trim();
  if (!reason) return { ok: false, error: "السبب مطلوب." };

  try {
    const res = await opts.run(admin);
    const err = res && "error" in res ? res.error : null;
    if (err) {
      const msg = typeof err === "string" ? err : (err.message ?? "");
      return { ok: false, error: msg || "فشل التنفيذ." };
    }
  } catch {
    return { ok: false, error: "فشل التنفيذ — جرّب تاني." };
  }

  await logAudit({
    action: opts.action,
    targetTable: opts.targetTable,
    targetId: opts.targetId,
    meta: { ...(opts.meta ?? {}), reason },
  });
  return { ok: true };
}
