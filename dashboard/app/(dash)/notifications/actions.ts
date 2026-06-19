"use server";

import { revalidatePath } from "next/cache";

import { logAudit } from "@/lib/audit";
import { createSupabaseServerClient } from "@/lib/supabase/server";

export type FormResult = { ok: true } | { ok: false; error: string };

const ROLES = ["super_admin", "admin", "supervisor", "teacher", "parent"];

// بثّ إشعار لجمهور (كل المستخدمين أو دور معيّن) — صف لكل مستلم.
export async function broadcast(
  _p: FormResult | null,
  fd: FormData,
): Promise<FormResult> {
  const audience = String(fd.get("audience") ?? "");
  const title = String(fd.get("title") ?? "").trim();
  const body = String(fd.get("body") ?? "").trim();
  if (!title) return { ok: false, error: "العنوان مطلوب." };
  if (!audience) return { ok: false, error: "اختر الجمهور." };

  const supabase = await createSupabaseServerClient();
  let ids: string[] = [];
  if (audience === "all") {
    const { data } = await supabase.from("app_user").select("person_id");
    ids = (data ?? []).map((r: { person_id: string }) => r.person_id);
  } else if (ROLES.includes(audience)) {
    const { data } = await supabase
      .from("role_assignment")
      .select("person_id")
      .eq("role", audience);
    ids = (data ?? []).map((r: { person_id: string }) => r.person_id);
  } else {
    return { ok: false, error: "جمهور غير صحيح." };
  }

  const unique = [...new Set(ids)];
  if (unique.length === 0)
    return { ok: false, error: "مفيش مستلمين للجمهور ده." };
  const rows = unique.map((pid) => ({
    recipient_person_id: pid,
    type: "broadcast",
    title,
    body: body || null,
  }));
  const { error } = await supabase.from("notification").insert(rows);
  if (error) return { ok: false, error: "فشل الإرسال." };
  await logAudit({
    action: "broadcast_sent",
    targetTable: "notification",
    meta: { audience, title, count: unique.length },
  });
  revalidatePath("/notifications");
  return { ok: true };
}

// سحب (حذف) إشعار مُرسَل — يحتاج سياسة notification_admin_delete (migration 0009).
export async function retractNotification(
  _p: FormResult | null,
  fd: FormData,
): Promise<FormResult> {
  const id = String(fd.get("id") ?? "");
  if (!id) return { ok: false, error: "الإشعار مطلوب." };
  const supabase = await createSupabaseServerClient();
  const { error } = await supabase.from("notification").delete().eq("id", id);
  if (error) return { ok: false, error: "فشل السحب." };
  await logAudit({
    action: "notification_retracted",
    targetTable: "notification",
    targetId: id,
  });
  revalidatePath("/notifications");
  return { ok: true };
}
