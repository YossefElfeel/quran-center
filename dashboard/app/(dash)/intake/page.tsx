import { DeleteButton } from "@/components/admin-controls";
import { createSupabaseServerClient } from "@/lib/supabase/server";

import { setWaitingStatus } from "./actions";
import {
  ApplicantForm,
  AssignForm,
  type Option,
  PlacementForm,
} from "./forms";

type LevelRow = {
  id: string;
  name: string;
  curriculum: { name: string } | null;
};
type CircleRow = {
  id: string;
  name: string;
  level: { name: string; curriculum: { name: string } | null } | null;
};
type WaitingRow = {
  id: string;
  status: string;
  level_id: string;
  student: { id: string; full_name: string } | null;
  level: { name: string } | null;
};

export default async function IntakePage() {
  const supabase = await createSupabaseServerClient();

  const { data: levelData } = await supabase
    .from("level")
    .select("id, name, curriculum:curriculum_id(name)")
    .order("ord");
  const levels: Option[] = ((levelData ?? []) as unknown as LevelRow[]).map(
    (l) => ({
      id: l.id,
      label: l.curriculum?.name ? `${l.curriculum.name} — ${l.name}` : l.name,
    }),
  );

  const { data: circleData } = await supabase
    .from("circle")
    .select("id, name, level:level_id(name, curriculum:curriculum_id(name))")
    .order("created_at");
  const circles: Option[] = ((circleData ?? []) as unknown as CircleRow[])
    .map((c) => {
      const prefix = [c.level?.curriculum?.name, c.level?.name]
        .filter(Boolean)
        .join(" — ");
      return { id: c.id, label: prefix ? `${prefix} — ${c.name}` : c.name };
    })
    .sort((a, b) => a.label.localeCompare(b.label, "ar"));

  const { data: waitingData } = await supabase
    .from("waiting_list")
    .select(
      "id, status, level_id, student:student_person_id(id, full_name), level:level_id(name)",
    )
    .eq("status", "waiting")
    .order("created_at", { ascending: true });
  const waiting = (waitingData ?? []) as unknown as WaitingRow[];

  return (
    <div className="flex flex-col gap-6">
      <div>
        <h1 className="text-2xl font-bold">قائمة الانتظار والالتحاق</h1>
        <p className="text-sm text-foreground/60">
          أضف متقدّم، سجّل اختبار تحديد المستوى، ثم أسنِده لحلقة.
        </p>
      </div>

      {levels.length === 0 ? (
        <p className="rounded-xl border border-border bg-white px-4 py-4 text-sm text-foreground/60">
          محتاج تنشئ مناهج ومستويات الأول من «المناهج والحلقات».
        </p>
      ) : (
        <ApplicantForm levels={levels} />
      )}

      <div className="flex flex-col gap-3">
        <h2 className="text-lg font-bold">في الانتظار ({waiting.length})</h2>
        {waiting.length === 0 ? (
          <p className="rounded-xl border border-border bg-white px-4 py-6 text-center text-foreground/50">
            مفيش متقدّمين في الانتظار.
          </p>
        ) : (
          waiting.map((w) => (
            <div
              key={w.id}
              className="flex flex-col gap-3 rounded-xl border border-border bg-white p-4"
            >
              <div className="flex items-center justify-between gap-3">
                <div className="flex flex-wrap items-center gap-2">
                  <span className="font-bold">
                    {w.student?.full_name ?? "—"}
                  </span>
                  <span className="text-xs text-foreground/50">
                    المستوى: {w.level?.name ?? "—"}
                  </span>
                </div>
                <DeleteButton
                  action={setWaitingStatus}
                  hidden={{ id: w.id, status: "declined" }}
                  label="رفض"
                  confirmMessage="رفض المتقدّم من قائمة الانتظار؟"
                />
              </div>
              <PlacementForm
                waitingId={w.id}
                studentPersonId={w.student?.id ?? ""}
                levels={levels}
                currentLevelId={w.level_id}
              />
              {circles.length > 0 ? (
                <AssignForm
                  waitingId={w.id}
                  studentPersonId={w.student?.id ?? ""}
                  circles={circles}
                />
              ) : null}
            </div>
          ))
        )}
      </div>
    </div>
  );
}
