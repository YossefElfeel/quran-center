import Link from "next/link";

import { CsvButton } from "@/components/csv-button";
import { Pager } from "@/components/list-controls";
import { formatDateTime, formatNumber } from "@/lib/format";
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

const PAGE_SIZE = 50;
const input =
  "rounded-lg border border-border px-3 py-2 text-sm outline-none focus:border-primary";

export default async function AuditPage({
  searchParams,
}: {
  searchParams: Promise<{ q?: string; from?: string; to?: string; page?: string }>;
}) {
  const { q, from, to, page: pageRaw } = await searchParams;
  const page = Math.max(1, Number(pageRaw) || 1);
  const offset = (page - 1) * PAGE_SIZE;

  const supabase = await createSupabaseServerClient();

  const now = new Date();
  const startToday = new Date(
    Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), now.getUTCDate()),
  ).toISOString();

  // شريط الحالة (عدّادات سريعة).
  const HEAD = { count: "exact" as const, head: true };
  const [totalEvents, eventsToday, blocked, deactivated] = await Promise.all([
    supabase.from("audit_log").select("*", HEAD),
    supabase.from("audit_log").select("*", HEAD).gte("at", startToday),
    supabase.from("person").select("*", HEAD).not("blocked_at", "is", null),
    supabase.from("person").select("*", HEAD).not("deactivated_at", "is", null),
  ]);

  // الاستكشاف (فلاتر + ترقيم).
  let query = supabase
    .from("audit_log")
    .select(
      "id, action, target_table, target_id, at, actor:actor_person_id(full_name)",
      { count: "exact" },
    )
    .order("at", { ascending: false })
    .range(offset, offset + PAGE_SIZE - 1);
  if (q) query = query.ilike("action", `%${q}%`);
  if (from) query = query.gte("at", from);
  if (to) query = query.lte("at", `${to}T23:59:59.999Z`);
  const { data, count } = await query;
  const rows = (data ?? []) as unknown as AuditRow[];
  const totalPages = Math.ceil((count ?? 0) / PAGE_SIZE);

  const csvRows = rows.map((r) => ({
    at: formatDateTime(r.at),
    actor: r.actor?.full_name ?? "—",
    action: r.action,
    target: r.target_table ?? "",
    target_id: r.target_id ?? "",
  }));

  const params: Record<string, string> = {};
  if (q) params.q = q;
  if (from) params.from = from;
  if (to) params.to = to;

  const health = [
    { label: "إجمالي الأحداث", value: totalEvents.count ?? 0 },
    { label: "أحداث النهاردة", value: eventsToday.count ?? 0 },
    { label: "حسابات محظورة", value: blocked.count ?? 0 },
    { label: "حسابات موقوفة", value: deactivated.count ?? 0 },
  ];

  return (
    <div className="flex flex-col gap-5">
      <div className="flex items-center justify-between gap-3">
        <div>
          <h1 className="text-2xl font-bold">سجل التدقيق وحالة النظام</h1>
          <p className="mt-1 text-sm text-foreground/60">
            استكشف الأحداث (مين عمل إيه وامتى) مع فلاتر وتصدير.
          </p>
        </div>
        <CsvButton rows={csvRows} columns={CSV_COLS} filename="audit_log.csv" />
      </div>

      <div className="grid gap-3 sm:grid-cols-2 lg:grid-cols-4">
        {health.map((h) => (
          <div key={h.label} className="rounded-xl border border-border bg-white p-4">
            <p className="text-xs text-foreground/60">{h.label}</p>
            <p className="mt-1 text-2xl font-bold text-primary">
              {formatNumber(h.value)}
            </p>
          </div>
        ))}
      </div>

      <form className="flex flex-wrap items-end gap-2 rounded-xl border border-border bg-white p-3">
        <label className="flex flex-col gap-1 text-xs text-foreground/60">
          الإجراء
          <input name="q" defaultValue={q ?? ""} placeholder="مثال: user_blocked" className={input} />
        </label>
        <label className="flex flex-col gap-1 text-xs text-foreground/60">
          من
          <input type="date" name="from" defaultValue={from ?? ""} className={input} />
        </label>
        <label className="flex flex-col gap-1 text-xs text-foreground/60">
          إلى
          <input type="date" name="to" defaultValue={to ?? ""} className={input} />
        </label>
        <button className="rounded-lg bg-primary px-4 py-2 text-sm font-bold text-white hover:opacity-90">
          فلترة
        </button>
        <Link href="/audit" className="rounded-lg border border-border px-4 py-2 text-sm hover:bg-border/40">
          مسح
        </Link>
        <span className="ml-auto self-center text-sm text-foreground/50">
          {formatNumber(count ?? 0)} نتيجة
        </span>
      </form>

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
                <td colSpan={4} className="px-4 py-6 text-center text-foreground/50">
                  مفيش أحداث مطابقة.
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
      <Pager page={page} totalPages={totalPages} params={params} />
    </div>
  );
}
