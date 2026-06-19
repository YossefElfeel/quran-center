"use client";

import { useActionState, useEffect, useRef } from "react";

import { broadcast, type FormResult } from "./actions";

export { DeleteButton } from "@/components/admin-controls";

const input =
  "rounded-lg border border-border px-3 py-2 text-sm outline-none focus:border-primary";
const btn =
  "rounded-lg bg-primary px-4 py-2 text-sm font-bold text-white transition-opacity hover:opacity-90 disabled:opacity-60";

const AUDIENCES = [
  { value: "all", label: "كل المستخدمين" },
  { value: "parent", label: "أولياء الأمور" },
  { value: "teacher", label: "المعلّمون" },
  { value: "supervisor", label: "المشرفون" },
  { value: "admin", label: "الأدمن" },
];

export function BroadcastForm() {
  const [state, action, pending] = useActionState<FormResult | null, FormData>(
    broadcast,
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
      className="flex flex-col gap-3 rounded-xl border border-border bg-white p-4"
    >
      <div className="flex flex-wrap items-end gap-3">
        <label className="flex flex-col gap-1 text-sm">
          الجمهور
          <select name="audience" defaultValue="all" className={input}>
            {AUDIENCES.map((a) => (
              <option key={a.value} value={a.value}>
                {a.label}
              </option>
            ))}
          </select>
        </label>
        <label className="flex flex-1 flex-col gap-1 text-sm">
          العنوان
          <input name="title" required className={input} />
        </label>
      </div>
      <label className="flex flex-col gap-1 text-sm">
        النص (اختياري)
        <textarea name="body" rows={2} className={input} />
      </label>
      <button className={`${btn} self-start`} disabled={pending}>
        {pending ? "…" : "ابعت البثّ"}
      </button>
      {state?.ok === false ? (
        <span className="text-sm text-red-600">{state.error}</span>
      ) : null}
      {state?.ok === true ? (
        <span className="text-sm text-primary">اتبعت ✅</span>
      ) : null}
    </form>
  );
}
