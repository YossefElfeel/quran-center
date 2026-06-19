import { createSupabaseServerClient } from "@/lib/supabase/server";

import { ExcuseDecision } from "./forms";

type Row = {
  id: string;
  reason: string | null;
  session_id: string | null;
  enrollment_id: string;
  enrollment: {
    student: { full_name: string } | null;
    circle: { name: string } | null;
  } | null;
  session: { session_date: string } | null;
};

export default async function ExcusesPage() {
  const supabase = await createSupabaseServerClient();
  const { data } = await supabase
    .from("excuse_request")
    .select(
      "id, reason, session_id, enrollment_id, enrollment:enrollment_id(student:student_person_id(full_name), circle:circle_id(name)), session:session_id(session_date)",
    )
    .eq("status", "pending")
    .order("created_at", { ascending: true });
  const rows = (data ?? []) as unknown as Row[];

  return (
    <div className="flex flex-col gap-6">
      <div>
        <h1 className="text-2xl font-bold">أعذار الغياب</h1>
        <p className="text-sm text-foreground/60">
          راجع طلبات أعذار الغياب المعلّقة. القبول بيخلّي الغياب محايد (بعذر).
        </p>
      </div>

      <div className="flex flex-col gap-2">
        {rows.length === 0 ? (
          <p className="rounded-xl border border-border bg-white px-4 py-6 text-center text-foreground/50">
            مفيش أعذار معلّقة.
          </p>
        ) : (
          rows.map((r) => (
            <div
              key={r.id}
              className="flex flex-wrap items-center justify-between gap-3 rounded-xl border border-border bg-white px-4 py-3 text-sm"
            >
              <div className="flex flex-col gap-0.5">
                <span className="font-bold">
                  {r.enrollment?.student?.full_name ?? "—"}
                </span>
                <span className="text-xs text-foreground/50">
                  {r.enrollment?.circle?.name ?? "—"}
                  {r.session?.session_date ? ` · ${r.session.session_date}` : ""}
                  {r.reason ? ` · ${r.reason}` : ""}
                </span>
              </div>
              <ExcuseDecision
                id={r.id}
                enrollmentId={r.enrollment_id}
                sessionId={r.session_id ?? ""}
              />
            </div>
          ))
        )}
      </div>
    </div>
  );
}
