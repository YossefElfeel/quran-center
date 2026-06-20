"use server";

import { revalidatePath } from "next/cache";

import { createSupabaseServerClient } from "@/lib/supabase/server";

export type FormResult = { ok: true } | { ok: false; error: string };

function mapErr(msg: string): string {
  if (msg.includes("forbidden")) return "غير مصرّح — لازم تكون سوبر أدمن.";
  if (msg.includes("reason required")) return "السبب مطلوب.";
  if (msg.includes("unknown job")) return "مهمّة غير معروفة.";
  return "فشل التنفيذ — جرّب تاني.";
}

// تفعيل/تعطيل مهمّة مجدولة. الـ RPC بيسجّل التدقيق بنفسه (cron_set_active).
export async function setCronActive(
  _p: FormResult | null,
  fd: FormData,
): Promise<FormResult> {
  const jobname = String(fd.get("jobname") ?? "");
  const active = String(fd.get("active") ?? "") === "true";
  const reason = String(fd.get("reason") ?? "").trim();
  if (!jobname) return { ok: false, error: "المهمّة مطلوبة." };
  if (!reason) return { ok: false, error: "السبب مطلوب." };
  const supabase = await createSupabaseServerClient();
  const { error } = await supabase.rpc("cron_set_active", {
    p_jobname: jobname,
    p_active: active,
    p_reason: reason,
  });
  if (error) return { ok: false, error: mapErr(error.message) };
  revalidatePath("/automation");
  return { ok: true };
}

// تشغيل مهمّة فورًا. الـ RPC بيسجّل التدقيق بنفسه (cron_run_now).
export async function runCronNow(
  _p: FormResult | null,
  fd: FormData,
): Promise<FormResult> {
  const jobname = String(fd.get("jobname") ?? "");
  const reason = String(fd.get("reason") ?? "").trim();
  if (!jobname) return { ok: false, error: "المهمّة مطلوبة." };
  if (!reason) return { ok: false, error: "السبب مطلوب." };
  const supabase = await createSupabaseServerClient();
  const { error } = await supabase.rpc("cron_run_now", {
    p_jobname: jobname,
    p_reason: reason,
  });
  if (error) return { ok: false, error: mapErr(error.message) };
  revalidatePath("/automation");
  return { ok: true };
}
