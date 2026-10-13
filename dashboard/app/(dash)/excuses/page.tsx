import { getDataClient } from "@/lib/supabase/data-client";
import Link from "next/link";
import { Pager } from "@/components/list-controls";
import { formatDate } from "@/lib/format";

import { ExcuseDecision } from "./forms";

type Row = {
  id: string;
  reason: string | null;
  session_id: string | null;
  enrollment_id: string;
  status: string;
  decided_at: string|null;
  decided_by: string|null;
  enrollment: {
    student: { full_name: string } | null;
    circle: { name: string } | null;
  } | null;
  session: { session_date: string } | null;
};

export default async function ExcusesPage({searchParams}:{searchParams:Promise<{tab?:string;page?:string}>}) {
  const {tab,page:pageRaw}=await searchParams;const history=tab==='history';const page=Math.max(1,Math.floor(Number(pageRaw)||1));const pageSize=50;
  const supabase = await getDataClient();
  let query = supabase
    .from("excuse_request")
    .select(
      "id, reason, status, decided_at, decided_by, session_id, enrollment_id, enrollment:enrollment_id(student:student_person_id(full_name), circle:circle_id(name)), session:session_id(session_date)",{count:'exact'},
    )
    .order("created_at", { ascending: !history }).range((page-1)*pageSize,page*pageSize-1);
  query=history?query.neq('status','pending'):query.eq('status','pending');
  const { data,count, error: loadError1 } = await query;
  if (loadError1) throw new Error('data_load_failed');
  const rows = (data ?? []) as unknown as Row[];

  return (
    <div className="flex flex-col gap-6">
      <div>
        <h1 className="text-2xl font-bold">أعذار الغياب</h1>
        <p className="text-sm text-foreground/60">
          راجع طلبات أعذار الغياب المعلّقة. القبول بيخلّي الغياب محايد (بعذر).
        </p>
      </div>

      <nav aria-label="عرض أعذار الغياب" className="flex gap-3"><Link aria-current={!history?'page':undefined} href="/excuses" className={!history?'font-bold text-primary':''}>طلبات معلّقة</Link><Link aria-current={history?'page':undefined} href="/excuses?tab=history" className={history?'font-bold text-primary':''}>سجل القرارات</Link></nav>

      <div className="flex flex-col gap-2">
        {rows.length === 0 ? (
          <p className="rounded-xl border border-border bg-white px-4 py-6 text-center text-foreground/50">
            {history?'مفيش قرارات مسجّلة.':'مفيش أعذار معلّقة.'}
          </p>
        ) : (
          rows.map((r) => (
            <div
              key={r.id}
              className="flex flex-wrap items-center justify-between gap-3 rounded-xl border border-border bg-white px-4 py-3 text-sm"
            >
              <div className="flex flex-col gap-0.5">
                <span className="font-bold">
                  {r.enrollment?.student?.full_name ?? "—"}
                </span>
                <span className="text-xs text-foreground/50">
                  {r.enrollment?.circle?.name ?? "—"}
                  {r.session?.session_date ? ` · ${formatDate(r.session.session_date)}` : ""}
                  {r.reason ? ` · ${r.reason}` : ""}
                  {history?` · ${r.status==='approved'?'مقبول':'مرفوض'} · ${formatDate(r.decided_at)}`:''}
                </span>
              </div>
              {!history?<ExcuseDecision
                id={r.id}
                enrollmentId={r.enrollment_id}
                sessionId={r.session_id ?? ""}
              />:null}
            </div>
          ))
        )}
      </div>
      <Pager page={page} totalPages={Math.ceil((count??0)/pageSize)} params={history?{tab:'history'}:{}}/>
    </div>
  );
}
