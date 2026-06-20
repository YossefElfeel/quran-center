"use server";

import { revalidatePath } from "next/cache";

import { guardedAction, type FormResult } from "@/lib/guard";
import { createSupabaseServerClient } from "@/lib/supabase/server";

// تبديل حالة مفتاح. كتابة محمية بـ RLS (سوبر أدمن بس) + سبب مطلوب + تسجيل تدقيق
// (اللي بيشغّل التنبيه الفوري في M7). enabled = الحالة الجديدة المطلوبة.
export async function toggleFlag(
  _p: FormResult | null,
  fd: FormData,
): Promise<FormResult> {
  const key = String(fd.get("key") ?? "");
  const enabled = String(fd.get("enabled") ?? "") === "true";
  const reason = String(fd.get("reason") ?? "");
  if (!key) return { ok: false, error: "المفتاح مطلوب." };

  const result = await guardedAction({
    action: "flag_toggle",
    targetTable: "feature_flag",
    targetId: key,
    reason,
    meta: { key, enabled },
    run: async (admin) => {
      const supabase = await createSupabaseServerClient();
      return supabase
        .from("feature_flag")
        .update({ enabled, updated_by: admin.personId })
        .eq("key", key);
    },
  });

  if (result.ok) revalidatePath("/flags");
  return result;
}
