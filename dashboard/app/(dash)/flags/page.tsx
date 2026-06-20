import { DangerAction } from "@/components/danger-action";
import { DangerZone } from "@/components/danger-zone";
import { createSupabaseServerClient } from "@/lib/supabase/server";

import { toggleFlag } from "./actions";
import { flagIsDanger, flagLabel } from "./meta";

type Flag = {
  key: string;
  enabled: boolean;
  description: string | null;
  updated_at: string | null;
};

export default async function FlagsPage() {
  const supabase = await createSupabaseServerClient();
  const { data } = await supabase
    .from("feature_flag")
    .select("key, enabled, description, updated_at")
    .order("key");
  const flags = (data ?? []) as Flag[];

  const danger = flags.filter((f) => flagIsDanger(f.key));
  const normal = flags.filter((f) => !flagIsDanger(f.key));

  return (
    <div className="flex flex-col gap-6">
      <div className="flex flex-col gap-1">
        <h1 className="text-2xl font-bold">المفاتيح ووضع الصيانة</h1>
        <p className="text-sm text-foreground/60">
          المفاتيح بتتفرض على مستوى قاعدة البيانات — تجميد الجلسات/المدفوعات بيمنع
          التطبيق نفسه من الكتابة، مش بس اللوحة. السوبر أدمن مستثنى دايمًا.
        </p>
      </div>

      {danger.length ? (
        <DangerZone description="تفعيل أي من دول بيوقف نشاط حقيقي على كل المستخدمين فورًا.">
          {danger.map((f) => (
            <FlagRow key={f.key} flag={f} />
          ))}
        </DangerZone>
      ) : null}

      {normal.length ? (
        <section className="flex flex-col gap-3">
          <h2 className="text-lg font-bold">مفاتيح عامّة</h2>
          {normal.map((f) => (
            <div
              key={f.key}
              className="rounded-xl border border-border bg-white p-4"
            >
              <FlagRow flag={f} tone="warn" />
            </div>
          ))}
        </section>
      ) : null}
    </div>
  );
}

function FlagRow({
  flag,
  tone = "danger",
}: {
  flag: Flag;
  tone?: "danger" | "warn";
}) {
  const label = flagLabel(flag.key);
  const next = !flag.enabled;
  return (
    <div className="flex flex-wrap items-center justify-between gap-3">
      <div className="flex min-w-0 flex-col gap-0.5">
        <div className="flex items-center gap-2">
          <span className="font-bold">{label}</span>
          <span
            className={`rounded-full px-2 py-0.5 text-xs font-medium ${
              flag.enabled
                ? "bg-red-100 text-red-700"
                : "bg-border/60 text-foreground/60"
            }`}
          >
            {flag.enabled ? "مفعّل" : "مقفول"}
          </span>
        </div>
        {flag.description ? (
          <span className="text-xs text-foreground/60">{flag.description}</span>
        ) : null}
      </div>
      <DangerAction
        action={toggleFlag}
        tone={flag.enabled ? "warn" : tone}
        label={flag.enabled ? "إيقاف" : "تفعيل"}
        title={`${flag.enabled ? "إيقاف" : "تفعيل"} «${label}»`}
        description={
          next
            ? "هيأثّر على كل المستخدمين فورًا. اكتب سبب التغيير."
            : "هيرجّع المفتاح لوضعه الطبيعي. اكتب سبب التغيير."
        }
        submitLabel={flag.enabled ? "أوقف" : "فعّل"}
        hidden={{ key: flag.key, enabled: String(next) }}
      />
    </div>
  );
}
