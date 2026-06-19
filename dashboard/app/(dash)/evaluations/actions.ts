"use server";

import { revalidatePath } from "next/cache";

import { logAudit } from "@/lib/audit";
import { createSupabaseServerClient } from "@/lib/supabase/server";

export type FormResult = { ok: true } | { ok: false; error: string };

// اعتماد تطوّر المعلّم (الـ trigger بيملأ approved_by/at ويسمح للسوبر أدمن).
export async function approveDevelopment(
  _p: FormResult | null,
  fd: FormData,
): Promise<FormResult> {
  const id = String(fd.get("id") ?? "");
  if (!id) return { ok: false, error: "العنصر مطلوب." };
  const supabase = await createSupabaseServerClient();
  const { error } = await supabase
    .from("teacher_development")
    .update({ status: "approved" })
    .eq("id", id);
  if (error) return { ok: false, error: "فشل الاعتماد." };
  await logAudit({
    action: "development_approved",
    targetTable: "teacher_development",
    targetId: id,
  });
  revalidatePath("/evaluations");
  return { ok: true };
}

// اعتماد التقييم الشهري للطالب.
export async function approveMonthlyEval(
  _p: FormResult | null,
  fd: FormData,
): Promise<FormResult> {
  const id = String(fd.get("id") ?? "");
  if (!id) return { ok: false, error: "العنصر مطلوب." };
  const supabase = await createSupabaseServerClient();
  const { error } = await supabase
    .from("monthly_student_evaluation")
    .update({ status: "approved" })
    .eq("id", id);
  if (error) return { ok: false, error: "فشل الاعتماد." };
  await logAudit({
    action: "monthly_eval_approved",
    targetTable: "monthly_student_evaluation",
    targetId: id,
  });
  revalidatePath("/evaluations");
  return { ok: true };
}

// إخفاء/إظهار تقييم محفّظ من ولي أمر.
export async function setRatingHidden(
  _p: FormResult | null,
  fd: FormData,
): Promise<FormResult> {
  const id = String(fd.get("id") ?? "");
  const hidden = String(fd.get("hidden") ?? "true") === "true";
  if (!id) return { ok: false, error: "العنصر مطلوب." };
  const supabase = await createSupabaseServerClient();
  const { error } = await supabase
    .from("teacher_rating")
    .update({
      hidden_by_manager: hidden,
      hidden_reason: hidden ? "أُخفي من اللوحة" : null,
    })
    .eq("id", id);
  if (error) return { ok: false, error: "فشل تغيير الحالة." };
  await logAudit({
    action: hidden ? "rating_hidden" : "rating_shown",
    targetTable: "teacher_rating",
    targetId: id,
  });
  revalidatePath("/evaluations");
  return { ok: true };
}
