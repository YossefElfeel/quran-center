import Link from "next/link";

import { SearchForm } from "@/components/list-controls";
import { createSupabaseServerClient } from "@/lib/supabase/server";

const STATUS_LABEL: Record<string, string> = {
  forming: "قيد التكوين",
  active: "نشطة",
  graduated: "متخرّجة",
};

type CircleRow = {
  id: string;
  name: string;
  status: string;
  teacher: { full_name: string } | null;
  level: { name: string } | null;
};

export default async function CirclesPage({
  searchParams,
}: {
  searchParams: Promise<{ q?: string }>;
}) {
  const { q } = await searchParams;
  const supabase = await createSupabaseServerClient();
  let circleQuery = supabase
    .from("circle")
    .select("id, name, status, teacher:teacher_id(full_name), level:level_id(name)")
    .order("created_at");
  if (q) circleQuery = circleQuery.ilike("name", `%${q}%`);
  const { data: circleData } = await circleQuery;
  const circles = (circleData ?? []) as unknown as CircleRow[];

  const { data: enr } = await supabase
    .from("enrollment")
    .select("circle_id")
    .eq("status", "active");
  const counts = new Map<string, number>();
  for (const e of (enr ?? []) as { circle_id: string }[]) {
    counts.set(e.circle_id, (counts.get(e.circle_id) ?? 0) + 1);
  }

  return (
    <div className="flex flex-col gap-6">
      <div>
        <h1 className="text-2xl font-bold">الحلقات والمتابعة</h1>
        <p className="text-sm text-foreground/60">
          اضغط على حلقة لمتابعة دفتر الطلاب (الدَيْن)، تصحيحه، وملاحظات السلوك.
        </p>
      </div>

      <SearchForm q={q} placeholder="ابحث باسم الحلقة…" />

      <div className="overflow-x-auto rounded-xl border border-border bg-white">
        <table className="w-full min-w-[640px] text-right text-sm">
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
                  مفيش حلقات لسه.
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
                  <td className="px-4 py-2">{c.teacher?.full_name ?? "—"}</td>
                  <td className="px-4 py-2">
                    {STATUS_LABEL[c.status] ?? c.status}
                  </td>
                  <td className="px-4 py-2">{counts.get(c.id) ?? 0}</td>
                </tr>
              ))
            )}
          </tbody>
        </table>
      </div>
    </div>
  );
}
