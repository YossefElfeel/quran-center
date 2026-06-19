"use server";

import { revalidatePath } from "next/cache";
import { redirect } from "next/navigation";

import { createSupabaseServerClient } from "@/lib/supabase/server";

import { SETTINGS } from "./meta";

// تحديث العتبات. الكتابة محمية بـ RLS (settings_superadmin_write = is_super_admin)،
// فحتى لو اتنادت من غير سوبر أدمن، السيرفر بيرفض.
export async function updateSettings(formData: FormData) {
  const supabase = await createSupabaseServerClient();

  for (const s of SETTINGS) {
    const raw = formData.get(s.key);
    if (raw == null) continue;
    const num = Number(raw);
    if (Number.isNaN(num)) continue;
    const clamped = Math.min(s.max, Math.max(s.min, Math.round(num)));
    await supabase
      .from("system_settings")
      .update({ value: clamped })
      .eq("key", s.key);
  }

  revalidatePath("/settings");
  redirect("/settings?saved=1");
}
