import Link from "next/link";

import { SearchForm } from "@/components/list-controls";
import { formatNumber } from "@/lib/format";
import { getDataClient } from "@/lib/supabase/data-client";

const STATUS_LABEL: Record<string, string> = {
  forming: "قيد التكوين",
  active: "نشطة",
  graduated: "متخرّجة",
};

type CircleRow = {
  id: string;
  name: string;
  status: string;
  teacher: { id: string; full_name: string } | null;
  level: { name: string } | null;
};

export default async function CirclesPage({
  searchParams,
}: {
  searchParams: Promise<{ q?: string; filter?: string }>;
}) {
  const { q, filter: filterRaw } = await searchParams;
  const filter = filterRaw === "struggling" ? filterRaw : undefined;
  const supabase = await getDataClient();
  let circleQuery = supabase
    .from("circle")
    .select("id, name, status, teacher:teacher_id(id, full_name), level:level_id(name)")
    .order("created_at");
  if (q) circleQuery = circleQuery.ilike("name", `%${q}%`);
  const { data: circleData, error: loadError1 } = await circleQuery;
  if (loadError1) throw new Error('data_load_failed');
  let circles = (circleData ?? []) as unknown as CircleRow[];

  const { data: enr, error: loadError2 } = await supabase
    .from("enrollment")
    .select("circle_id")
    .eq("status", "active");
  if (loadError2) throw new Error('data_load_failed');
  const counts = new Map<string, number>();
  for (const e of (enr ?? []) as { circle_id: string }[]) {
    counts.set(e.circle_id, (counts.get(e.circle_id) ?? 0) + 1);
  }

  if(filter==='struggling'){
    const {data:struggling,error}=await supabase.rpc('struggling_circle_ids');
    if(error)throw new Error('struggling_load_failed');
    const ids=new Set((struggling??[]).map((row:{circle_id:string})=>row.circle_id));
    circles=circles.filter(circle=>ids.has(circle.id));
  }
  return (
    <div className="flex flex-col gap-6">
      <div>
        <h1 className="text-2xl font-bold">الحلقات والمتابعة</h1>
        <p className="text-sm text-foreground/60">
          اضغط على حلقة لمتابعة دفتر الطلاب (الدَيْن)، تصحيحه، وملاحظات السلوك.
        </p>
      </div>

      <SearchForm q={q} placeholder="ابحث باسم الحلقة…" hidden={filter ? { filter } : undefined} />
      {filter === "struggling" ? (
        <div className="flex flex-wrap items-center gap-2 text-sm">
          <span className="text-foreground/60">فلتر نشط:</span>
          <span className="inline-flex items-center gap-2 rounded-full bg-red-50 px-3 py-1 font-medium text-red-700">
            حلقات فيها طلبة متعثّرون
            <Link href={q ? `/circles?q=${encodeURIComponent(q)}` : "/circles"} className="rounded-full px-1 hover:bg-red-100" aria-label="إلغاء فلتر الحلقات المتعثّرة">✕</Link>
          </span>
        </div>
      ) : null}

      <div className="overflow-x-auto rounded-xl border border-border bg-white">
        <table className="w-full min-w-[640px] text-start text-sm">
          <thead className="border-b border-border bg-background/50 text-foreground/60">
            <tr>
              <th className="px-4 py-2 font-medium">الحلقة</th>
              <th className="px-4 py-2 font-medium">المستوى</th>
              <th className="px-4 py-2 font-medium">المعلّم</th>
              <th className="px-4 py-2 font-medium">الحالة</th>
              <th className="px-4 py-2 font-medium">الطلاب</th>
            </tr>
          </thead>
          <tbody>
            {circles.length === 0 ? (
              <tr>
                <td colSpan={5} className="px-4 py-6 text-center text-foreground/50">
                  {filter === "struggling" ? "مفيش حلقات فيها طلبة متعثّرون دلوقتي." : q ? "مفيش حلقات بالاسم ده." : "مفيش حلقات لسه."}
                </td>
              </tr>
            ) : (
              circles.map((c) => (
                <tr key={c.id} className="border-b border-border/60">
                  <td className="px-4 py-2">
                    <Link
                      href={`/circles/${c.id}`}
                      className="font-medium text-primary hover:underline"
                    >
                      {c.name}
                    </Link>
                  </td>
                  <td className="px-4 py-2">{c.level?.name ?? "—"}</td>
                  <td className="px-4 py-2">{c.teacher ? <Link href={`/users/${c.teacher.id}`} className="text-primary hover:underline">{c.teacher.full_name}</Link> : "—"}</td>
                  <td className="px-4 py-2">
                    {STATUS_LABEL[c.status] ?? c.status}
                  </td>
                  <td className="px-4 py-2">{formatNumber(counts.get(c.id) ?? 0)}</td>
                </tr>
              ))
            )}
          </tbody>
        </table>
      </div>
    </div>
  );
}
