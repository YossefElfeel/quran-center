"use server";

import { revalidatePath } from "next/cache";

import { createSupabaseServerClient } from "@/lib/supabase/server";

// رد المدير على شكوى (status → answered). محمي بـ RLS (المدير/سوبر أدمن بس).
export async function respondToComplaint(formData: FormData) {
  const id = String(formData.get("id") ?? "");
  const response = String(formData.get("response") ?? "").trim();
  if (!id || !response) return;

  const supabase = await createSupabaseServerClient();
  await supabase
    .from("complaint")
    .update({
      manager_response: response,
      responded_at: new Date().toISOString(),
      status: "answered",
    })
    .eq("id", id);

  revalidatePath("/complaints");
}
