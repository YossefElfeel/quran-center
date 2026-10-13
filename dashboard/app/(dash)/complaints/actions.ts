"use server";
import { revalidatePath } from "next/cache";
import { z } from "zod";
import { validationError } from "@/lib/validation";
import { getDataClient } from "@/lib/supabase/data-client";
import type { FormResult } from "@/lib/guard";
const schema = z.object({ id: z.uuid(), response: z.string().trim().max(4000), status: z.enum(['open','answered','closed']) });
export async function respondToComplaint(_previous: FormResult | null, fd: FormData): Promise<FormResult> {
  const parsed = schema.safeParse(Object.fromEntries(fd));
  if (!parsed.success) return validationError(parsed)!;
  const { id, response, status } = parsed.data;
  if (status !== 'open' && !response) return { ok: false, error: "اكتب الرد قبل تغيير الحالة." };
  try {
    const client = await getDataClient();
    const { error } = await client.from("complaint").update({ manager_response: response || null, responded_at: response ? new Date().toISOString() : null, status }).eq("id", id).select("id").single();
    if (error) return { ok: false, error: "تعذّر حفظ الرد — راجع الاتصال والصلاحيات." };
    revalidatePath("/complaints");
    return { ok: true };
  } catch { return { ok: false, error: "تعذّر حفظ الرد — جرّب تاني." }; }
}
