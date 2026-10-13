"use server";
import { validateAction } from "@/lib/action-schemas";

import { z } from "zod";
import { idSchema,nameSchema,webUrlSchema,validationError,normalizeNumber,cairoDateTime } from "@/lib/validation";
import { revalidatePath } from "next/cache";

import { logAudit } from "@/lib/audit";
import { getDataClient } from "@/lib/supabase/data-client";

export type FormResult = { ok: true } | { ok: false; error: string;fieldErrors?:Record<string,string[]|undefined> };
const courseSchema=z.object({title:nameSchema,video_url:webUrlSchema,description:z.string().max(5000,"الوصف أطول من اللازم")});

// ===== courses =====
export async function addCourse(
  _p: FormResult | null,
  fd: FormData,
): Promise<FormResult> {
  const title = String(fd.get("title") ?? "").trim();
  const videoUrl = String(fd.get("video_url") ?? "").trim();
  const parsed=courseSchema.safeParse({title,video_url:videoUrl,description:String(fd.get("description")??"").trim()});const invalid=validationError(parsed);if(invalid)return invalid;
  const supabase = await getDataClient();
  const { data, error } = await supabase
    .from("course")
    .insert({ title, video_url: videoUrl, description: String(fd.get("description") ?? "").trim(), is_free: true })
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
  const formError = validateAction("deleteCourse", fd);
  if (formError) return formError;

  const id = String(fd.get("id") ?? "");
  if (!id) return { ok: false, error: "الكورس مطلوب." };
  const supabase = await getDataClient();
  const { error } = await supabase.from("course").delete().eq("id", id).select("id").single();
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
  const year = yearRaw ? Number(normalizeNumber(yearRaw)) : null;
  const rawDeadline=String(fd.get("deadline")??"");const deadline=rawDeadline?cairoDateTime(rawDeadline):null;
  const parsed=z.object({name:nameSchema,year:z.number().int().min(1900).max(3000).nullable(),rules:z.string().max(10000),prize:z.string().max(2000),deadline:z.string().nullable().refine(v=>!rawDeadline||!!v,"اكتب موعدًا صحيحًا بتوقيت القاهرة")}).safeParse({name,year,rules:String(fd.get("rules")??""),prize:String(fd.get("prize")??""),deadline});const invalid=validationError(parsed);if(invalid)return invalid;
  const supabase = await getDataClient();
  const { data, error } = await supabase
    .from("competition")
    .insert({ name, year, status: "draft", rules: String(fd.get("rules") ?? "").trim(), prize: String(fd.get("prize") ?? "").trim(), deadline })
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

const competitionEditSchema=z.object({id:idSchema,name:nameSchema,rules:z.string().max(10000,"الشروط أطول من اللازم"),prize:z.string().max(2000,"الجائزة أطول من اللازم"),deadline:z.string().nullable()});
export async function updateCompetition(
  _p: FormResult | null,
  fd: FormData,
): Promise<FormResult> {
  const id = String(fd.get("id") ?? "");
  const name = String(fd.get("name") ?? "").trim();
  const rules = String(fd.get("rules") ?? "").trim();
  const prize = String(fd.get("prize") ?? "").trim();
  const rawDeadline=String(fd.get("deadline")??"").trim();const deadline=rawDeadline?cairoDateTime(rawDeadline):null;
  const parsed=competitionEditSchema.extend({deadline:competitionEditSchema.shape.deadline.refine(v=>!rawDeadline||!!v,"اكتب موعدًا صحيحًا بتوقيت القاهرة")}).safeParse({id,name,rules,prize,deadline});const invalid=validationError(parsed);if(invalid)return invalid;
  const supabase = await getDataClient();
  const { error } = await supabase
    .from("competition")
    .update({ name, rules: rules || null, prize: prize || null, deadline })
    .eq("id", id).select("id").single();
  if (error) return { ok: false, error: "فشل تعديل المسابقة." };
  await logAudit({
    action: "competition_updated",
    targetTable: "competition",
    targetId: id,
    meta: { name },
  });
  revalidatePath("/content");
  revalidatePath(`/content/${id}`);
  return { ok: true };
}

export async function setCompetitionStatus(
  _p: FormResult | null,
  fd: FormData,
): Promise<FormResult> {
  const formError = validateAction("setCompetitionStatus", fd);
  if (formError) return formError;

  const id = String(fd.get("id") ?? "");
  const status = String(fd.get("status") ?? "");
  if (!z.object({id:idSchema,status:z.enum(["draft","open","judging","closed"])}).safeParse({id,status}).success) return { ok: false, error: "بيانات ناقصة." };
  const supabase = await getDataClient();
  const { error } = await supabase
    .from("competition")
    .update({ status })
    .eq("id", id).select("id").single();
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
  const formError = validateAction("deleteCompetition", fd);
  if (formError) return formError;

  const id = String(fd.get("id") ?? "");
  if (!id) return { ok: false, error: "المسابقة مطلوبة." };
  const supabase = await getDataClient();
  const { error } = await supabase.from("competition").delete().eq("id", id).select("id").single();
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
  const formError = validateAction("setApplicationStatus", fd);
  if (formError) return formError;

  const id = String(fd.get("id") ?? "");
  const status = String(fd.get("status") ?? "");
  const competitionId = String(fd.get("competition_id") ?? "");
  if (!id || (status !== "accepted" && status !== "rejected"))
    return { ok: false, error: "بيانات ناقصة." };
  const supabase = await getDataClient();
  const { error } = await supabase
    .from("competition_application")
    .update({ status })
    .eq("id", id).select("id").single();
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

export async function updateCourse(_previous:FormResult|null,fd:FormData):Promise<FormResult>{
  const id=String(fd.get('id')??''),title=String(fd.get('title')??'').trim(),description=String(fd.get('description')??'').trim(),video=String(fd.get('video_url')??'').trim();
  const parsed=courseSchema.extend({id:idSchema}).safeParse({id,title,description,video_url:video});const invalid=validationError(parsed);if(invalid)return invalid;
  const client=await getDataClient();const {error}=await client.from('course').update({title,description,video_url:video}).eq('id',id).select('id').single();
  if(error)return {ok:false,error:'تعذّر تحديث الكورس.'};
  await logAudit({action:'course_updated',targetTable:'course',targetId:id});revalidatePath('/content');return {ok:true};
}
