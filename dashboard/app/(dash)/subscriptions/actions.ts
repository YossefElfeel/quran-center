"use server";

import { revalidatePath } from "next/cache";

import { getSuperAdmin } from "@/lib/auth";
import { logAudit } from "@/lib/audit";
import { createSupabaseServerClient } from "@/lib/supabase/server";

export type FormResult = { ok: true } | { ok: false; error: string };

function currentMonth(): string {
  const now = new Date();
  return new Date(Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), 1))
    .toISOString()
    .slice(0, 10);
}

export async function createHousehold(
  _p: FormResult | null,
  fd: FormData,
): Promise<FormResult> {
  const name = String(fd.get("name") ?? "").trim();
  const amount = Number(fd.get("monthly_amount") ?? 0);
  if (!name) return { ok: false, error: "اسم الأسرة مطلوب." };
  const supabase = await createSupabaseServerClient();
  const { data, error } = await supabase
    .from("household")
    .insert({ name, monthly_amount: Number.isFinite(amount) ? amount : 0 })
    .select("id")
    .single();
  if (error) return { ok: false, error: "فشل إنشاء الأسرة." };
  await logAudit({
    action: "household_created",
    targetTable: "household",
    targetId: data.id as string,
    meta: { name },
  });
  revalidatePath("/subscriptions");
  return { ok: true };
}

export async function recordPayment(
  _p: FormResult | null,
  fd: FormData,
): Promise<FormResult> {
  const householdId = String(fd.get("household_id") ?? "");
  const amount = Number(fd.get("amount") ?? 0);
  if (!householdId || !Number.isFinite(amount) || amount < 0)
    return { ok: false, error: "بيانات الدفع ناقصة." };
  const supabase = await createSupabaseServerClient();
  const admin = await getSuperAdmin();
  const { error } = await supabase.from("subscription_payment").insert({
    household_id: householdId,
    amount,
    period_month: currentMonth(),
    recorded_by: admin?.personId ?? null,
  });
  if (error) return { ok: false, error: "فشل تسجيل الدفع." };
  await logAudit({
    action: "payment_recorded",
    targetTable: "subscription_payment",
    meta: { household_id: householdId, amount },
  });
  revalidatePath("/subscriptions");
  return { ok: true };
}

// إبطال دفعة (الجدول append-only — voided flag بدل الحذف).
export async function voidPayment(
  _p: FormResult | null,
  fd: FormData,
): Promise<FormResult> {
  const id = String(fd.get("id") ?? "");
  const reason = String(fd.get("reason") ?? "").trim();
  if (!id) return { ok: false, error: "الدفعة مطلوبة." };
  if (!reason) return { ok: false, error: "سبب الإبطال مطلوب." };
  const supabase = await createSupabaseServerClient();
  const { error } = await supabase
    .from("subscription_payment")
    .update({ voided: true, void_reason: reason })
    .eq("id", id);
  if (error) return { ok: false, error: "فشل إبطال الدفعة." };
  await logAudit({
    action: "payment_voided",
    targetTable: "subscription_payment",
    targetId: id,
    meta: { reason },
  });
  revalidatePath("/subscriptions");
  return { ok: true };
}
