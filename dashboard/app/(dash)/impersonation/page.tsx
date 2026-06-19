import { getSuperAdmin } from "@/lib/auth";
import { formatDateTime } from "@/lib/format";
import { getActiveImpersonation } from "@/lib/impersonation";
import { createSupabaseServerClient } from "@/lib/supabase/server";

import { startImpersonation, stopImpersonation } from "./actions";

type RoleRow = {
  role: string;
  person: { id: string; full_name: string } | null;
};

export default async function ImpersonationPage() {
  const admin = await getSuperAdmin();
  const active = admin ? await getActiveImpersonation(admin.personId) : null;

  const supabase = await createSupabaseServerClient();
  const { data } = await supabase
    .from("role_assignment")
    .select("role, person:person_id(id, full_name)");

  // أشخاص بأدوار، باستثناء السوبر أدمن (مش بنتقمّص سوبر أدمن).
  const people = new Map<string, string>();
  const superIds = new Set<string>();
  for (const row of (data ?? []) as unknown as RoleRow[]) {
    if (!row.person) continue;
    if (row.role === "super_admin") superIds.add(row.person.id);
    people.set(row.person.id, row.person.full_name);
  }
  const options = [...people.entries()]
    .filter(([id]) => !superIds.has(id))
    .sort((a, b) => a[1].localeCompare(b[1], "ar"));

  return (
    <div className="flex max-w-xl flex-col gap-6">
      <div>
        <h1 className="text-2xl font-bold">تقمّص الدور (معاينة)</h1>
        <p className="mt-1 text-sm text-foreground/60">
          معاينة <span className="font-bold">قراءة فقط</span> ومدقّقة (بتتسجّل في{" "}
          <code>impersonation_session</code>)، محدّدة بـ ٣٠ دقيقة. الكتابة كـ
          المستخدم مش مدعومة في النسخة دي.
        </p>
      </div>

      {active && !active.expired ? (
        <div className="flex flex-col gap-3 rounded-xl border border-accent bg-accent/10 p-4">
          <p className="font-bold text-foreground">
            بتعاين كـ: {active.subjectName}
          </p>
          <p className="text-xs text-foreground/60">
            بدأت {formatDateTime(active.startedAt)}
            {active.reason ? ` · السبب: ${active.reason}` : ""}
          </p>
          <form action={stopImpersonation}>
            <button className="rounded-lg bg-foreground/80 px-4 py-1.5 text-sm font-bold text-white hover:bg-foreground">
              إيقاف المعاينة
            </button>
          </form>
        </div>
      ) : (
        <form
          action={startImpersonation}
          className="flex flex-col gap-3 rounded-xl border border-border bg-white p-5"
        >
          {active?.expired ? (
            <p className="text-xs text-foreground/50">
              (الجلسة السابقة انتهت بالوقت — ابدأ جديدة.)
            </p>
          ) : null}
          <label className="flex flex-col gap-1 text-sm">
            المستخدم
            <select
              name="subject_person_id"
              required
              className="rounded-lg border border-border bg-white px-3 py-2 outline-none focus:border-primary"
            >
              <option value="">— اختر —</option>
              {options.map(([id, name]) => (
                <option key={id} value={id}>
                  {name}
                </option>
              ))}
            </select>
          </label>
          <label className="flex flex-col gap-1 text-sm">
            السبب (اختياري)
            <input
              name="reason"
              className="rounded-lg border border-border px-3 py-2 outline-none focus:border-primary"
            />
          </label>
          <button
            type="submit"
            className="self-start rounded-lg bg-primary px-4 py-2 font-bold text-white hover:opacity-90"
          >
            ابدأ المعاينة
          </button>
        </form>
      )}
    </div>
  );
}
