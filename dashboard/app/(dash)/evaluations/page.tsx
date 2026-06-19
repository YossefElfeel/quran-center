import { createSupabaseServerClient } from "@/lib/supabase/server";

import { approveDevelopment, approveMonthlyEval } from "./actions";
import { ApproveButton, RatingToggle } from "./forms";

type DevRow = {
  id: string;
  month: string;
  teacher: { full_name: string } | null;
};
type MseRow = {
  id: string;
  month: string;
  student: { full_name: string } | null;
};
type RatingRow = {
  id: string;
  stars: number;
  comment: string | null;
  hidden_by_manager: boolean;
  teacher: { full_name: string } | null;
};

export default async function EvaluationsPage() {
  const supabase = await createSupabaseServerClient();
  const [devRes, mseRes, ratingRes] = await Promise.all([
    supabase
      .from("teacher_development")
      .select("id, month, teacher:teacher_person_id(full_name)")
      .eq("status", "submitted")
      .order("month", { ascending: false }),
    supabase
      .from("monthly_student_evaluation")
      .select("id, month, student:student_person_id(full_name)")
      .eq("status", "submitted")
      .order("month", { ascending: false }),
    supabase
      .from("teacher_rating")
      .select(
        "id, stars, comment, hidden_by_manager, teacher:teacher_person_id(full_name)",
      )
      .order("created_at", { ascending: false })
      .limit(50),
  ]);
  const devs = (devRes.data ?? []) as unknown as DevRow[];
  const mses = (mseRes.data ?? []) as unknown as MseRow[];
  const ratings = (ratingRes.data ?? []) as unknown as RatingRow[];

  return (
    <div className="flex flex-col gap-8">
      <div>
        <h1 className="text-2xl font-bold">التقييمات والاعتمادات</h1>
        <p className="text-sm text-foreground/60">
          اعتمد تطوّر المعلّمين والتقييم الشهري، وأدِر تقييمات أولياء الأمور.
        </p>
      </div>

      <Section title={`اعتماد تطوّر المعلّمين (${devs.length})`}>
        {devs.length === 0 ? (
          <Empty>مفيش طلبات معلّقة.</Empty>
        ) : (
          devs.map((d) => (
            <Row key={d.id}>
              <span>
                <b>{d.teacher?.full_name ?? "—"}</b> — {d.month}
              </span>
              <ApproveButton action={approveDevelopment} id={d.id} />
            </Row>
          ))
        )}
      </Section>

      <Section title={`اعتماد التقييم الشهري للطلاب (${mses.length})`}>
        {mses.length === 0 ? (
          <Empty>مفيش طلبات معلّقة.</Empty>
        ) : (
          mses.map((m) => (
            <Row key={m.id}>
              <span>
                <b>{m.student?.full_name ?? "—"}</b> — {m.month}
              </span>
              <ApproveButton action={approveMonthlyEval} id={m.id} />
            </Row>
          ))
        )}
      </Section>

      <Section title="تقييمات المحفّظين">
        {ratings.length === 0 ? (
          <Empty>مفيش تقييمات.</Empty>
        ) : (
          ratings.map((r) => (
            <Row key={r.id}>
              <span className={r.hidden_by_manager ? "text-foreground/40" : ""}>
                <b>{r.teacher?.full_name ?? "—"}</b> — {"★".repeat(r.stars)}
                {r.comment ? ` · ${r.comment}` : ""}
                {r.hidden_by_manager ? " (مخفي)" : ""}
              </span>
              <RatingToggle id={r.id} hidden={r.hidden_by_manager} />
            </Row>
          ))
        )}
      </Section>
    </div>
  );
}

function Section({
  title,
  children,
}: {
  title: string;
  children: React.ReactNode;
}) {
  return (
    <section className="flex flex-col gap-2">
      <h2 className="text-lg font-bold">{title}</h2>
      {children}
    </section>
  );
}

function Row({ children }: { children: React.ReactNode }) {
  return (
    <div className="flex flex-wrap items-center justify-between gap-3 rounded-xl border border-border bg-white px-4 py-3 text-sm">
      {children}
    </div>
  );
}

function Empty({ children }: { children: React.ReactNode }) {
  return (
    <p className="rounded-xl border border-border bg-white px-4 py-4 text-center text-sm text-foreground/50">
      {children}
    </p>
  );
}
