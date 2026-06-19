"use client";

import { useActionState, useEffect, useRef, useTransition } from "react";

import {
  createHousehold,
  recordPayment,
  voidPayment,
  type FormResult,
} from "./actions";

const input =
  "rounded-lg border border-border px-3 py-2 text-sm outline-none focus:border-primary";
const btn =
  "rounded-lg bg-primary px-4 py-2 text-sm font-bold text-white transition-opacity hover:opacity-90 disabled:opacity-60";
const btnSm =
  "rounded-md border border-border px-2 py-1 text-xs hover:bg-border/40 disabled:opacity-50";

export function HouseholdForm() {
  const [state, action, pending] = useActionState<FormResult | null, FormData>(
    createHousehold,
    null,
  );
  const ref = useRef<HTMLFormElement>(null);
  useEffect(() => {
    if (state?.ok) ref.current?.reset();
  }, [state]);
  return (
    <form
      ref={ref}
      action={action}
      className="flex flex-wrap items-end gap-3 rounded-xl border border-border bg-white p-4"
    >
      <label className="flex flex-col gap-1 text-sm">
        اسم الأسرة
        <input name="name" required className={input} />
      </label>
      <label className="flex flex-col gap-1 text-sm">
        الاشتراك الشهري (ج.م)
        <input
          name="monthly_amount"
          type="number"
          min={0}
          defaultValue={10}
          className={`${input} w-32`}
        />
      </label>
      <button className={btn} disabled={pending}>
        {pending ? "…" : "أضف أسرة"}
      </button>
      {state?.ok === false ? (
        <span className="w-full text-sm text-red-600">{state.error}</span>
      ) : null}
    </form>
  );
}

export function PaymentForm({
  householdId,
  defaultAmount,
}: {
  householdId: string;
  defaultAmount: number;
}) {
  const [state, action, pending] = useActionState<FormResult | null, FormData>(
    recordPayment,
    null,
  );
  return (
    <form action={action} className="flex items-center gap-2">
      <input type="hidden" name="household_id" value={householdId} />
      <input
        name="amount"
        type="number"
        min={0}
        defaultValue={defaultAmount}
        className={`${input} w-24 py-1`}
      />
      <button className={btnSm} disabled={pending}>
        {pending ? "…" : "سجّل دفع الشهر"}
      </button>
      {state?.ok === false ? (
        <span className="text-xs text-red-600">{state.error}</span>
      ) : null}
    </form>
  );
}

export function VoidButton({ paymentId }: { paymentId: string }) {
  const [pending, start] = useTransition();
  return (
    <button
      disabled={pending}
      className="rounded-md border border-red-300 px-2 py-1 text-xs text-red-600 hover:bg-red-50 disabled:opacity-50"
      onClick={() => {
        const reason = window.prompt("سبب إبطال آخر دفعة؟");
        if (!reason) return;
        const fd = new FormData();
        fd.set("id", paymentId);
        fd.set("reason", reason);
        start(async () => {
          const r = await voidPayment(null, fd);
          if (!r.ok) window.alert(r.error);
        });
      }}
    >
      {pending ? "…" : "إبطال آخر دفعة"}
    </button>
  );
}
