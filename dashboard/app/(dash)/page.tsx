import Link from "next/link";

import { ActivityFeed, type ActivityEntry } from "@/components/activity-feed";
import { LiveRefresh } from "@/components/live-refresh";
import { TrendChart } from "@/components/trend-chart";
import { formatNumber } from "@/lib/format";
import { createSupabaseServerClient } from "@/lib/supabase/server";

import { RevenueChart } from "./analytics/revenue-chart";

export default async function DashHome() {
  const supabase = await createSupabaseServerClient();

  // كل المقاييس في نداء RPC واحد (بدل ١٨ COUNT)، + بيانات الرسوم + بذرة سجل النشاط.
  const [metricsRes, payments, enrolledRows, activity] = await Promise.all([
    supabase.rpc("dashboard_metrics"),
    supabase
      .from("subscription_payment")
      .select("period_month, amount")
      .eq("voided", false),
    supabase
      .from("enrollment")
      .select("enrolled_at")
      .order("enrolled_at", { ascending: false })
      .limit(3000),
    supabase
      .from("audit_log")
      .select("id, action, target_table, at")
      .order("at", { ascending: false })
      .limit(30),
  ]);

  const m = (metricsRes.data ?? {}) as Record<string, number | boolean>;
  const num = (k: string) => Number(m[k] ?? 0);
  const bool = (k: string) => m[k] === true;

  const byMonth = new Map<string, number>();
  for (const p of (payments.data ?? []) as {
    period_month: string;
    amount: number;
  }[]) {
    const mo = String(p.period_month).slice(0, 7);
    byMonth.set(mo, (byMonth.get(mo) ?? 0) + Number(p.amount));
  }
  const chart = [...byMonth.entries()]
    .sort((a, b) => a[0].localeCompare(b[0]))
    .slice(-12)
    .map(([mo, total]) => ({ month: mo, total }));

  const enrollByMonth = new Map<string, number>();
  for (const e of (enrolledRows.data ?? []) as { enrolled_at: string }[]) {
    const mo = String(e.enrolled_at).slice(0, 7);
    enrollByMonth.set(mo, (enrollByMonth.get(mo) ?? 0) + 1);
  }
  const enrollChart = [...enrollByMonth.entries()]
    .sort((a, b) => a[0].localeCompare(b[0]))
    .slice(-12)
    .map(([mo, count]) => ({ month: mo, count }));

  const kpis = [
    { label: "الطلاب النشطين", value: num("active_students") },
    {
      label: "الحلقات النشطة",
      value: num("active_circles"),
      sub: `من ${num("total_circles")}`,
    },
    { label: "المعلّمون", value: num("teachers") },
    { label: "الأسر", value: num("households") },
    { label: "نسبة النجاح", value: num("pass_rate"), suffix: "٪" },
    { label: "نسبة الحضور", value: num("att_rate"), suffix: "٪" },
  ];

  const alerts = [
    { label: "اشتراكات متأخّرة", count: num("overdue"), href: "/subscriptions", tone: "red" as const },
    {
      label: "اعتمادات معلّقة (تطوّر + تقييم شهري)",
      count: num("dev_pending") + num("mse_pending"),
      href: "/evaluations",
      tone: "amber" as const,
    },
    { label: "أعذار غياب معلّقة", count: num("excuse_pending"), href: "/excuses", tone: "amber" as const },
    { label: "طلبة متعثّرون (٣+ محاولات)", count: num("struggling"), href: "/circles", tone: "red" as const },
    { label: "في قائمة الانتظار", count: num("waiting"), href: "/intake", tone: "blue" as const },
    { label: "شكاوى مفتوحة", count: num("open_complaints"), href: "/complaints", tone: "amber" as const },
  ];

  // إشارات الشذوذ — تظهر فقط لمّا تتفعّل (god-mode).
  const anomalies = [
    { label: "وضع الصيانة مفعّل", active: bool("maintenance_on"), href: "/flags", count: null },
    { label: "الجلسات متجمّدة", active: bool("sessions_frozen"), href: "/flags", count: null },
    { label: "المدفوعات متجمّدة", active: bool("payments_frozen"), href: "/flags", count: null },
    { label: "تقمّص نشط", active: num("open_impersonations") > 0, href: "/impersonation", count: num("open_impersonations") },
    { label: "حذف نهائي (آخر ٢٤س)", active: num("hard_deletes_24h") > 0, href: "/audit", count: num("hard_deletes_24h") },
    { label: "كتابة مباشرة (آخر ٢٤س)", active: num("data_writes_24h") > 0, href: "/audit", count: num("data_writes_24h") },
  ].filter((a) => a.active);

  return (
    <div className="flex flex-col gap-6">
      <LiveRefresh />
      <div className="flex items-center justify-between gap-3">
        <h1 className="text-2xl font-bold">نظرة عامة</h1>
        <span className="text-xs text-foreground/40">يتحدّث تلقائيًا</span>
      </div>

      {anomalies.length ? (
        <section className="flex flex-col gap-3">
          <h2 className="text-lg font-bold text-red-700">إشارات تستدعي تدخّلك</h2>
          <div className="grid gap-3 sm:grid-cols-2 lg:grid-cols-3">
            {anomalies.map((a) => (
              <Link
                key={a.label}
                href={a.href}
                className="flex items-center justify-between gap-3 rounded-xl border border-red-300 bg-red-50 px-4 py-3 text-red-700 transition-shadow hover:shadow-md"
              >
                <span className="text-sm font-bold">{a.label}</span>
                {a.count != null ? (
                  <span className="text-2xl font-bold">{formatNumber(a.count)}</span>
                ) : (
                  <span className="text-xl">●</span>
                )}
              </Link>
            ))}
          </div>
        </section>
      ) : null}

      <div className="grid gap-4 sm:grid-cols-3 lg:grid-cols-6">
        {kpis.map((k) => (
          <div key={k.label} className="rounded-xl border border-border bg-white p-4">
            <p className="text-xs text-foreground/60">{k.label}</p>
            <p className="mt-1 text-2xl font-bold text-primary">
              {formatNumber(k.value)}
              {k.suffix ?? ""}
            </p>
            {k.sub ? <p className="text-xs text-foreground/40">{k.sub}</p> : null}
          </div>
        ))}
      </div>

      <section className="flex flex-col gap-3">
        <h2 className="text-lg font-bold">يحتاج انتباهك</h2>
        <div className="grid gap-3 sm:grid-cols-2 lg:grid-cols-3">
          {alerts.map((a) => (
            <AlertCard key={a.label} {...a} />
          ))}
        </div>
      </section>

      <div className="grid gap-4 lg:grid-cols-2">
        <div className="rounded-xl border border-border bg-white p-5">
          <h2 className="mb-4 font-bold">إيراد الاشتراكات بالشهر (ج.م)</h2>
          <RevenueChart data={chart} />
        </div>
        <div className="rounded-xl border border-border bg-white p-5">
          <h2 className="mb-4 font-bold">الالتحاق الجديد بالشهر</h2>
          <TrendChart data={enrollChart} />
        </div>
      </div>

      <section className="flex flex-col gap-3">
        <h2 className="text-lg font-bold">النشاط المباشر</h2>
        <ActivityFeed initial={(activity.data ?? []) as ActivityEntry[]} />
      </section>
    </div>
  );
}

function AlertCard({
  label,
  count,
  href,
  tone,
}: {
  label: string;
  count: number;
  href: string;
  tone: "red" | "amber" | "blue";
}) {
  const calm = count === 0;
  const toneCls = calm
    ? "border-border bg-white text-foreground/50"
    : tone === "red"
      ? "border-red-200 bg-red-50 text-red-700"
      : tone === "amber"
        ? "border-amber-200 bg-amber-50 text-amber-700"
        : "border-blue-200 bg-blue-50 text-blue-700";
  return (
    <Link
      href={href}
      className={`flex items-center justify-between gap-3 rounded-xl border px-4 py-3 transition-shadow hover:shadow-md ${toneCls}`}
    >
      <span className="text-sm font-medium">{label}</span>
      <span className="text-2xl font-bold">{formatNumber(count)}</span>
    </Link>
  );
}
