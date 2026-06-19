"use server";

import { revalidatePath } from "next/cache";

import { logAudit } from "@/lib/audit";
import { createSupabaseServerClient } from "@/lib/supabase/server";

export type FormResult = { ok: true } | { ok: false; error: string };

// ===== courses =====
export async function addCourse(
  _p: FormResult | null,
  fd: FormData,
): Promise<FormResult> {
  const title = String(fd.get("title") ?? "").trim();
  const videoUrl = String(fd.get("video_url") ?? "").trim();
  if (!title || !videoUrl) return { ok: false, error: "العنوان والرابط مطلوبين." };
  const supabase = await createSupabaseServerClient();
  const { data, error } = await supabase
    .from("course")
    .insert({ title, video_url: videoUrl, is_free: true })
    .select("id")
    .single();
  if (error) return { ok: false, error: "فشل إضافة الكورس." };
  await logAudit({
    action: "course_added",
    targetTable: "course",
    targetId: data.id as string,
    meta: { title },
  });
  revalidatePath("/content");
  return { ok: true };
}

export async function deleteCourse(
  _p: FormResult | null,
  fd: FormData,
): Promise<FormResult> {
  const id = String(fd.get("id") ?? "");
  if (!id) return { ok: false, error: "الكورس مطلوب." };
  const supabase = await createSupabaseServerClient();
  const { error } = await supabase.from("course").delete().eq("id", id);
  if (error) return { ok: false, error: "فشل حذف الكورس." };
  await logAudit({ action: "course_deleted", targetTable: "course", targetId: id });
  revalidatePath("/content");
  return { ok: true };
}

// ===== competitions =====
export async function createCompetition(
  _p: FormResult | null,
  fd: FormData,
): Promise<FormResult> {
  const name = String(fd.get("name") ?? "").trim();
  const yearRaw = String(fd.get("year") ?? "").trim();
  const year = yearRaw ? Number(yearRaw) : null;
  if (!name) return { ok: false, error: "اسم المسابقة مطلوب." };
  const supabase = await createSupabaseServerClient();
  const { data, error } = await supabase
    .from("competition")
    .insert({ name, year, status: "draft" })
    .select("id")
    .single();
  if (error) return { ok: false, error: "فشل إنشاء المسابقة." };
  await logAudit({
    action: "competition_created",
    targetTable: "competition",
    targetId: data.id as string,
    meta: { name },
  });
  revalidatePath("/content");
  return { ok: true };
}

export async function setCompetitionStatus(
  _p: FormResult | null,
  fd: FormData,
): Promise<FormResult> {
  const id = String(fd.get("id") ?? "");
  const status = String(fd.get("status") ?? "");
  if (!id || !status) return { ok: false, error: "بيانات ناقصة." };
  const supabase = await createSupabaseServerClient();
  const { error } = await supabase
    .from("competition")
    .update({ status })
    .eq("id", id);
  if (error) return { ok: false, error: "فشل تغيير الحالة." };
  await logAudit({
    action: "competition_status",
    targetTable: "competition",
    targetId: id,
    meta: { status },
  });
  revalidatePath("/content");
  return { ok: true };
}

export async function deleteCompetition(
  _p: FormResult | null,
  fd: FormData,
): Promise<FormResult> {
  const id = String(fd.get("id") ?? "");
  if (!id) return { ok: false, error: "المسابقة مطلوبة." };
  const supabase = await createSupabaseServerClient();
  const { error } = await supabase.from("competition").delete().eq("id", id);
  if (error) return { ok: false, error: "فشل حذف المسابقة." };
  await logAudit({
    action: "competition_deleted",
    targetTable: "competition",
    targetId: id,
  });
  revalidatePath("/content");
  return { ok: true };
}

// ===== applications =====
export async function setApplicationStatus(
  _p: FormResult | null,
  fd: FormData,
): Promise<FormResult> {
  const id = String(fd.get("id") ?? "");
  const status = String(fd.get("status") ?? "");
  const competitionId = String(fd.get("competition_id") ?? "");
  if (!id || (status !== "accepted" && status !== "rejected"))
    return { ok: false, error: "بيانات ناقصة." };
  const supabase = await createSupabaseServerClient();
  const { error } = await supabase
    .from("competition_application")
    .update({ status })
    .eq("id", id);
  if (error) return { ok: false, error: "فشل تحديث الطلب." };
  await logAudit({
    action: "application_decided",
    targetTable: "competition_application",
    targetId: id,
    meta: { status },
  });
  revalidatePath(`/content/${competitionId}`);
  return { ok: true };
}
