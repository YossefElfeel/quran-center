"use server";
import { validateAction } from "@/lib/action-schemas";

import { normalizeNumber } from "@/lib/validation";
import { revalidatePath } from "next/cache";


import { logAudit } from "@/lib/audit";
import { getDataClient, getDataIdentity } from "@/lib/supabase/data-client";

export type FormResult = { ok: true; paymentId?:string } | { ok: false; error: string };

function currentMonth():string {
  const parts=new Intl.DateTimeFormat('en-CA',{year:'numeric',month:'2-digit',timeZone:'Africa/Cairo'}).formatToParts(new Date());
  return parts.find(part=>part.type==='year')!.value+'-'+parts.find(part=>part.type==='month')!.value+'-01';
}

export async function createHousehold(
  _p: FormResult | null,
  fd: FormData,
): Promise<FormResult> {
  const formError = validateAction("createHousehold", fd);
  if (formError) return formError;

  const name = String(fd.get("name") ?? "").trim();
  const amount = Number(normalizeNumber(String(fd.get("monthly_amount")??0)));
  if (!name) return { ok: false, error: "اسم الأسرة مطلوب." };
  const supabase = await getDataClient();
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
  const formError = validateAction("recordPayment", fd);
  if (formError) return formError;

  const householdId = String(fd.get("household_id") ?? "");
  const amount = Number(normalizeNumber(String(fd.get("amount")??"")));
  const month=String(fd.get('period_month')??'');
  const method=String(fd.get('method')??'cash');
  if(!/^\d{4}-\d{2}$/.test(month)||Number(month.slice(5))<1||Number(month.slice(5))>12||month>currentMonth().slice(0,7)||!['cash','instapay','other'].includes(method))return{ok:false,error:'راجع شهر الدفعة وطريقة الدفع.'};
  if (!householdId || !Number.isFinite(amount) || amount < 0)
    return { ok: false, error: "بيانات الدفع ناقصة." };
  const supabase = await getDataClient();
  const actor = await getDataIdentity();
  const { data, error } = await supabase.from("subscription_payment").insert({
    household_id: householdId,
    amount,
    period_month: month+'-01',
    method,
    recorded_by: actor.personId,
  }).select("id").single();
  if (error) return { ok: false, error: error.code==='23505'?'الشهر ده مدفوع بالفعل.':"فشل تسجيل الدفع." };
  await logAudit({
    action: "payment_recorded",
    targetTable: "subscription_payment",
    meta: { household_id: householdId, amount },
  });
  revalidatePath("/subscriptions");
  return { ok: true, paymentId:data.id };
}

// إبطال دفعة (الجدول append-only — voided flag بدل الحذف).
export async function voidPayment(
  _p: FormResult | null,
  fd: FormData,
): Promise<FormResult> {
  const formError = validateAction("voidPayment", fd);
  if (formError) return formError;

  const id = String(fd.get("id") ?? "");
  const reason = String(fd.get("reason") ?? "").trim();
  if (!id) return { ok: false, error: "الدفعة مطلوبة." };
  if (!reason) return { ok: false, error: "سبب الإبطال مطلوب." };
  const supabase = await getDataClient();
  const { error } = await supabase
    .from("subscription_payment")
    .update({ voided: true, void_reason: reason })
    .eq("id", id).select("id").single();
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
