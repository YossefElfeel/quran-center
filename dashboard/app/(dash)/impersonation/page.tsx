import Link from "next/link";

import { DangerZone } from "@/components/danger-zone";
import { getSuperAdmin } from "@/lib/auth";
import { formatDateTime } from "@/lib/format";
import { getActiveImpersonation } from "@/lib/impersonation";
import { createSupabaseServerClient } from "@/lib/supabase/server";

import { startImpersonation, stopImpersonation } from "./actions";

type RoleRow = {
  role: string;
  person: { id: string; full_name: string } | null;
};

export default async function ImpersonationPage({
  searchParams,
}: {
  searchParams: Promise<{ e?: string }>;
}) {
  const { e } = await searchParams;
  const admin = await getSuperAdmin();
  const active = admin ? await getActiveImpersonation(admin.personId) : null;

  const supabase = await createSupabaseServerClient();
  const [{ data: flagRow }, { data }] = await Promise.all([
    supabase
      .from("feature_flag")
      .select("enabled")
      .eq("key", "write_impersonation")
      .maybeSingle(),
    supabase.from("role_assignment").select("role, person:person_id(id, full_name)"),
  ]);
  const flagOn = flagRow?.enabled === true;

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

  const isActive = active && !active.expired;

  return (
    <div className="flex max-w-xl flex-col gap-6">
      <div>
        <h1 className="text-2xl font-bold">تقمّص الدور (بصلاحية الكتابة)</h1>
        <p className="mt-1 text-sm text-foreground/60">
          بتتصرّف <span className="font-bold text-red-600">كـ المستخدم فعليًا</span>{" "}
          — أي تغيير بيتنسب له. مدقّق (<code>impersonation_session</code> + سجل
          التدقيق)، بتنبيه فوري، ومحدّد بـ ٣٠ دقيقة. متحكّم فيه بمفتاح{" "}
          <Link href="/flags" className="text-primary underline">
            write_impersonation
          </Link>
          .
        </p>
      </div>

      {e ? (
        <p className="rounded-lg bg-red-50 p-3 text-sm text-red-700">{e}</p>
      ) : null}

      {isActive ? (
        <div className="flex flex-col gap-3 rounded-xl border-2 border-red-300 bg-red-50 p-4">
          <p className="font-bold text-red-700">
            🔴 بتتصرّف كـ: {active!.subjectName}
          </p>
          <p className="text-xs text-red-700/80">
            بدأت {formatDateTime(active!.startedAt)}
            {active!.reason ? ` · السبب: ${active!.reason}` : ""} · كل تغيير
            بيتنسب للمستخدم ده.
          </p>
          <form action={stopImpersonation}>
            <button className="rounded-lg bg-red-600 px-4 py-1.5 text-sm font-bold text-white hover:opacity-90">
              إيقاف التقمّص
            </button>
          </form>
        </div>
      ) : !flagOn ? (
        <div className="flex flex-col gap-2 rounded-xl border border-border bg-white p-5">
          <p className="text-sm font-bold">التقمّص بالكتابة مقفول 🔒</p>
          <p className="text-xs text-foreground/60">
            فعّل مفتاح <code>write_impersonation</code> من صفحة المفاتيح الأول —
            ده كِل سويتش أمان.
          </p>
          <Link
            href="/flags"
            className="self-start rounded-lg border border-border px-3 py-1.5 text-sm hover:bg-border/40"
          >
            روح للمفاتيح
          </Link>
        </div>
      ) : (
        <DangerZone
          title="بدء تقمّص بصلاحية الكتابة"
          description="هتقدر تعمل تغييرات باسم المستخدم. اختر بعناية واكتب سبب واضح."
        >
          <form action={startImpersonation} className="flex flex-col gap-3">
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
              السبب (مطلوب)
              <input
                name="reason"
                required
                className="rounded-lg border border-border px-3 py-2 outline-none focus:border-primary"
              />
            </label>
            <button
              type="submit"
              className="self-start rounded-lg bg-red-600 px-4 py-2 font-bold text-white hover:opacity-90"
            >
              ابدأ التقمّص
            </button>
          </form>
        </DangerZone>
      )}
    </div>
  );
}
