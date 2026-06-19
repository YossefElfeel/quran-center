import { CsvButton } from "@/components/csv-button";
import { formatDateTime } from "@/lib/format";
import { createSupabaseServerClient } from "@/lib/supabase/server";

type AuditRow = {
  id: string;
  action: string;
  target_table: string | null;
  target_id: string | null;
  at: string;
  actor: { full_name: string } | null;
};

const CSV_COLS = [
  { key: "at", label: "التاريخ" },
  { key: "actor", label: "الفاعل" },
  { key: "action", label: "الإجراء" },
  { key: "target", label: "الجدول" },
  { key: "target_id", label: "المعرّف" },
];

export default async function AuditPage() {
  const supabase = await createSupabaseServerClient();
  const { data } = await supabase
    .from("audit_log")
    .select(
      "id, action, target_table, target_id, at, actor:actor_person_id(full_name)",
    )
    .order("at", { ascending: false })
    .limit(200);

  const rows = (data ?? []) as unknown as AuditRow[];
  const csvRows = rows.map((r) => ({
    at: formatDateTime(r.at),
    actor: r.actor?.full_name ?? "—",
    action: r.action,
    target: r.target_table ?? "",
    target_id: r.target_id ?? "",
  }));

  return (
    <div className="flex flex-col gap-4">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold">سجل التدقيق</h1>
          <p className="mt-1 text-sm text-foreground/60">
            آخر ٢٠٠ حدث (مين عمل إيه وامتى).
          </p>
        </div>
        <CsvButton rows={csvRows} columns={CSV_COLS} filename="audit_log.csv" />
      </div>

      <div className="overflow-x-auto rounded-xl border border-border bg-white">
        <table className="w-full text-right text-sm">
          <thead className="border-b border-border bg-background/50 text-foreground/60">
            <tr>
              <th className="px-4 py-2 font-medium">التاريخ</th>
              <th className="px-4 py-2 font-medium">الفاعل</th>
              <th className="px-4 py-2 font-medium">الإجراء</th>
              <th className="px-4 py-2 font-medium">الجدول</th>
            </tr>
          </thead>
          <tbody>
            {rows.length === 0 ? (
              <tr>
                <td
                  colSpan={4}
                  className="px-4 py-6 text-center text-foreground/50"
                >
                  مفيش أحداث مسجّلة لسه.
                </td>
              </tr>
            ) : (
              rows.map((r) => (
                <tr key={r.id} className="border-b border-border/60">
                  <td className="whitespace-nowrap px-4 py-2 text-foreground/70">
                    {formatDateTime(r.at)}
                  </td>
                  <td className="px-4 py-2">{r.actor?.full_name ?? "—"}</td>
                  <td className="px-4 py-2">
                    <span className="rounded bg-accent/10 px-1.5 py-0.5 text-xs text-accent">
                      {r.action}
                    </span>
                  </td>
                  <td className="px-4 py-2 text-foreground/60">
                    {r.target_table ?? "—"}
                  </td>
                </tr>
              ))
            )}
          </tbody>
        </table>
      </div>
    </div>
  );
}
