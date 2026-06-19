import { formatDateTime, formatNumber } from "@/lib/format";
import { createSupabaseServerClient } from "@/lib/supabase/server";

import { HouseholdForm, PaymentForm, VoidButton } from "./forms";

type Household = { id: string; name: string; monthly_amount: number };
type Payment = {
  id: string;
  household_id: string;
  period_month: string;
  paid_at: string;
  amount: number;
};

export default async function SubscriptionsPage() {
  const supabase = await createSupabaseServerClient();
  const [{ data: households }, { data: payments }] = await Promise.all([
    supabase.from("household").select("id, name, monthly_amount"),
    supabase
      .from("subscription_payment")
      .select("id, household_id, period_month, paid_at, amount")
      .eq("voided", false)
      .order("period_month", { ascending: false }),
  ]);

  const lastByHousehold = new Map<string, Payment>();
  for (const p of (payments ?? []) as Payment[]) {
    if (!lastByHousehold.has(p.household_id)) {
      lastByHousehold.set(p.household_id, p);
    }
  }

  // بداية الشهر الحالي (UTC) — لو آخر دفعة لشهر أقدم → متأخّر.
  const now = new Date();
  const monthStart = new Date(
    Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), 1),
  );

  const rows = ((households ?? []) as Household[])
    .map((h) => {
      const last = lastByHousehold.get(h.id) ?? null;
      const active = last ? new Date(last.period_month) >= monthStart : false;
      return { ...h, last, active };
    })
    .sort((a, b) => Number(a.active) - Number(b.active));

  return (
    <div className="flex flex-col gap-4">
      <div>
        <h1 className="text-2xl font-bold">الاشتراكات</h1>
        <p className="mt-1 text-sm text-foreground/60">
          حالة اشتراك كل أسرة (كاش). سجّل دفع الشهر أو أبطل آخر دفعة بسبب.
        </p>
      </div>

      <HouseholdForm />

      <div className="overflow-x-auto rounded-xl border border-border bg-white">
        <table className="w-full text-right text-sm">
          <thead className="border-b border-border bg-background/50 text-foreground/60">
            <tr>
              <th className="px-4 py-2 font-medium">الأسرة</th>
              <th className="px-4 py-2 font-medium">الاشتراك الشهري</th>
              <th className="px-4 py-2 font-medium">آخر دفعة</th>
              <th className="px-4 py-2 font-medium">الحالة</th>
              <th className="px-4 py-2 font-medium">إجراءات</th>
            </tr>
          </thead>
          <tbody>
            {rows.length === 0 ? (
              <tr>
                <td
                  colSpan={5}
                  className="px-4 py-6 text-center text-foreground/50"
                >
                  مفيش أسر مسجّلة لسه.
                </td>
              </tr>
            ) : (
              rows.map((h) => (
                <tr key={h.id} className="border-b border-border/60">
                  <td className="px-4 py-2">{h.name}</td>
                  <td className="px-4 py-2">
                    {formatNumber(h.monthly_amount)} ج.م
                  </td>
                  <td className="px-4 py-2 text-foreground/60">
                    {h.last ? formatDateTime(h.last.paid_at) : "—"}
                  </td>
                  <td className="px-4 py-2">
                    {h.active ? (
                      <span className="rounded-full bg-primary/10 px-2 py-0.5 text-xs text-primary">
                        نشط
                      </span>
                    ) : (
                      <span className="rounded-full bg-red-100 px-2 py-0.5 text-xs text-red-600">
                        متأخّر
                      </span>
                    )}
                  </td>
                  <td className="px-4 py-2">
                    <div className="flex flex-wrap items-center gap-2">
                      <PaymentForm
                        householdId={h.id}
                        defaultAmount={h.monthly_amount}
                      />
                      {h.last ? <VoidButton paymentId={h.last.id} /> : null}
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
