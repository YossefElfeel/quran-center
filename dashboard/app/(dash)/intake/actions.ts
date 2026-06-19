"use server";

import { revalidatePath } from "next/cache";

import { getSuperAdmin } from "@/lib/auth";
import { logAudit } from "@/lib/audit";
import { createSupabaseServerClient } from "@/lib/supabase/server";

export type FormResult = { ok: true } | { ok: false; error: string };

function pgMessage(error: { code?: string } | null, fallback: string): string {
  const code = error?.code;
  if (code === "23505") return "الطالب عنده تسجيل نشط بالفعل.";
  if (code === "42501") return "غير مصرّح — لازم تكون سوبر أدمن/أدمن/مشرف.";
  if (code === "23503") return "مرتبط بعناصر تانية.";
  return fallback;
}

// إضافة متقدّم: person جديد + صف في قائمة الانتظار.
export async function addApplicant(
  _p: FormResult | null,
  fd: FormData,
): Promise<FormResult> {
  const name = String(fd.get("name") ?? "").trim();
  const gender = String(fd.get("gender") ?? "male");
  const levelId = String(fd.get("level_id") ?? "");
  if (!name || !levelId) return { ok: false, error: "الاسم والمستوى مطلوبين." };
  const supabase = await createSupabaseServerClient();
  const { data: person, error: pErr } = await supabase
    .from("person")
    .insert({ full_name: name, gender, is_minor: true })
    .select("id")
    .single();
  if (pErr) return { ok: false, error: pgMessage(pErr, "فشل إضافة المتقدّم.") };
  const { error: wErr } = await supabase.from("waiting_list").insert({
    student_person_id: person.id as string,
    level_id: levelId,
    status: "waiting",
  });
  if (wErr) {
    // تنظيف الـ person اليتيم (مفيش معاملة ذرّية هنا — بنرجّع الحالة يدويًا).
    await supabase.from("person").delete().eq("id", person.id as string);
    return { ok: false, error: pgMessage(wErr, "فشل الإضافة لقائمة الانتظار.") };
  }
  await logAudit({
    action: "applicant_added",
    targetTable: "waiting_list",
    meta: { name, level_id: levelId, person_id: person.id },
  });
  revalidatePath("/intake");
  return { ok: true };
}

// تسجيل نتيجة اختبار تحديد المستوى + تحديث المستوى المستهدف.
export async function recordPlacement(
  _p: FormResult | null,
  fd: FormData,
): Promise<FormResult> {
  const waitingId = String(fd.get("waiting_id") ?? "");
  const studentPersonId = String(fd.get("student_person_id") ?? "");
  const resultLevelId = String(fd.get("result_level_id") ?? "");
  const notes = String(fd.get("notes") ?? "").trim();
  if (!waitingId || !studentPersonId || !resultLevelId)
    return { ok: false, error: "البيانات ناقصة." };
  const supabase = await createSupabaseServerClient();
  const admin = await getSuperAdmin();
  const { error } = await supabase.from("placement_test").insert({
    student_person_id: studentPersonId,
    supervisor_id: admin?.personId ?? null,
    result_level_id: resultLevelId,
    notes: notes || null,
  });
  if (error) return { ok: false, error: pgMessage(error, "فشل تسجيل الاختبار.") };
  const { error: uErr } = await supabase
    .from("waiting_list")
    .update({ level_id: resultLevelId })
    .eq("id", waitingId);
  if (uErr)
    return {
      ok: false,
      error: "اتسجّل الاختبار بس مش قادرين نحدّث المستوى المستهدف — جرّب تاني.",
    };
  await logAudit({
    action: "placement_recorded",
    targetTable: "placement_test",
    meta: { student_person_id: studentPersonId, result_level_id: resultLevelId },
  });
  revalidatePath("/intake");
  return { ok: true };
}

// إسناد المتقدّم لحلقة: enrollment نشط + قائمة الانتظار accepted.
export async function enrollFromWaiting(
  _p: FormResult | null,
  fd: FormData,
): Promise<FormResult> {
  const waitingId = String(fd.get("waiting_id") ?? "");
  const studentPersonId = String(fd.get("student_person_id") ?? "");
  const circleId = String(fd.get("circle_id") ?? "");
  if (!waitingId || !studentPersonId || !circleId)
    return { ok: false, error: "اختر حلقة." };
  const supabase = await createSupabaseServerClient();
  const { error } = await supabase.from("enrollment").insert({
    student_person_id: studentPersonId,
    circle_id: circleId,
    status: "active",
  });
  if (error) return { ok: false, error: pgMessage(error, "فشل الإسناد لحلقة.") };
  const { error: uErr } = await supabase
    .from("waiting_list")
    .update({ status: "accepted" })
    .eq("id", waitingId);
  if (uErr)
    return {
      ok: false,
      error: "اتسجّل الطالب بس مش قادرين نحدّث قائمة الانتظار — حدّثها يدويًا.",
    };
  await logAudit({
    action: "waiting_enrolled",
    targetTable: "enrollment",
    meta: { student_person_id: studentPersonId, circle_id: circleId },
  });
  revalidatePath("/intake");
  return { ok: true };
}

// تغيير حالة قائمة الانتظار (رفض/انتهاء).
export async function setWaitingStatus(
  _p: FormResult | null,
  fd: FormData,
): Promise<FormResult> {
  const id = String(fd.get("id") ?? "");
  const status = String(fd.get("status") ?? "");
  if (!id || !status) return { ok: false, error: "البيانات ناقصة." };
  const supabase = await createSupabaseServerClient();
  const { error } = await supabase
    .from("waiting_list")
    .update({ status })
    .eq("id", id);
  if (error) return { ok: false, error: pgMessage(error, "فشل تغيير الحالة.") };
  await logAudit({
    action: "waiting_status",
    targetTable: "waiting_list",
    targetId: id,
    meta: { status },
  });
  revalidatePath("/intake");
  return { ok: true };
}
