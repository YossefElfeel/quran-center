"use server";
import { validateAction } from "@/lib/action-schemas";

import { revalidatePath } from "next/cache";

import { guardedAction, type FormResult } from "@/lib/guard";
import { getDataClient } from "@/lib/supabase/data-client";

// تبديل حالة مفتاح. كتابة محمية بـ RLS (سوبر أدمن بس) + سبب مطلوب + تسجيل تدقيق
// (اللي بيشغّل التنبيه الفوري في M7). enabled = الحالة الجديدة المطلوبة.
export async function toggleFlag(
  _p: FormResult | null,
  fd: FormData,
): Promise<FormResult> {
  const formError = validateAction("toggleFlag", fd);
  if (formError) return formError;

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
      const supabase = await getDataClient();
      return supabase
        .from("feature_flag")
        .update({ enabled, updated_by: admin.personId })
        .eq("key", key).select("key").single();
    },
  });

  if (result.ok) revalidatePath("/flags");
  return result;
}
