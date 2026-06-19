import { formatNumber } from "@/lib/format";
import { createSupabaseServerClient } from "@/lib/supabase/server";

import { RevenueChart } from "./revenue-chart";

type Payment = { period_month: string; amount: number };

export default async function AnalyticsPage() {
  const supabase = await createSupabaseServerClient();

  const [students, circles, households, openComplaints, paymentsRes] =
    await Promise.all([
      supabase
        .from("enrollment")
        .select("*", { count: "exact", head: true })
        .eq("status", "active"),
      supabase.from("circle").select("*", { count: "exact", head: true }),
      supabase.from("household").select("*", { count: "exact", head: true }),
      supabase
        .from("complaint")
        .select("*", { count: "exact", head: true })
        .eq("status", "open"),
      supabase
        .from("subscription_payment")
        .select("period_month, amount")
        .eq("voided", false),
    ]);

  const byMonth = new Map<string, number>();
  for (const p of (paymentsRes.data ?? []) as Payment[]) {
    const m = String(p.period_month).slice(0, 7);
    byMonth.set(m, (byMonth.get(m) ?? 0) + Number(p.amount));
  }
  const chartData = [...byMonth.entries()]
    .sort((a, b) => a[0].localeCompare(b[0]))
    .slice(-12)
    .map(([month, total]) => ({ month, total }));

  const stats = [
    { label: "الطلاب النشطين", value: students.count ?? 0 },
    { label: "الحلقات", value: circles.count ?? 0 },
    { label: "الأسر", value: households.count ?? 0 },
    { label: "شكاوى مفتوحة", value: openComplaints.count ?? 0 },
  ];

  return (
    <div className="flex flex-col gap-6">
      <h1 className="text-2xl font-bold">تحليلات</h1>

      <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
        {stats.map((s) => (
          <div
            key={s.label}
            className="rounded-xl border border-border bg-white p-5"
          >
            <p className="text-sm text-foreground/60">{s.label}</p>
            <p className="mt-1 text-3xl font-bold text-primary">
              {formatNumber(s.value)}
            </p>
          </div>
        ))}
      </div>

      <div className="rounded-xl border border-border bg-white p-5">
        <h2 className="mb-4 font-bold">إيراد الاشتراكات بالشهر (ج.م)</h2>
        <RevenueChart data={chartData} />
      </div>
    </div>
  );
}
