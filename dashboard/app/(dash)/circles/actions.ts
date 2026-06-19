"use server";

import { revalidatePath } from "next/cache";

import { getSuperAdmin } from "@/lib/auth";
import { logAudit } from "@/lib/audit";
import { createSupabaseServerClient } from "@/lib/supabase/server";

export type FormResult = { ok: true } | { ok: false; error: string };

// تصحيح إداري لحالة الدفتر (الدَيْن) لطالب على مقطع — upsert (بينشئ صف لو مش موجود).
// مسموح للسوبر أدمن عبر RLS (ledger_write). بيتسجّل في التدقيق. ملاحظة: triggers
// المحرّك (journey/struggling) بتشتغل بعد التحديث كأنها حالة حقيقية — وده المقصود.
export async function correctLedger(
  _p: FormResult | null,
  fd: FormData,
): Promise<FormResult> {
  const studentPersonId = String(fd.get("student_person_id") ?? "");
  const portionId = String(fd.get("portion_id") ?? "");
  const circleId = String(fd.get("circle_id") ?? "");
  const state = String(fd.get("state") ?? "");
  if (!studentPersonId || !portionId || !state)
    return { ok: false, error: "بيانات ناقصة." };
  const supabase = await createSupabaseServerClient();
  const { error } = await supabase.from("portion_ledger_entry").upsert(
    {
      student_person_id: studentPersonId,
      portion_id: portionId,
      state,
      passed_on:
        state === "passed" ? new Date().toISOString().slice(0, 10) : null,
    },
    { onConflict: "student_person_id,portion_id" },
  );
  if (error) return { ok: false, error: "فشل تصحيح الدفتر." };
  await logAudit({
    action: "ledger_corrected",
    targetTable: "portion_ledger_entry",
    meta: { student_person_id: studentPersonId, portion_id: portionId, state },
  });
  revalidatePath(`/circles/${circleId}`);
  return { ok: true };
}

export async function addBehavioralNote(
  _p: FormResult | null,
  fd: FormData,
): Promise<FormResult> {
  const studentPersonId = String(fd.get("student_person_id") ?? "");
  const circleId = String(fd.get("circle_id") ?? "");
  const text = String(fd.get("text") ?? "").trim();
  const visibility = String(fd.get("visibility") ?? "internal");
  if (!studentPersonId || !text) return { ok: false, error: "بيانات ناقصة." };
  const supabase = await createSupabaseServerClient();
  const admin = await getSuperAdmin();
  const { data, error } = await supabase
    .from("behavioral_note")
    .insert({
      student_person_id: studentPersonId,
      teacher_id: admin?.personId ?? null,
      text,
      visibility,
    })
    .select("id")
    .single();
  if (error) return { ok: false, error: "فشل إضافة الملاحظة." };
  await logAudit({
    action: "note_added",
    targetTable: "behavioral_note",
    targetId: data.id as string,
    meta: { student_person_id: studentPersonId, visibility },
  });
  revalidatePath(`/circles/${circleId}`);
  return { ok: true };
}

export async function deleteBehavioralNote(
  _p: FormResult | null,
  fd: FormData,
): Promise<FormResult> {
  const id = String(fd.get("id") ?? "");
  const circleId = String(fd.get("circle_id") ?? "");
  if (!id) return { ok: false, error: "الملاحظة مطلوبة." };
  const supabase = await createSupabaseServerClient();
  const { error } = await supabase.from("behavioral_note").delete().eq("id", id);
  if (error) return { ok: false, error: "فشل حذف الملاحظة." };
  await logAudit({
    action: "note_deleted",
    targetTable: "behavioral_note",
    targetId: id,
  });
  revalidatePath(`/circles/${circleId}`);
  return { ok: true };
}
