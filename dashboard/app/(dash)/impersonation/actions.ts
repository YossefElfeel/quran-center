"use server";

import { revalidatePath } from "next/cache";
import { redirect } from "next/navigation";

import { getSuperAdmin } from "@/lib/auth";
import { createSupabaseServerClient } from "@/lib/supabase/server";

// بدء جلسة تقمّص (معاينة قراءة-فقط، مدقّقة). بنقفل أي جلسة فعّالة قبلها.
// الإدراج محمي بـ RLS (impersonation_superadmin_all = is_super_admin).
export async function startImpersonation(formData: FormData) {
  const subject = String(formData.get("subject_person_id") ?? "");
  const reason = String(formData.get("reason") ?? "").trim();
  if (!subject) return;

  const admin = await getSuperAdmin();
  if (!admin) return;

  const supabase = await createSupabaseServerClient();
  await supabase
    .from("impersonation_session")
    .update({ ended_at: new Date().toISOString() })
    .eq("super_admin_person_id", admin.personId)
    .is("ended_at", null);

  await supabase.from("impersonation_session").insert({
    super_admin_person_id: admin.personId,
    subject_person_id: subject,
    reason: reason || null,
  });

  revalidatePath("/", "layout");
  redirect("/impersonation");
}

export async function stopImpersonation() {
  const admin = await getSuperAdmin();
  if (!admin) return;

  const supabase = await createSupabaseServerClient();
  await supabase
    .from("impersonation_session")
    .update({ ended_at: new Date().toISOString() })
    .eq("super_admin_person_id", admin.personId)
    .is("ended_at", null);

  revalidatePath("/", "layout");
  redirect("/impersonation");
}
