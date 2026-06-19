"use client";

import { useActionState, useEffect, useRef } from "react";

import { addBehavioralNote, correctLedger, type FormResult } from "./actions";

export type Student = { id: string; name: string };

const input =
  "rounded-lg border border-border px-3 py-2 text-sm outline-none focus:border-primary";
const btn =
  "rounded-lg bg-primary px-4 py-2 text-sm font-bold text-white transition-opacity hover:opacity-90 disabled:opacity-60";
const btnSm =
  "rounded-md border border-border px-2 py-1 text-xs hover:bg-border/40 disabled:opacity-50";

export { DeleteButton } from "@/components/admin-controls";

export function LedgerControl({
  studentPersonId,
  portionId,
  circleId,
  current,
}: {
  studentPersonId: string;
  portionId: string;
  circleId: string;
  current: string;
}) {
  const [state, action, pending] = useActionState<FormResult | null, FormData>(
    correctLedger,
    null,
  );
  return (
    <form action={action} className="flex items-center gap-2">
      <input type="hidden" name="student_person_id" value={studentPersonId} />
      <input type="hidden" name="portion_id" value={portionId} />
      <input type="hidden" name="circle_id" value={circleId} />
      <select name="state" defaultValue={current} className={`${input} py-1`}>
        <option value="assigned">مُسنَد</option>
        <option value="failed_retry">رسب/إعادة</option>
        <option value="passed">عدّى</option>
      </select>
      <button className={btnSm} disabled={pending}>
        {pending ? "…" : "صحّح"}
      </button>
      {state?.ok === false ? (
        <span className="text-xs text-red-600">{state.error}</span>
      ) : null}
    </form>
  );
}

export function NoteForm({
  circleId,
  students,
}: {
  circleId: string;
  students: Student[];
}) {
  const [state, action, pending] = useActionState<FormResult | null, FormData>(
    addBehavioralNote,
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
      <input type="hidden" name="circle_id" value={circleId} />
      <label className="flex flex-col gap-1 text-sm">
        الطالب
        <select name="student_person_id" required defaultValue="" className={input}>
          <option value="" disabled>
            — اختر طالب —
          </option>
          {students.map((s) => (
            <option key={s.id} value={s.id}>
              {s.name}
            </option>
          ))}
        </select>
      </label>
      <label className="flex flex-1 flex-col gap-1 text-sm">
        الملاحظة
        <input name="text" required className={input} />
      </label>
      <label className="flex flex-col gap-1 text-sm">
        الظهور
        <select name="visibility" defaultValue="internal" className={input}>
          <option value="internal">داخلي</option>
          <option value="parent">لولي الأمر</option>
        </select>
      </label>
      <button className={btn} disabled={pending}>
        {pending ? "…" : "أضف ملاحظة"}
      </button>
      {state?.ok === false ? (
        <span className="w-full text-sm text-red-600">{state.error}</span>
      ) : null}
    </form>
  );
}
