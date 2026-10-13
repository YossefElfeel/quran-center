"use server";
import { normalizeNumber, validationError } from "@/lib/validation";
import { z } from "zod";
import { revalidatePath } from "next/cache";
import { guardedAction, type FormResult } from "@/lib/guard";
import { getDataClient } from "@/lib/supabase/data-client";
import { SETTINGS } from "./meta";

export async function updateSettings(_previous: FormResult | null, formData: FormData): Promise<FormResult> {
  const shape = Object.fromEntries(SETTINGS.map(setting => [setting.key,
    z.preprocess(value => value === "" || value == null ? NaN : Number(normalizeNumber(String(value))), z.number().int("اكتب عددًا صحيحًا").min(setting.min, `الحد الأدنى ${setting.min}`).max(setting.max, `الحد الأقصى ${setting.max}`)),
  ]));
  const parsed = z.object({ ...shape,
    center_name: z.string().trim().min(1,"اكتب اسم الدار").max(200),
    center_phone: z.string().transform(value => normalizeNumber(value.trim()).replace(/[\s()-]/g, "")).refine(value => !value || /^\+?[0-9]{10,15}$/.test(value), "اكتب رقمًا صحيحًا بكود الدولة"),
    center_address: z.string().trim().max(2000,"العنوان أطول من اللازم"),
    reason: z.string().trim().min(1,"اكتب سبب التغيير").max(2000),
  }).safeParse(Object.fromEntries(formData));
  const invalid = validationError(parsed);
  if (invalid) return invalid;
  const values: Record<string, number | string> = {};
  for (const setting of SETTINGS) {
    const value = Number(normalizeNumber(String(formData.get(setting.key)??"")));
    if (!Number.isFinite(value) || !Number.isInteger(value) || value < setting.min || value > setting.max) return { ok: false, error: `راجع قيمة «${setting.label}».` };
    values[setting.key] = value;
  }
  const phone = normalizeNumber(String(formData.get("center_phone") ?? "").trim()).replace(/[\s()-]/g,"");
  if (phone && !/^\+?[0-9]{10,15}$/.test(phone)) return { ok: false, error: "رقم الإدارة غير صحيح. استخدم كود الدولة لواتساب." };
  values.center_phone = phone;
  values.center_name = String(formData.get("center_name") ?? "").trim();
  values.center_address = String(formData.get("center_address") ?? "").trim();
  if (!values.center_name) return { ok: false, error: "اسم الدار مطلوب." };
  const result = await guardedAction({ action: "settings_updated", reason: String(formData.get("reason") ?? ""), targetTable: "system_settings", run: async () => {
    const supabase = await getDataClient();
    const { error } = await supabase.rpc("update_center_settings", { p_values: values });
    return { error: error ? "تعذّر حفظ الإعدادات — راجع الاتصال وصلاحيات الحساب." : null };
  }});
  if (result.ok) revalidatePath("/settings");
  return result;
}
