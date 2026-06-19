"use server";

import { revalidatePath } from "next/cache";

import { logAudit } from "@/lib/audit";
import { createSupabaseServerClient } from "@/lib/supabase/server";

export type FormResult = { ok: true } | { ok: false; error: string };

function pgMessage(error: { code?: string } | null, fallback: string): string {
  const code = error?.code;
  if (code === "23505")
    return "الطالب عنده تسجيل نشط بالفعل (أو الرقم القومي مكرّر).";
  if (code === "22023") return "الرقم القومي لازم يكون ١٤ رقم.";
  if (code === "42501") return "غير مصرّح — لازم تكون سوبر أدمن/أدمن/مشرف.";
  if (code === "23503") return "مرتبط بعناصر تانية.";
  return fallback;
}

// إنشاء طالب جديد + تسجيله في حلقة (RPC ذرّي enroll_student).
export async function enrollStudent(
  _p: FormResult | null,
  fd: FormData,
): Promise<FormResult> {
  const circleId = String(fd.get("circle_id") ?? "");
  const name = String(fd.get("name") ?? "").trim();
  const gender = String(fd.get("gender") ?? "male");
  const nationalId = String(fd.get("national_id") ?? "").trim();
  if (!circleId || !name) return { ok: false, error: "الاسم والحلقة مطلوبين." };
  const supabase = await createSupabaseServerClient();
  const { data, error } = await supabase.rpc("enroll_student", {
    p_circle: circleId,
    p_name: name,
    p_gender: gender,
    p_national_id: nationalId || null,
  });
  if (error) return { ok: false, error: pgMessage(error, "فشل تسجيل الطالب.") };
  await logAudit({
    action: "student_enrolled",
    targetTable: "enrollment",
    meta: { circle_id: circleId, name, person_id: data },
  });
  revalidatePath("/enrollment");
  return { ok: true };
}

// نقل بين الحلقات و/أو تغيير الحالة.
export async function updateEnrollment(
  _p: FormResult | null,
  fd: FormData,
): Promise<FormResult> {
  const id = String(fd.get("id") ?? "");
  if (!id) return { ok: false, error: "التسجيل مطلوب." };
  const patch: Record<string, unknown> = {};
  if (fd.has("circle_id")) patch.circle_id = String(fd.get("circle_id") ?? "");
  if (fd.has("status")) {
    const status = String(fd.get("status") ?? "");
    patch.status = status;
    patch.left_at = status === "active" ? null : new Date().toISOString();
  }
  if (Object.keys(patch).length === 0) return { ok: true };
  const supabase = await createSupabaseServerClient();
  const { error } = await supabase.from("enrollment").update(patch).eq("id", id);
  if (error) return { ok: false, error: pgMessage(error, "فشل تعديل التسجيل.") };
  await logAudit({
    action: "enrollment_updated",
    targetTable: "enrollment",
    targetId: id,
    meta: patch,
  });
  revalidatePath("/enrollment");
  return { ok: true };
}

export async function deleteEnrollment(
  _p: FormResult | null,
  fd: FormData,
): Promise<FormResult> {
  const id = String(fd.get("id") ?? "");
  if (!id) return { ok: false, error: "التسجيل مطلوب." };
  const supabase = await createSupabaseServerClient();
  const { error } = await supabase.from("enrollment").delete().eq("id", id);
  if (error) return { ok: false, error: pgMessage(error, "فشل حذف التسجيل.") };
  await logAudit({
    action: "enrollment_deleted",
    targetTable: "enrollment",
    targetId: id,
  });
  revalidatePath("/enrollment");
  return { ok: true };
}
