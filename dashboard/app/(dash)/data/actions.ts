"use server";

import { revalidatePath } from "next/cache";

import { createSupabaseServerClient } from "@/lib/supabase/server";

export type FormResult = { ok: true } | { ok: false; error: string };

async function invoke(body: Record<string, unknown>): Promise<FormResult> {
  const supabase = await createSupabaseServerClient();
  const { error } = await supabase.functions.invoke("data-console-write", {
    body,
  });
  if (error) {
    let detail = "";
    try {
      const ctx = (error as { context?: Response }).context;
      if (ctx && typeof ctx.json === "function") {
        const j = (await ctx.json()) as { error?: string };
        detail = j?.error ?? "";
      }
    } catch {
      // تجاهل.
    }
    return { ok: false, error: detail || "فشل تنفيذ العملية." };
  }
  return { ok: true };
}

export async function deleteRow(
  _p: FormResult | null,
  fd: FormData,
): Promise<FormResult> {
  const table = String(fd.get("table") ?? "");
  const id = String(fd.get("id") ?? "");
  const reason = String(fd.get("reason") ?? "").trim();
  if (!table || !id) return { ok: false, error: "بيانات ناقصة." };
  if (!reason) return { ok: false, error: "السبب مطلوب." };
  const r = await invoke({ table, op: "delete", match: { id }, reason });
  if (r.ok) revalidatePath("/data");
  return r;
}

export async function writeJson(
  _p: FormResult | null,
  fd: FormData,
): Promise<FormResult> {
  const table = String(fd.get("table") ?? "");
  const op = String(fd.get("op") ?? "");
  const reason = String(fd.get("reason") ?? "").trim();
  const payloadRaw = String(fd.get("payload") ?? "").trim();
  const matchRaw = String(fd.get("match") ?? "").trim();
  if (!table || !op) return { ok: false, error: "بيانات ناقصة." };
  if (!reason) return { ok: false, error: "السبب مطلوب." };
  let payload: unknown = {};
  let match: unknown = {};
  try {
    if (payloadRaw) payload = JSON.parse(payloadRaw);
  } catch {
    return { ok: false, error: "JSON القيم غير صحيح." };
  }
  try {
    if (matchRaw) match = JSON.parse(matchRaw);
  } catch {
    return { ok: false, error: "JSON الشرط غير صحيح." };
  }
  const r = await invoke({ table, op, payload, match, reason });
  if (r.ok) revalidatePath("/data");
  return r;
}
