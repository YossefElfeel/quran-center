import Link from "next/link";

import { createSupabaseServerClient } from "@/lib/supabase/server";

import { deleteCircle } from "../../actions";
import {
  type Circle,
  CircleControls,
  CircleForm,
  DeleteButton,
  type Teacher,
} from "../../forms";

const STATUS_LABEL: Record<string, string> = {
  forming: "قيد التكوين",
  active: "نشطة",
  graduated: "متخرّجة",
};

type TeacherRow = { person: { id: string; full_name: string } | null };

export default async function CirclesPage({
  params,
}: {
  params: Promise<{ curriculumId: string; levelId: string }>;
}) {
  const { curriculumId, levelId } = await params;
  const supabase = await createSupabaseServerClient();
  const { data: level } = await supabase
    .from("level")
    .select("name")
    .eq("id", levelId)
    .maybeSingle();
  const { data: circleData } = await supabase
    .from("circle")
    .select("id, level_id, name, max_size, status, teacher_id")
    .eq("level_id", levelId)
    .order("created_at");
  const circles = (circleData ?? []) as Circle[];

  const { data: teacherData } = await supabase
    .from("role_assignment")
    .select("person:person_id(id, full_name)")
    .eq("role", "teacher");
  const teachers: Teacher[] = ((teacherData ?? []) as unknown as TeacherRow[])
    .map((r) => r.person)
    .filter((p): p is { id: string; full_name: string } => !!p)
    .map((p) => ({ id: p.id, name: p.full_name }))
    .sort((a, b) => a.name.localeCompare(b.name, "ar"));
  const teacherName = (id: string | null) =>
    id ? (teachers.find((t) => t.id === id)?.name ?? "—") : "—";

  return (
    <div className="flex flex-col gap-6">
      <div className="flex flex-col gap-1">
        <Link
          href={`/academics/${curriculumId}`}
          className="text-sm text-primary hover:underline"
        >
          ← المستويات
        </Link>
        <h1 className="text-2xl font-bold">
          حلقات «{(level?.name as string) ?? "المستوى"}»
        </h1>
      </div>

      <CircleForm
        levelId={levelId}
        curriculumId={curriculumId}
        teachers={teachers}
      />

      <div className="flex flex-col gap-3">
        {circles.length === 0 ? (
          <p className="rounded-xl border border-border bg-white px-4 py-6 text-center text-foreground/50">
            مفيش حلقات لسه.
          </p>
        ) : (
          circles.map((c) => (
            <div
              key={c.id}
              className="flex flex-col gap-3 rounded-xl border border-border bg-white p-4"
            >
              <div className="flex items-center justify-between gap-3">
                <div className="flex flex-wrap items-center gap-2">
                  <span className="font-bold">{c.name}</span>
                  <span className="rounded-full bg-primary/10 px-2 py-0.5 text-xs text-primary">
                    {STATUS_LABEL[c.status] ?? c.status}
                  </span>
                  <span className="text-xs text-foreground/50">
                    معلّم: {teacherName(c.teacher_id)} · حد {c.max_size}
                  </span>
                </div>
                <DeleteButton
                  action={deleteCircle}
                  hidden={{
                    id: c.id,
                    level_id: levelId,
                    curriculum_id: curriculumId,
                  }}
                  label="حذف الحلقة"
                  confirmMessage={`حذف حلقة «${c.name}»؟ ده هيمسح تسجيلات الطلاب فيها.`}
                />
              </div>
              <CircleControls
                circle={c}
                curriculumId={curriculumId}
                teachers={teachers}
              />
            </div>
          ))
        )}
      </div>
    </div>
  );
}
