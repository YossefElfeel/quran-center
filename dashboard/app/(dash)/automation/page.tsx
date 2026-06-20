import { DangerAction } from "@/components/danger-action";
import { formatDateTime } from "@/lib/format";
import { createSupabaseServerClient } from "@/lib/supabase/server";

import { runCronNow, setCronActive } from "./actions";

const JOB_LABEL: Record<string, string> = {
  "monthly-close": "الإقفال الشهري",
  "media-retention": "سياسة الاحتفاظ بالوسائط",
  "purge-public-registrations": "تنظيف التسجيلات العامّة",
  "nominate-certificate-candidates": "ترشيح مرشّحي الشهادات",
  "escalate-overdue-complaints": "تصعيد الشكاوى المتأخّرة",
  "notify-overdue-subscriptions": "تنبيه الاشتراكات المتأخّرة",
};

type Job = {
  jobid: number;
  jobname: string;
  schedule: string;
  active: boolean;
};

type AuditRow = {
  action: string;
  meta: { jobname?: string } | null;
  at: string;
};

export default async function AutomationPage() {
  const supabase = await createSupabaseServerClient();
  const [jobsRes, recentRes] = await Promise.all([
    supabase.rpc("cron_jobs"),
    supabase
      .from("audit_log")
      .select("action, meta, at")
      .eq("action", "cron_run_now")
      .order("at", { ascending: false })
      .limit(50),
  ]);

  const jobs = (jobsRes.data ?? []) as Job[];
  const recent = (recentRes.data ?? []) as AuditRow[];
  const lastRun = new Map<string, string>();
  for (const r of recent) {
    const jn = r.meta?.jobname;
    if (jn && !lastRun.has(jn)) lastRun.set(jn, r.at);
  }

  return (
    <div className="flex flex-col gap-6">
      <div className="flex flex-col gap-1">
        <h1 className="text-2xl font-bold">الأتمتة والمجدولات</h1>
        <p className="text-sm text-foreground/60">
          تحكّم كامل في مهام pg_cron — تفعيل/تعطيل أو تشغيل فوري. كل عملية بتتسجّل في
          التدقيق وبتطلّع تنبيه فوري.
        </p>
      </div>

      <div className="overflow-x-auto rounded-xl border border-border bg-white">
        <table className="w-full min-w-[720px] text-right text-sm">
          <thead className="border-b border-border bg-background/50 text-foreground/60">
            <tr>
              <th className="px-4 py-2 font-medium">المهمّة</th>
              <th className="px-4 py-2 font-medium">الجدول</th>
              <th className="px-4 py-2 font-medium">الحالة</th>
              <th className="px-4 py-2 font-medium">آخر تشغيل يدوي</th>
              <th className="px-4 py-2 font-medium">إجراءات</th>
            </tr>
          </thead>
          <tbody>
            {jobs.length === 0 ? (
              <tr>
                <td colSpan={5} className="px-4 py-6 text-center text-foreground/50">
                  مفيش مهام (اتأكد إن RPC منشور والمايجريشن متطبّق).
                </td>
              </tr>
            ) : (
              jobs.map((j) => (
                <tr key={j.jobid} className="border-b border-border/60">
                  <td className="px-4 py-2 font-medium">
                    {JOB_LABEL[j.jobname] ?? j.jobname}
                    <div className="text-xs text-foreground/40" dir="ltr">
                      {j.jobname}
                    </div>
                  </td>
                  <td className="px-4 py-2">
                    <code className="text-xs" dir="ltr">
                      {j.schedule}
                    </code>
                  </td>
                  <td className="px-4 py-2">
                    <span
                      className={`rounded-full px-2 py-0.5 text-xs ${
                        j.active
                          ? "bg-green-100 text-green-700"
                          : "bg-gray-200 text-gray-600"
                      }`}
                    >
                      {j.active ? "مفعّلة" : "متوقّفة"}
                    </span>
                  </td>
                  <td className="px-4 py-2 text-xs text-foreground/50">
                    {lastRun.has(j.jobname)
                      ? formatDateTime(lastRun.get(j.jobname)!)
                      : "—"}
                  </td>
                  <td className="px-4 py-2">
                    <div className="flex flex-wrap items-center justify-end gap-1">
                      <DangerAction
                        action={runCronNow}
                        tone="warn"
                        label="تشغيل الآن"
                        title={`تشغيل «${JOB_LABEL[j.jobname] ?? j.jobname}» فورًا`}
                        description="هتشتغل المهمّة دلوقتي على بيانات الإنتاج."
                        submitLabel="شغّل"
                        hidden={{ jobname: j.jobname }}
                      />
                      <DangerAction
                        action={setCronActive}
                        tone={j.active ? "danger" : "warn"}
                        label={j.active ? "تعطيل" : "تفعيل"}
                        title={`${j.active ? "تعطيل" : "تفعيل"} «${
                          JOB_LABEL[j.jobname] ?? j.jobname
                        }»`}
                        description={
                          j.active
                            ? "المهمّة مش هتشتغل في مواعيدها لحد ما تفعّلها تاني."
                            : "المهمّة هترجع تشتغل في مواعيدها."
                        }
                        submitLabel={j.active ? "عطّل" : "فعّل"}
                        hidden={{ jobname: j.jobname, active: String(!j.active) }}
                      />
                    </div>
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
