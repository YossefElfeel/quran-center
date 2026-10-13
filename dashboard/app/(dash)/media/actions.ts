"use server";
import { validateAction } from "@/lib/action-schemas";

import { revalidatePath } from "next/cache";

import { logAudit } from "@/lib/audit";
import { getDataClient } from "@/lib/supabase/data-client";

export type FormResult = { ok: true } | { ok: false; error: string };

// حذف ناعم / استرجاع للوسيط (retained flag — سياسة الاحتفاظ).
export async function setMediaRetained(
  _p: FormResult | null,
  fd: FormData,
): Promise<FormResult> {
  const formError = validateAction("setMediaRetained", fd);
  if (formError) return formError;

  const id = String(fd.get("id") ?? "");
  const retained = String(fd.get("retained") ?? "true") === "true";
  if (!id) return { ok: false, error: "الوسيط مطلوب." };
  const supabase = await getDataClient();
  const { error } = await supabase
    .from("media")
    .update({ retained })
    .eq("id", id).select("id").single();
  if (error) return { ok: false, error: "فشل التحديث." };
  await logAudit({
    action: retained ? "media_restored" : "media_soft_deleted",
    targetTable: "media",
    targetId: id,
  });
  revalidatePath("/media");
  return { ok: true };
}

// حذف نهائي لصفّ الوسيط (ملف التخزين بيتنضّف عبر مهمة منفصلة).
export async function deleteMedia(
  _p: FormResult | null,
  fd: FormData,
): Promise<FormResult> {
  const formError = validateAction("deleteMedia", fd);
  if (formError) return formError;

  const id = String(fd.get("id") ?? "");
  if (!id) return { ok: false, error: "الوسيط مطلوب." };
  const supabase = await getDataClient();
  const { error } = await supabase.from("media").delete().eq("id", id).select("id").single();
  if (error) return { ok: false, error: "فشل الحذف." };
  await logAudit({ action: "media_deleted", targetTable: "media", targetId: id });
  revalidatePath("/media");
  return { ok: true };
}
