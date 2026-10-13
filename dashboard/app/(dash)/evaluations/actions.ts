"use server";
import { validateAction } from "@/lib/action-schemas";

import { revalidatePath } from "next/cache";

import { logAudit } from "@/lib/audit";
import { getDataClient } from "@/lib/supabase/data-client";

import { z } from "zod";

export type FormResult = { ok: true } | { ok: false; error: string };

// اعتماد تطوّر المعلّم (الـ trigger بيملأ approved_by/at ويسمح للسوبر أدمن).
export async function approveDevelopment(
  _p: FormResult | null,
  fd: FormData,
): Promise<FormResult> {
  const formError = validateAction("approveDevelopment", fd);
  if (formError) return formError;

  const id = String(fd.get("id") ?? "");
  if (!id) return { ok: false, error: "العنصر مطلوب." };
  const supabase = await getDataClient();
  const { error } = await supabase
    .from("teacher_development")
    .update({ status: "approved" })
    .eq("id", id).select("id").single();
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
  const formError = validateAction("approveMonthlyEval", fd);
  if (formError) return formError;

  const id = String(fd.get("id") ?? "");
  if (!id) return { ok: false, error: "العنصر مطلوب." };
  const supabase = await getDataClient();
  const { error } = await supabase
    .from("monthly_student_evaluation")
    .update({ status: "approved" })
    .eq("id", id).select("id").single();
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
  const formError = validateAction("setRatingHidden", fd);
  if (formError) return formError;

  const id = String(fd.get("id") ?? "");
  const hidden = String(fd.get("hidden") ?? "true") === "true";
  if (!id) return { ok: false, error: "العنصر مطلوب." };
  const supabase = await getDataClient();
  const { error } = await supabase
    .from("teacher_rating")
    .update({
      hidden_by_manager: hidden,
      hidden_reason: hidden ? "أُخفي من اللوحة" : null,
    })
    .eq("id", id).select("id").single();
  if (error) return { ok: false, error: "فشل تغيير الحالة." };
  await logAudit({
    action: hidden ? "rating_hidden" : "rating_shown",
    targetTable: "teacher_rating",
    targetId: id,
  });
  revalidatePath("/evaluations");
  return { ok: true };
}

export async function returnEvaluation(_previous: FormResult | null, fd: FormData): Promise<FormResult> {
  const formError = validateAction("returnEvaluation", fd);
  if (formError) return formError;

  const parsed = z.object({ id: z.uuid(), table: z.enum(['teacher_development','monthly_student_evaluation']), reason: z.string().trim().min(1).max(2000) }).safeParse(Object.fromEntries(fd));
  if (!parsed.success) return {ok:false,error:'اكتب سبب الإرجاع.'};
  const {id,table,reason}=parsed.data;
  const client=await getDataClient();
  const {error}=await client.from(table).update({status:'returned',return_reason:reason}).eq('id',id).eq('status','submitted').select('id').single();
  if (error) return {ok:false,error:'تعذّر إرجاع التقييم.'};
  await logAudit({action:'evaluation_returned',targetTable:table,targetId:id,meta:{reason}});
  revalidatePath('/evaluations');return {ok:true};
}
