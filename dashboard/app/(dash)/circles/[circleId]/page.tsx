import Link from "next/link";

import { DeleteButton } from "@/components/admin-controls";
import { createSupabaseServerClient } from "@/lib/supabase/server";

import { deleteBehavioralNote } from "../actions";
import { LedgerControl, NoteForm, type Student } from "../forms";

const LEDGER_LABEL: Record<string, string> = {
  assigned: "مُسنَد",
  failed_retry: "رسب/إعادة",
  passed: "عدّى",
};
const VIS_LABEL: Record<string, string> = {
  internal: "داخلي",
  parent: "لولي الأمر",
};

type Circle = {
  name: string;
  teacher: { full_name: string } | null;
  level: { name: string } | null;
};
type EnrRow = { student: { id: string; full_name: string } | null };
type Note = {
  id: string;
  student_person_id: string;
  text: string;
  visibility: string;
  created_at: string;
};

export default async function CircleDetailPage({
  params,
}: {
  params: Promise<{ circleId: string }>;
}) {
  const { circleId } = await params;
  const supabase = await createSupabaseServerClient();

  const { data: circle } = await supabase
    .from("circle")
    .select("name, teacher:teacher_id(full_name), level:level_id(name)")
    .eq("id", circleId)
    .maybeSingle();
  const c = circle as unknown as Circle | null;

  const { data: gpc } = await supabase
    .from("group_portion_cycle")
    .select("portion_id, portion:portion_id(name)")
    .eq("circle_id", circleId)
    .is("advanced_at", null)
    .maybeSingle();
  const portionId = (gpc?.portion_id as string | undefined) ?? null;
  const portionName =
    (gpc?.portion as unknown as { name: string } | null)?.name ?? null;

  const { data: enrData } = await supabase
    .from("enrollment")
    .select("student:student_person_id(id, full_name)")
    .eq("circle_id", circleId)
    .eq("status", "active");
  const students: Student[] = ((enrData ?? []) as unknown as EnrRow[])
    .map((e) => e.student)
    .filter((s): s is { id: string; full_name: string } => !!s)
    .map((s) => ({ id: s.id, name: s.full_name }))
    .sort((a, b) => a.name.localeCompare(b.name, "ar"));
  const studentIds = students.map((s) => s.id);

  const ledger = new Map<string, string>();
  if (portionId && studentIds.length) {
    const { data: led } = await supabase
      .from("portion_ledger_entry")
      .select("student_person_id, state")
      .eq("portion_id", portionId)
      .in("student_person_id", studentIds);
    for (const l of (led ?? []) as {
      student_person_id: string;
      state: string;
    }[]) {
      ledger.set(l.student_person_id, l.state);
    }
  }

  let notes: Note[] = [];
  if (studentIds.length) {
    const { data: notesData } = await supabase
      .from("behavioral_note")
      .select("id, student_person_id, text, visibility, created_at")
      .in("student_person_id", studentIds)
      .order("created_at", { ascending: false })
      .limit(30);
    notes = (notesData ?? []) as Note[];
  }
  const studentName = (id: string) =>
    students.find((s) => s.id === id)?.name ?? "—";

  return (
    <div className="flex flex-col gap-6">
      <div className="flex flex-col gap-1">
        <Link href="/circles" className="text-sm text-primary hover:underline">
          ← الحلقات
        </Link>
        <h1 className="text-2xl font-bold">{c?.name ?? "الحلقة"}</h1>
        <p className="text-sm text-foreground/50">
          {c?.level?.name ?? "—"} · معلّم: {c?.teacher?.full_name ?? "—"}
        </p>
      </div>

      <section className="flex flex-col gap-3">
        <h2 className="text-lg font-bold">
          الدفتر — المقطع الحالي:{" "}
          <span className="text-primary">{portionName ?? "مفيش مقطع مفتوح"}</span>
        </h2>
        <div className="overflow-hidden rounded-xl border border-border bg-white">
          <table className="w-full text-right text-sm">
            <thead className="border-b border-border bg-background/50 text-foreground/60">
              <tr>
                <th className="px-4 py-2 font-medium">الطالب</th>
                <th className="px-4 py-2 font-medium">الحالة</th>
                <th className="px-4 py-2 font-medium">تصحيح إداري</th>
              </tr>
            </thead>
            <tbody>
              {students.length === 0 ? (
                <tr>
                  <td colSpan={3} className="px-4 py-6 text-center text-foreground/50">
                    مفيش طلاب نشطين في الحلقة.
                  </td>
                </tr>
              ) : (
                students.map((s) => {
                  const cur = ledger.get(s.id) ?? "assigned";
                  return (
                    <tr key={s.id} className="border-b border-border/60">
                      <td className="px-4 py-2">{s.name}</td>
                      <td className="px-4 py-2">{LEDGER_LABEL[cur] ?? cur}</td>
                      <td className="px-4 py-2">
                        {portionId ? (
                          <LedgerControl
                            studentPersonId={s.id}
                            portionId={portionId}
                            circleId={circleId}
                            current={cur}
                          />
                        ) : (
                          <span className="text-xs text-foreground/40">
                            مفيش مقطع مفتوح
                          </span>
                        )}
                      </td>
                    </tr>
                  );
                })
              )}
            </tbody>
          </table>
        </div>
      </section>

      <section className="flex flex-col gap-3">
        <h2 className="text-lg font-bold">ملاحظات السلوك</h2>
        {students.length > 0 ? (
          <NoteForm circleId={circleId} students={students} />
        ) : null}
        <div className="flex flex-col gap-2">
          {notes.length === 0 ? (
            <p className="rounded-xl border border-border bg-white px-4 py-4 text-sm text-foreground/50">
              مفيش ملاحظات.
            </p>
          ) : (
            notes.map((n) => (
              <div
                key={n.id}
                className="flex items-center justify-between gap-3 rounded-xl border border-border bg-white px-4 py-3 text-sm"
              >
                <div className="flex flex-col gap-0.5">
                  <span>
                    <span className="font-bold">
                      {studentName(n.student_person_id)}
                    </span>{" "}
                    — {n.text}
                  </span>
                  <span className="text-xs text-foreground/40">
                    {VIS_LABEL[n.visibility] ?? n.visibility}
                  </span>
                </div>
                <DeleteButton
                  action={deleteBehavioralNote}
                  hidden={{ id: n.id, circle_id: circleId }}
                  label="حذف"
                  confirmMessage="حذف الملاحظة؟"
                />
              </div>
            ))
          )}
        </div>
      </section>
    </div>
  );
}
