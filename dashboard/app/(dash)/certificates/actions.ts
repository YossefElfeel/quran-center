"use server";
import { validateAction } from "@/lib/action-schemas";

import { z } from "zod";
import { revalidatePath } from "next/cache";


import { logAudit } from "@/lib/audit";
import { getDataClient, getDataIdentity } from "@/lib/supabase/data-client";

export type FormResult = { ok: true; certificateId?:string } | { ok: false; error: string };

// إصدار شهادة. الـ trigger بيفرض الأهلية لكل الأنواع عدا 'honor' (تكريم — يتخطّى).
export async function issueCertificate(
  _p: FormResult | null,
  fd: FormData,
): Promise<FormResult> {
  const formError = validateAction("issueCertificate", fd);
  if (formError) return formError;

  const studentPersonId = String(fd.get("student_person_id") ?? "");
  const kind = String(fd.get("kind") ?? "");
  if (!z.object({studentPersonId:z.uuid(),kind:z.enum(["juz_amma","half","full","honor"])}).safeParse({studentPersonId,kind}).success) return { ok: false, error: "بيانات ناقصة." };
  const supabase = await getDataClient();
  const actor = await getDataIdentity();
  const { data, error } = await supabase
    .from("certificate")
    .insert({
      student_person_id: studentPersonId,
      kind,
      approved_by: actor.personId,
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
  return { ok: true,certificateId:data.id as string };
}

export async function revokeCertificate(
  _p: FormResult | null,
  fd: FormData,
): Promise<FormResult> {
  const formError = validateAction("revokeCertificate", fd);
  if (formError) return formError;

  const id = String(fd.get("id") ?? "");
  if (!id) return { ok: false, error: "الشهادة مطلوبة." };
  const supabase = await getDataClient();
  const { error } = await supabase.from("certificate").delete().eq("id", id).select("id").single();
  if (error) return { ok: false, error: "فشل سحب الشهادة." };
  await logAudit({
    action: "certificate_revoked",
    targetTable: "certificate",
    targetId: id,
  });
  revalidatePath("/certificates");
  return { ok: true };
}
