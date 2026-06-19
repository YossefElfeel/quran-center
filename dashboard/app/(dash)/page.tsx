import Link from "next/link";

import { formatNumber } from "@/lib/format";
import { createSupabaseServerClient } from "@/lib/supabase/server";

import { RevenueChart } from "./analytics/revenue-chart";

function currentMonth(): string {
  const now = new Date();
  return new Date(Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), 1))
    .toISOString()
    .slice(0, 10);
}

const HEAD = { count: "exact" as const, head: true };

export default async function DashHome() {
  const supabase = await createSupabaseServerClient();
  const month = currentMonth();

  const [
    activeStudents,
    activeCircles,
    totalCircles,
    teachers,
    households,
    openComplaints,
    waiting,
    devPending,
    msePending,
    excusePending,
    struggling,
    tasmeeTotal,
    tasmeePassed,
    attTotal,
    attPresent,
    paidThisMonth,
    payments,
  ] = await Promise.all([
    supabase.from("enrollment").select("*", HEAD).eq("status", "active"),
    supabase.from("circle").select("*", HEAD).eq("status", "active"),
    supabase.from("circle").select("*", HEAD),
    supabase.from("role_assignment").select("*", HEAD).eq("role", "teacher"),
    supabase.from("household").select("*", HEAD),
    supabase.from("complaint").select("*", HEAD).eq("status", "open"),
    supabase.from("waiting_list").select("*", HEAD).eq("status", "waiting"),
    supabase.from("teacher_development").select("*", HEAD).eq("status", "submitted"),
    supabase
      .from("monthly_student_evaluation")
      .select("*", HEAD)
      .eq("status", "submitted"),
    supabase.from("excuse_request").select("*", HEAD).eq("status", "pending"),
    supabase
      .from("portion_ledger_entry")
      .select("*", HEAD)
      .eq("state", "failed_retry")
      .gte("attempts_count", 3),
    supabase.from("daily_tasmee").select("*", HEAD),
    supabase.from("daily_tasmee").select("*", HEAD).eq("passed", true),
    supabase.from("attendance").select("*", HEAD),
    supabase.from("attendance").select("*", HEAD).eq("status", "present"),
    supabase
      .from("subscription_payment")
      .select("household_id")
      .eq("voided", false)
      .eq("period_month", month),
    supabase
      .from("subscription_payment")
      .select("period_month, amount")
      .eq("voided", false),
  ]);

  const n = (r: { count: number | null }) => r.count ?? 0;
  const passRate = n(tasmeeTotal)
    ? Math.round((n(tasmeePassed) / n(tasmeeTotal)) * 100)
    : 0;
  const attRate = n(attTotal)
    ? Math.round((n(attPresent) / n(attTotal)) * 100)
    : 0;
  const paidHouseholds = new Set(
    ((paidThisMonth.data ?? []) as { household_id: string }[]).map(
      (r) => r.household_id,
    ),
  ).size;
  const overdue = Math.max(0, n(households) - paidHouseholds);
  const pendingApprovals = n(devPending) + n(msePending);

  const byMonth = new Map<string, number>();
  for (const p of (payments.data ?? []) as {
    period_month: string;
    amount: number;
  }[]) {
    const m = String(p.period_month).slice(0, 7);
    byMonth.set(m, (byMonth.get(m) ?? 0) + Number(p.amount));
  }
  const chart = [...byMonth.entries()]
    .sort((a, b) => a[0].localeCompare(b[0]))
    .slice(-12)
    .map(([m, total]) => ({ month: m, total }));

  const kpis = [
    { label: "الطلاب النشطين", value: n(activeStudents) },
    { label: "الحلقات النشطة", value: n(activeCircles), sub: `من ${n(totalCircles)}` },
    { label: "المعلّمون", value: n(teachers) },
    { label: "الأسر", value: n(households) },
    { label: "نسبة النجاح", value: passRate, suffix: "٪" },
    { label: "نسبة الحضور", value: attRate, suffix: "٪" },
  ];

  const alerts = [
    {
      label: "اشتراكات متأخّرة",
      count: overdue,
      href: "/subscriptions",
      tone: "red" as const,
    },
    {
      label: "اعتمادات معلّقة (تطوّر + تقييم شهري)",
      count: pendingApprovals,
      href: "/evaluations",
      tone: "amber" as const,
    },
    {
      label: "أعذار غياب معلّقة",
      count: n(excusePending),
      href: "/excuses",
      tone: "amber" as const,
    },
    {
      label: "طلبة متعثّرون (٣+ محاولات)",
      count: n(struggling),
      href: "/circles",
      tone: "red" as const,
    },
    {
      label: "في قائمة الانتظار",
      count: n(waiting),
      href: "/intake",
      tone: "blue" as const,
    },
    {
      label: "شكاوى مفتوحة",
      count: n(openComplaints),
      href: "/complaints",
      tone: "amber" as const,
    },
  ];

  return (
    <div className="flex flex-col gap-6">
      <h1 className="text-2xl font-bold">نظرة عامة</h1>

      <div className="grid gap-4 sm:grid-cols-3 lg:grid-cols-6">
        {kpis.map((k) => (
          <div
            key={k.label}
            className="rounded-xl border border-border bg-white p-4"
          >
            <p className="text-xs text-foreground/60">{k.label}</p>
            <p className="mt-1 text-2xl font-bold text-primary">
              {formatNumber(k.value)}
              {k.suffix ?? ""}
            </p>
            {k.sub ? (
              <p className="text-xs text-foreground/40">{k.sub}</p>
            ) : null}
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

      <div className="rounded-xl border border-border bg-white p-5">
        <h2 className="mb-4 font-bold">إيراد الاشتراكات بالشهر (ج.م)</h2>
        <RevenueChart data={chart} />
      </div>
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
