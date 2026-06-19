"use server";

import { createSupabaseServerClient } from "@/lib/supabase/server";

export type InviteResult =
  | { ok: true; actionLink: string | null }
  | { ok: false; error: string };

// يدعو مستخدم عبر Edge Function invite-user (بتشتغل بهوية الـ super_admin/admin
// الحالي + service-role داخليًا). بترجّع رابط الدعوة عشان يتبعت للمستخدم.
export async function inviteUser(
  _prev: InviteResult | null,
  formData: FormData,
): Promise<InviteResult> {
  const email = String(formData.get("email") ?? "").trim();
  const fullName = String(formData.get("full_name") ?? "").trim();
  const role = String(formData.get("role") ?? "");

  if (!email || !fullName || !role) {
    return { ok: false, error: "كل الحقول مطلوبة." };
  }

  const supabase = await createSupabaseServerClient();
  const { data, error } = await supabase.functions.invoke("invite-user", {
    body: { email, full_name: fullName, role },
  });

  if (error) {
    return {
      ok: false,
      error:
        "فشل إرسال الدعوة — اتأكد إن وظيفة invite-user منشورة وإن حسابك أدمن/سوبر أدمن.",
    };
  }

  const actionLink =
    (data as { action_link?: string } | null)?.action_link ?? null;
  return { ok: true, actionLink };
}
