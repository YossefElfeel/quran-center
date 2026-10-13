import { FieldInput, FieldSelect } from "@/components/ui/fields";
import Link from "next/link";
import { SubmitButton } from "@/components/ui/button";

import { DangerZone } from "@/components/danger-zone";
import { getSuperAdmin } from "@/lib/auth";
import { formatDateTime, personOptionLabel } from "@/lib/format";
import { roleLabel } from "@/lib/action-labels";
import { flagLabel } from "../flags/meta";
import { getActiveImpersonation } from "@/lib/impersonation";
import { createSupabaseServerClient } from "@/lib/supabase/server";

import { startImpersonation, stopImpersonation } from "./actions";

type RoleRow = {
  role: string;
  person: { id: string; full_name: string; phone: string | null } | null;
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
  const [{ data: flagRow, error: flagError }, { data, error: peopleError }] = await Promise.all([
    supabase
      .from("feature_flag")
      .select("enabled")
      .eq("key", "write_impersonation")
      .maybeSingle(),
    supabase.from("role_assignment").select("role, person:person_id(id, full_name, phone)"),
  ]);
  if (flagError || peopleError) throw new Error("impersonation_options_load_failed");
  const flagOn = flagRow?.enabled === true;

  // أشخاص بأدوار، باستثناء السوبر أدمن (مش بنتقمّص سوبر أدمن).
  // كل خيار: «الاسم — الموبايل/#XXXX (الأدوار)» عشان الأسماء المتكررة تتفرّق.
  const people = new Map<string, { person: NonNullable<RoleRow["person"]>; roles: string[] }>();
  const superIds = new Set<string>();
  for (const row of (data ?? []) as unknown as RoleRow[]) {
    if (!row.person) continue;
    if (row.role === "super_admin") superIds.add(row.person.id);
    const entry = people.get(row.person.id) ?? { person: row.person, roles: [] };
    entry.roles.push(roleLabel(row.role));
    people.set(row.person.id, entry);
  }
  const options = [...people.values()]
    .filter(({ person }) => !superIds.has(person.id))
    .sort((a, b) => a.person.full_name.localeCompare(b.person.full_name, "ar"))
    .map(({ person, roles }) => [person.id, personOptionLabel(person, roles.join("، "))] as const);
  const flagName = flagLabel("write_impersonation");

  const isActive = active && !active.expired;

  return (
    <div className="flex max-w-xl flex-col gap-6">
      <div>
        <h1 className="text-2xl font-bold">تقمّص الدور (بصلاحية الكتابة)</h1>
        <p className="mt-1 text-sm text-foreground/60">
          بتتصرّف <span className="font-bold text-red-600">كـ المستخدم فعليًا</span>{" "}
          — أي تغيير بيتنسب له. كل جلسة بتتسجّل (سجل جلسات التقمّص + سجل
          التدقيق)، بتنبيه فوري، ومحدّدة بـ ٣٠ دقيقة. بيتحكّم فيه مفتاح «{flagName}» من{" "}
          <Link href="/flags" className="text-primary underline">
            صفحة المفاتيح والصيانة
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
            <SubmitButton className="bg-red-700">إيقاف التقمّص</SubmitButton>
          </form>
        </div>
      ) : !flagOn ? (
        <div className="flex flex-col gap-2 rounded-xl border border-border bg-white p-5">
          <p className="text-sm font-bold">التقمّص بالكتابة مقفول 🔒</p>
          <p className="text-xs text-foreground/60">
            فعّل مفتاح «{flagName}» من صفحة المفاتيح والصيانة الأول — ده مفتاح
            أمان بيقفل التقمّص كله.
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
              <FieldSelect
                name="subject_person_id"
                required
                aria-label="المستخدم"
              >
                <option value="">— اختر —</option>
                {options.map(([id, name]) => (
                  <option key={id} value={id}>
                    {name}
                  </option>
                ))}
              </FieldSelect>
            </label>
            <label className="flex flex-col gap-1 text-sm">
              السبب (مطلوب)
              <FieldInput
                name="reason"
                required
                aria-label="السبب"
              />
            </label>
            <SubmitButton variant="danger" className="self-start">ابدأ التقمّص</SubmitButton>
          </form>
        </DangerZone>
      )}
    </div>
  );
}
