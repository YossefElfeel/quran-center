import { createSupabaseServerClient } from "@/lib/supabase/server";

import { DeleteRowButton, TableSelect, WriteForm } from "./forms";

// قائمة الجداول المتاحة للتصفّح. الكتابة على app_user/role_assignment/audit_log ممنوعة
// من Edge function (تُدار بمسارات مخصّصة) — بس متاحة للقراءة هنا.
const TABLES = [
  "person",
  "app_user",
  "role_assignment",
  "guardian_link",
  "system_settings",
  "impersonation_session",
  "curriculum",
  "level",
  "circle",
  "enrollment",
  "waiting_list",
  "placement_test",
  "portion",
  "circle_session",
  "group_portion_cycle",
  "daily_tasmee",
  "portion_ledger_entry",
  "attendance",
  "behavioral_note",
  "household",
  "household_member",
  "subscription_payment",
  "media",
  "consent_record",
  "audit_log",
  "notification",
  "certificate",
  "competition",
  "competition_application",
  "competition_judge",
  "competition_score",
  "supervisor_evaluation",
  "eval_score",
  "teacher_development",
  "monthly_student_evaluation",
  "monthly_top_student",
  "teacher_rating",
  "complaint",
  "course",
];

const PII_COLS = new Set([
  "national_id_encrypted",
  "national_id_hmac",
  "national_id_last4",
]);

function cell(v: unknown): string {
  if (v === null || v === undefined) return "—";
  if (typeof v === "object") return JSON.stringify(v);
  const s = String(v);
  return s.length > 60 ? s.slice(0, 57) + "…" : s;
}

export default async function DataPage({
  searchParams,
}: {
  searchParams: Promise<{ table?: string }>;
}) {
  const { table: raw } = await searchParams;
  const table = TABLES.includes(raw ?? "") ? (raw as string) : TABLES[0];

  const supabase = await createSupabaseServerClient();
  const { data, error } = await supabase.from(table).select("*").limit(50);
  const rows = (data ?? []) as Record<string, unknown>[];
  const cols = rows.length
    ? Object.keys(rows[0]).filter((c) => !PII_COLS.has(c))
    : [];

  return (
    <div className="flex flex-col gap-6">
      <div>
        <h1 className="text-2xl font-bold">وحدة التحكّم بالبيانات</h1>
        <p className="text-sm text-foreground/60">
          تصفّح أي جدول وعدّله مباشرة. الكتابة بتمرّ عبر دالة محروسة (تمنع جداول
          حسّاسة وأعمدة الرقم القومي، وتطلب سبب، وتسجّل كل عملية). ⚠️ أداة قوية —
          استخدمها بحذر.
        </p>
      </div>

      <div className="flex items-center gap-3">
        <span className="text-sm text-foreground/60">الجدول:</span>
        <TableSelect tables={TABLES} current={table} />
      </div>

      <WriteForm table={table} />

      {error ? (
        <p className="rounded-xl border border-red-200 bg-red-50 px-4 py-3 text-sm text-red-600">
          مش قادرين نقرا الجدول ده: {error.message}
        </p>
      ) : (
        <div className="overflow-x-auto rounded-xl border border-border bg-white">
          <table className="w-full min-w-[640px] text-right text-xs">
            <thead className="border-b border-border bg-background/50 text-foreground/60">
              <tr>
                {cols.map((c) => (
                  <th key={c} className="px-3 py-2 font-medium">
                    {c}
                  </th>
                ))}
                <th className="px-3 py-2 font-medium">إجراء</th>
              </tr>
            </thead>
            <tbody>
              {rows.length === 0 ? (
                <tr>
                  <td
                    colSpan={(cols.length || 1) + 1}
                    className="px-4 py-6 text-center text-foreground/50"
                  >
                    مفيش صفوف.
                  </td>
                </tr>
              ) : (
                rows.map((row, i) => (
                  <tr
                    key={(row.id as string) ?? i}
                    className="border-b border-border/60"
                  >
                    {cols.map((c) => (
                      <td key={c} className="px-3 py-2 align-top">
                        {cell(row[c])}
                      </td>
                    ))}
                    <td className="px-3 py-2">
                      {typeof row.id === "string" ? (
                        <DeleteRowButton table={table} id={row.id} />
                      ) : (
                        <span className="text-foreground/30">—</span>
                      )}
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>
      )}
      <p className="text-xs text-foreground/40">
        بيعرض أول ٥٠ صف. الجداول بمفتاح مركّب (من غير id) عدّلها/احذفها عبر «الشرط
        (JSON)» في النموذج فوق.
      </p>
    </div>
  );
}
