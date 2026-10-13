"use server";
import { revalidatePath } from "next/cache";
import { z } from "zod";
import { validationError } from "@/lib/validation";
import { getDataClient } from "@/lib/supabase/data-client";
import { guardedAction, type FormResult } from "@/lib/guard";
const schema = z.object({ id: z.uuid(), response: z.string().trim().max(4000), status: z.enum(['open','reopened','answered','closed']) });
export async function respondToComplaint(_previous: FormResult | null, fd: FormData): Promise<FormResult> {
  const parsed = schema.safeParse(Object.fromEntries(fd));
  if (!parsed.success) return validationError(parsed)!;
  const { id, response, status } = parsed.data;
  if (status !== 'open' && status !== 'reopened' && !response) return { ok: false, error: "اكتب الرد قبل تغيير الحالة." };
  // guardedAction re-checks the super admin and writes the audit entry after a successful save.
  const result = await guardedAction({
    action: "complaint_responded",
    reason: response ? "رد الإدارة على الشكوى" : "تحديث حالة الشكوى",
    targetTable: "complaint",
    targetId: id,
    meta: { status, has_response: Boolean(response) },
    run: async () => {
      const client = await getDataClient();
      const { error } = await client.from("complaint").update({ manager_response: response || null, responded_at: response ? new Date().toISOString() : null, status }).eq("id", id).select("id").single();
      return { error: error ? "تعذّر حفظ الرد — راجع الاتصال والصلاحيات." : null };
    },
  });
  if (result.ok) revalidatePath("/complaints");
  return result;
}
