import { createSupabaseServerClient } from "@/lib/supabase/server";

const TIMEBOX_MS = 30 * 60 * 1000; // ٣٠ دقيقة

export type ActiveImpersonation = {
  id: string;
  subjectPersonId: string;
  subjectName: string;
  reason: string | null;
  startedAt: string;
  expired: boolean;
};

// جلسة التقمّص الفعّالة للسوبر أدمن الحالي (غير منتهية)، أو null.
export async function getActiveImpersonation(
  superAdminPersonId: string,
): Promise<ActiveImpersonation | null> {
  const supabase = await createSupabaseServerClient();
  const { data } = await supabase
    .from("impersonation_session")
    .select(
      "id, subject_person_id, reason, started_at, subject:subject_person_id(full_name)",
    )
    .eq("super_admin_person_id", superAdminPersonId)
    .is("ended_at", null)
    .order("started_at", { ascending: false })
    .limit(1)
    .maybeSingle();

  if (!data) return null;

  const row = data as unknown as {
    id: string;
    subject_person_id: string;
    reason: string | null;
    started_at: string;
    subject: { full_name: string } | null;
  };

  return {
    id: row.id,
    subjectPersonId: row.subject_person_id,
    subjectName: row.subject?.full_name ?? "—",
    reason: row.reason,
    startedAt: row.started_at,
    expired: Date.now() - new Date(row.started_at).getTime() > TIMEBOX_MS,
  };
}
