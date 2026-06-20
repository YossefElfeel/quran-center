"use server";

import { revalidatePath } from "next/cache";
import { cookies } from "next/headers";
import { redirect } from "next/navigation";

import { getSuperAdmin } from "@/lib/auth";
import { IMP_COOKIE } from "@/lib/supabase/impersonated";
import { createSupabaseServerClient } from "@/lib/supabase/server";

// بدء تقمّص بصلاحية الكتابة. بيستدعي Edge Function impersonate (اللي بيتأكد من المفتاح
// write_impersonation، يقفل أي جلسة سابقة، يفتح جلسة مدقّقة، ويصدر توكن الموضوع). بنخزّن
// التوكن في cookie httpOnly (٣٠ دقيقة) فالأسطح اللي بتستخدم createImpersonatedClient
// بتتصرّف كالموضوع. الكتابة بتتنسب للموضوع، والـ act claim + الجلسة + التدقيق للمساءلة.
export async function startImpersonation(formData: FormData) {
  const subject = String(formData.get("subject_person_id") ?? "");
  const reason = String(formData.get("reason") ?? "").trim();
  if (!subject) redirect(`/impersonation?e=${encodeURIComponent("اختر مستخدم.")}`);
  if (!reason) redirect(`/impersonation?e=${encodeURIComponent("السبب مطلوب.")}`);

  const admin = await getSuperAdmin();
  if (!admin) redirect("/impersonation");

  const supabase = await createSupabaseServerClient();
  const { data, error } = await supabase.functions.invoke("impersonate", {
    body: { subject_person_id: subject, reason },
  });

  if (error) {
    let detail = "";
    try {
      const ctx = (error as { context?: Response }).context;
      if (ctx && typeof ctx.text === "function") detail = await ctx.text();
    } catch {
      // تجاهل.
    }
    const msg = detail.includes("disabled")
      ? "التقمّص بالكتابة مقفول — فعّله من «المفاتيح» الأول."
      : detail.toLowerCase().includes("super_admin")
        ? "مينفعش تتقمّص سوبر أدمن."
        : detail.includes("login account")
          ? "المستخدم ده ماعندوش حساب دخول."
          : "فشل بدء التقمّص.";
    redirect(`/impersonation?e=${encodeURIComponent(msg)}`);
  }

  const token = (data as { access_token?: string } | null)?.access_token;
  if (token) {
    const cookieStore = await cookies();
    cookieStore.set(IMP_COOKIE, token, {
      httpOnly: true,
      secure: true,
      sameSite: "lax",
      maxAge: 1800,
      path: "/",
    });
  }

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

  const cookieStore = await cookies();
  cookieStore.delete(IMP_COOKIE);

  revalidatePath("/", "layout");
  redirect("/impersonation");
}
