"use server";

import { revalidatePath } from "next/cache";

import { getSuperAdmin } from "@/lib/auth";
import { logAudit } from "@/lib/audit";
import { createSupabaseServerClient } from "@/lib/supabase/server";

export type FormResult = { ok: true } | { ok: false; error: string };

// إصدار شهادة. الـ trigger بيفرض الأهلية لكل الأنواع عدا 'honor' (تكريم — يتخطّى).
export async function issueCertificate(
  _p: FormResult | null,
  fd: FormData,
): Promise<FormResult> {
  const studentPersonId = String(fd.get("student_person_id") ?? "");
  const kind = String(fd.get("kind") ?? "");
  if (!studentPersonId || !kind) return { ok: false, error: "بيانات ناقصة." };
  const supabase = await createSupabaseServerClient();
  const admin = await getSuperAdmin();
  const { data, error } = await supabase
    .from("certificate")
    .insert({
      student_person_id: studentPersonId,
      kind,
      approved_by: admin?.personId ?? null,
    })
    .select("id")
    .single();
  if (error) {
    const msg = (error as { message?: string }).message ?? "";
    if (msg.includes("not eligible")) {
      return {
        ok: false,
        error:
          "الطالب مش مؤهّل لشهادة إتمام (لازم يعدّي كل المقاطع). استخدم «تكريم» لو ده تقدير.",
      };
    }
    return { ok: false, error: "فشل إصدار الشهادة." };
  }
  await logAudit({
    action: "certificate_issued",
    targetTable: "certificate",
    targetId: data.id as string,
    meta: { student_person_id: studentPersonId, kind },
  });
  revalidatePath("/certificates");
  return { ok: true };
}

export async function revokeCertificate(
  _p: FormResult | null,
  fd: FormData,
): Promise<FormResult> {
  const id = String(fd.get("id") ?? "");
  if (!id) return { ok: false, error: "الشهادة مطلوبة." };
  const supabase = await createSupabaseServerClient();
  const { error } = await supabase.from("certificate").delete().eq("id", id);
  if (error) return { ok: false, error: "فشل سحب الشهادة." };
  await logAudit({
    action: "certificate_revoked",
    targetTable: "certificate",
    targetId: id,
  });
  revalidatePath("/certificates");
  return { ok: true };
}
