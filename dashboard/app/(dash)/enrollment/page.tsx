import { DeleteButton } from "@/components/admin-controls";
import { Pager, SearchForm } from "@/components/list-controls";
import { createSupabaseServerClient } from "@/lib/supabase/server";

import { deleteEnrollment } from "./actions";
import { type CircleOption, EnrollForm, EnrollmentControls } from "./forms";

const STATUS_LABEL: Record<string, string> = {
  active: "نشط",
  paused: "موقوف مؤقتًا",
  graduated: "متخرّج",
  dropped: "منسحب",
  transferred: "منقول",
};

type CircleRow = {
  id: string;
  name: string;
  level: { name: string; curriculum: { name: string } | null } | null;
};

type EnrollRow = {
  id: string;
  status: string;
  student: { full_name: string } | null;
  circle: { id: string; name: string } | null;
};

const PAGE_SIZE = 25;

export default async function EnrollmentPage({
  searchParams,
}: {
  searchParams: Promise<{ q?: string; page?: string }>;
}) {
  const { q, page: pageRaw } = await searchParams;
  const page = Math.max(1, Number(pageRaw) || 1);
  const offset = (page - 1) * PAGE_SIZE;
  const supabase = await createSupabaseServerClient();

  const { data: circleData } = await supabase
    .from("circle")
    .select("id, name, level:level_id(name, curriculum:curriculum_id(name))")
    .order("created_at");
  const circles: CircleOption[] = ((circleData ?? []) as unknown as CircleRow[])
    .map((c) => {
      const lvl = c.level?.name ?? "";
      const cur = c.level?.curriculum?.name ?? "";
      const prefix = [cur, lvl].filter(Boolean).join(" — ");
      return { id: c.id, label: prefix ? `${prefix} — ${c.name}` : c.name };
    })
    .sort((a, b) => a.label.localeCompare(b.label, "ar"));

  let enrollQuery = supabase
    .from("enrollment")
    .select(
      "id, status, student:student_person_id!inner(full_name), circle:circle_id(id, name)",
      { count: "exact" },
    )
    .in("status", ["active", "paused"])
    .order("enrolled_at", { ascending: false })
    .range(offset, offset + PAGE_SIZE - 1);
  if (q) enrollQuery = enrollQuery.ilike("student.full_name", `%${q}%`);
  const { data: enrollData, count: enrollCount } = await enrollQuery;
  const enrollments = (enrollData ?? []) as unknown as EnrollRow[];
  const totalPages = Math.ceil((enrollCount ?? 0) / PAGE_SIZE);

  return (
    <div className="flex flex-col gap-6">
      <div>
        <h1 className="text-2xl font-bold">التسجيل</h1>
        <p className="text-sm text-foreground/60">
          سجّل طالب جديد في حلقة، أو انقل طالب بين الحلقات وغيّر حالته.
        </p>
      </div>

      {circles.length === 0 ? (
        <p className="rounded-xl border border-border bg-white px-4 py-4 text-sm text-foreground/60">
          محتاج تنشئ حلقات الأول من «المناهج والحلقات».
        </p>
      ) : (
        <EnrollForm circles={circles} />
      )}

      <div className="flex flex-col gap-3">
        <h2 className="text-lg font-bold">
          التسجيلات النشطة ({enrollCount ?? 0})
        </h2>
        <SearchForm q={q} placeholder="ابحث باسم الطالب…" />
        {enrollments.length === 0 ? (
          <p className="rounded-xl border border-border bg-white px-4 py-6 text-center text-foreground/50">
            مفيش تسجيلات لسه.
          </p>
        ) : (
          enrollments.map((e) => (
            <div
              key={e.id}
              className="flex flex-col gap-3 rounded-xl border border-border bg-white p-4"
            >
              <div className="flex items-center justify-between gap-3">
                <div className="flex flex-wrap items-center gap-2">
                  <span className="font-bold">
                    {e.student?.full_name ?? "—"}
                  </span>
                  <span className="text-xs text-foreground/50">
                    {e.circle?.name ?? "—"} ·{" "}
                    {STATUS_LABEL[e.status] ?? e.status}
                  </span>
                </div>
                <DeleteButton
                  action={deleteEnrollment}
                  hidden={{ id: e.id }}
                  label="حذف التسجيل"
                  confirmMessage="حذف تسجيل الطالب؟ ده بيمسح سجلّ الحلقة الحالي."
                />
              </div>
              <EnrollmentControls
                enrollmentId={e.id}
                currentCircleId={e.circle?.id ?? ""}
                currentStatus={e.status}
                circles={circles}
              />
            </div>
          ))
        )}
        <Pager page={page} totalPages={totalPages} params={q ? { q } : {}} />
      </div>
    </div>
  );
}
