"use server";

import { revalidatePath } from "next/cache";

import { logAudit } from "@/lib/audit";
import { createSupabaseServerClient } from "@/lib/supabase/server";

export type FormResult = { ok: true } | { ok: false; error: string };

// رسالة عربية موحّدة من خطأ Postgres (RLS / FK / check).
function pgMessage(error: { code?: string } | null, fallback: string): string {
  const code = error?.code;
  if (code === "23503") return "مرتبط بعناصر تانية — احذفها الأول.";
  if (code === "42501") return "غير مصرّح — لازم تكون سوبر أدمن/أدمن.";
  if (code === "23505") return "موجود قبل كده.";
  return fallback;
}

// ===== curriculum =====
export async function createCurriculum(
  _p: FormResult | null,
  fd: FormData,
): Promise<FormResult> {
  const name = String(fd.get("name") ?? "").trim();
  const type = String(fd.get("type") ?? "quran");
  if (!name) return { ok: false, error: "الاسم مطلوب." };
  const supabase = await createSupabaseServerClient();
  const { data, error } = await supabase
    .from("curriculum")
    .insert({ name, type })
    .select("id")
    .single();
  if (error) return { ok: false, error: pgMessage(error, "فشل إنشاء المنهج.") };
  await logAudit({
    action: "curriculum_created",
    targetTable: "curriculum",
    targetId: data.id as string,
    meta: { name, type },
  });
  revalidatePath("/academics");
  return { ok: true };
}

export async function deleteCurriculum(
  _p: FormResult | null,
  fd: FormData,
): Promise<FormResult> {
  const id = String(fd.get("id") ?? "");
  if (!id) return { ok: false, error: "المنهج مطلوب." };
  const supabase = await createSupabaseServerClient();
  const { error } = await supabase.from("curriculum").delete().eq("id", id);
  if (error) return { ok: false, error: pgMessage(error, "فشل حذف المنهج.") };
  await logAudit({
    action: "curriculum_deleted",
    targetTable: "curriculum",
    targetId: id,
  });
  revalidatePath("/academics");
  return { ok: true };
}

// ===== level =====
export async function createLevel(
  _p: FormResult | null,
  fd: FormData,
): Promise<FormResult> {
  const curriculumId = String(fd.get("curriculum_id") ?? "");
  const name = String(fd.get("name") ?? "").trim();
  if (!curriculumId || !name) return { ok: false, error: "البيانات ناقصة." };
  const supabase = await createSupabaseServerClient();
  // ترتيب تلقائي: أعلى ord + 1 داخل المنهج.
  const { data: maxRow } = await supabase
    .from("level")
    .select("ord")
    .eq("curriculum_id", curriculumId)
    .order("ord", { ascending: false })
    .limit(1)
    .maybeSingle();
  const ord = ((maxRow?.ord as number | undefined) ?? 0) + 1;
  const { data, error } = await supabase
    .from("level")
    .insert({ curriculum_id: curriculumId, name, ord })
    .select("id")
    .single();
  if (error) return { ok: false, error: pgMessage(error, "فشل إضافة المستوى.") };
  await logAudit({
    action: "level_created",
    targetTable: "level",
    targetId: data.id as string,
    meta: { name, ord },
  });
  revalidatePath(`/academics/${curriculumId}`);
  return { ok: true };
}

export async function deleteLevel(
  _p: FormResult | null,
  fd: FormData,
): Promise<FormResult> {
  const id = String(fd.get("id") ?? "");
  const curriculumId = String(fd.get("curriculum_id") ?? "");
  if (!id) return { ok: false, error: "المستوى مطلوب." };
  const supabase = await createSupabaseServerClient();
  const { error } = await supabase.from("level").delete().eq("id", id);
  if (error) return { ok: false, error: pgMessage(error, "فشل حذف المستوى.") };
  await logAudit({ action: "level_deleted", targetTable: "level", targetId: id });
  revalidatePath(`/academics/${curriculumId}`);
  return { ok: true };
}

// ===== circle =====
export async function createCircle(
  _p: FormResult | null,
  fd: FormData,
): Promise<FormResult> {
  const levelId = String(fd.get("level_id") ?? "");
  const curriculumId = String(fd.get("curriculum_id") ?? "");
  const name = String(fd.get("name") ?? "").trim();
  const maxSize = Number(fd.get("max_size") ?? 30);
  const teacherId = String(fd.get("teacher_id") ?? "");
  if (!levelId || !name) return { ok: false, error: "البيانات ناقصة." };
  if (!Number.isFinite(maxSize) || maxSize < 1)
    return { ok: false, error: "الحد الأقصى لازم يكون رقم موجب." };
  const supabase = await createSupabaseServerClient();
  const { data, error } = await supabase
    .from("circle")
    .insert({
      level_id: levelId,
      name,
      max_size: maxSize,
      teacher_id: teacherId || null,
    })
    .select("id")
    .single();
  if (error) return { ok: false, error: pgMessage(error, "فشل إنشاء الحلقة.") };
  await logAudit({
    action: "circle_created",
    targetTable: "circle",
    targetId: data.id as string,
    meta: { name, max_size: maxSize },
  });
  revalidatePath(`/academics/${curriculumId}/${levelId}`);
  return { ok: true };
}

export async function updateCircle(
  _p: FormResult | null,
  fd: FormData,
): Promise<FormResult> {
  const id = String(fd.get("id") ?? "");
  const levelId = String(fd.get("level_id") ?? "");
  const curriculumId = String(fd.get("curriculum_id") ?? "");
  if (!id) return { ok: false, error: "الحلقة مطلوبة." };
  const patch: Record<string, unknown> = {};
  if (fd.has("teacher_id"))
    patch.teacher_id = String(fd.get("teacher_id") ?? "") || null;
  if (fd.has("status")) patch.status = String(fd.get("status") ?? "");
  if (fd.has("max_size")) {
    const m = Number(fd.get("max_size"));
    if (!Number.isFinite(m) || m < 1)
      return { ok: false, error: "الحد الأقصى لازم يكون رقم موجب." };
    patch.max_size = m;
  }
  if (Object.keys(patch).length === 0) return { ok: true };
  const supabase = await createSupabaseServerClient();
  const { error } = await supabase.from("circle").update(patch).eq("id", id);
  if (error) return { ok: false, error: pgMessage(error, "فشل تعديل الحلقة.") };
  await logAudit({
    action: "circle_updated",
    targetTable: "circle",
    targetId: id,
    meta: patch,
  });
  revalidatePath(`/academics/${curriculumId}/${levelId}`);
  return { ok: true };
}

export async function deleteCircle(
  _p: FormResult | null,
  fd: FormData,
): Promise<FormResult> {
  const id = String(fd.get("id") ?? "");
  const levelId = String(fd.get("level_id") ?? "");
  const curriculumId = String(fd.get("curriculum_id") ?? "");
  if (!id) return { ok: false, error: "الحلقة مطلوبة." };
  const supabase = await createSupabaseServerClient();
  // حذف الحلقة بيعمل cascade للتسجيلات ← التسميع ← الدفتر (مسح تاريخ أكاديمي لا رجعة فيه).
  // فبنمنع الحذف لو فيها أي تسجيل، ونوجّه لتخريج الحلقة (status='graduated') بدلًا منه.
  const { count } = await supabase
    .from("enrollment")
    .select("id", { count: "exact", head: true })
    .eq("circle_id", id);
  if ((count ?? 0) > 0) {
    return {
      ok: false,
      error: "الحلقة فيها تسجيلات — خرّجها (الحالة) أو انقل الطلاب الأول. الحذف بيمسح سجلّ التسميع.",
    };
  }
  const { error } = await supabase.from("circle").delete().eq("id", id);
  if (error) return { ok: false, error: pgMessage(error, "فشل حذف الحلقة.") };
  await logAudit({
    action: "circle_deleted",
    targetTable: "circle",
    targetId: id,
  });
  revalidatePath(`/academics/${curriculumId}/${levelId}`);
  return { ok: true };
}
