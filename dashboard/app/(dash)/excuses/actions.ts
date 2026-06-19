"use server";

import { revalidatePath } from "next/cache";

import { getSuperAdmin } from "@/lib/auth";
import { logAudit } from "@/lib/audit";
import { createSupabaseServerClient } from "@/lib/supabase/server";

export type FormResult = { ok: true } | { ok: false; error: string };

// قرار عذر غياب: موافقة/رفض. الموافقة بتحدّث حضور الحصة لـ absent_excused (محايد).
export async function decideExcuse(
  _p: FormResult | null,
  fd: FormData,
): Promise<FormResult> {
  const id = String(fd.get("id") ?? "");
  const decision = String(fd.get("decision") ?? "");
  const enrollmentId = String(fd.get("enrollment_id") ?? "");
  const sessionId = String(fd.get("session_id") ?? "");
  if (!id || (decision !== "approved" && decision !== "rejected"))
    return { ok: false, error: "بيانات ناقصة." };

  const supabase = await createSupabaseServerClient();
  const admin = await getSuperAdmin();
  const { error } = await supabase
    .from("excuse_request")
    .update({
      status: decision,
      decided_by: admin?.personId ?? null,
      decided_at: new Date().toISOString(),
    })
    .eq("id", id);
  if (error) return { ok: false, error: "فشل تنفيذ القرار." };

  if (decision === "approved" && sessionId && enrollmentId) {
    const { error: aErr } = await supabase.from("attendance").upsert(
      {
        session_id: sessionId,
        enrollment_id: enrollmentId,
        status: "absent_excused",
        excuse_approved_by: admin?.personId ?? null,
      },
      { onConflict: "session_id,enrollment_id" },
    );
    if (aErr)
      return {
        ok: false,
        error: "اتسجّل القرار بس مش قادرين نحدّث الحضور — جرّب تاني.",
      };
  }

  await logAudit({
    action: "excuse_decided",
    targetTable: "excuse_request",
    targetId: id,
    meta: { decision },
  });
  revalidatePath("/excuses");
  return { ok: true };
}
