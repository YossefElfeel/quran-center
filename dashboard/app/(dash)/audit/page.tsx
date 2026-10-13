import { PersonLink } from "@/components/person-link";
import { Button } from "@/components/ui/button";
import { FieldInput, FieldSelect } from "@/components/ui/fields";
import { OperatorScopeNote } from "@/components/operator-scope-note";
import Link from "next/link";

import { ExportButton } from "@/components/export-button";
import { ACTION_LABEL,actionLabel } from "@/lib/action-labels";
import { auditQuery,parseAuditFilters } from "@/lib/audit-query";
import { Pager } from "@/components/list-controls";
import { formatDateTime, formatNumber } from "@/lib/format";
import { createSupabaseServerClient } from "@/lib/supabase/server";

type AuditRow = {
  id: string;
  action: string;
  target_table: string | null;
  target_id: string | null;
  at: string;
  actor: { id: string; full_name: string } | null;
};


const PAGE_SIZE = 50;

export default async function AuditPage({
  searchParams,
}: {
  searchParams: Promise<{ action?:string; actor?:string; from?: string; to?: string; page?: string }>;
}) {
  const { action,actor,from, to, page: pageRaw } = await searchParams;
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

  const readErrors=[totalEvents,eventsToday,blocked,deactivated].some(r=>r.error);
  if(readErrors)throw new Error("data_load_failed");
  const {data:actors,error:actorError}=await supabase.from("person").select("id,full_name").eq("is_minor",false).order("full_name");
  if(actorError)throw new Error("data_load_failed");
  const filters=parseAuditFilters({action,actor,from,to});
  // الاستكشاف (فلاتر + ترقيم).
  const {data,count,error:loadError1}=await auditQuery(supabase,filters).range(offset,offset+PAGE_SIZE-1);
  if (loadError1) throw new Error('data_load_failed');
  const rows = (data ?? []) as unknown as AuditRow[];
  const totalPages = Math.ceil((count ?? 0) / PAGE_SIZE);


  const params: Record<string, string> = {};
  if (action) params.action = action;
  if (actor) params.actor=actor;
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
          <h1 className="text-2xl font-bold">سجل التدقيق وحالة النظام</h1><OperatorScopeNote />
          <p className="mt-1 text-sm text-foreground/60">
            استكشف الأحداث (مين عمل إيه وامتى) مع فلاتر وتصدير.
          </p>
        </div>
        <ExportButton href={`/audit/export?${new URLSearchParams(params)}`} filename="audit_log.csv" />
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
          <FieldSelect name="action" defaultValue={action??""} aria-label="الإجراء" className="text-sm"><option value="">كل الإجراءات</option>{Object.entries(ACTION_LABEL).map(([key,label])=><option key={key} value={key}>{label}</option>)}</FieldSelect>
        </label>
        <label className="flex flex-col gap-1 text-xs text-foreground/60">الفاعل<FieldSelect name="actor" defaultValue={actor??""} aria-label="الفاعل" className="text-sm"><option value="">كل الأشخاص</option>{(actors??[]).map(a=><option key={a.id} value={a.id}>{a.full_name}</option>)}</FieldSelect></label>
        <label className="flex flex-col gap-1 text-xs text-foreground/60">
          من
          <FieldInput type="date" name="from" defaultValue={from ?? ""} aria-label="من" className="text-sm" />
        </label>
        <label className="flex flex-col gap-1 text-xs text-foreground/60">
          إلى
          <FieldInput type="date" name="to" defaultValue={to ?? ""} aria-label="إلى" className="text-sm" />
        </label>
        <Button type="submit" className="text-sm">
          فلترة
        </Button>
        <Link href="/audit" className="rounded-lg border border-border px-4 py-2 text-sm hover:bg-border/40">
          مسح
        </Link>
        <span className="ms-auto self-center text-sm text-foreground/50">
          {formatNumber(count ?? 0)} نتيجة
        </span>
      </form>

      <div className="overflow-x-auto rounded-xl border border-border bg-white">
        <table className="w-full text-start text-sm">
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
                  <td className="px-4 py-2"><PersonLink person={r.actor} /></td>
                  <td className="px-4 py-2">
                    <span className="rounded bg-accent/10 px-1.5 py-0.5 text-xs text-accent">
                      {actionLabel(r.action)}
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
