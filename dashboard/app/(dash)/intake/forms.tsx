"use client";
import { FieldInput, FieldSelect } from "@/components/ui/fields";
import { useActionFeedback } from "@/components/ui/feedback";

import { useActionState, useEffect, useRef } from "react";

import {
  addApplicant,
  enrollFromWaiting,
  recordPlacement,
  type FormResult,
} from "./actions";

export type Option = { id: string; label: string };

const input =
  "rounded-lg border border-border px-3 py-2 text-sm outline-none focus:border-primary";
const btn =
  "rounded-lg bg-primary px-4 py-2 text-sm font-bold text-white transition-opacity hover:opacity-90 disabled:opacity-60";
const btnSm =
  "rounded-md border border-border px-2 py-1 text-xs hover:bg-border/40 disabled:opacity-50";

export function ApplicantForm({ levels }: { levels: Option[] }) {
  const [state, action, pending] = useActionState<FormResult | null, FormData>(
    addApplicant,
    null,
  );
  useActionFeedback(state);
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
        اسم المتقدّم
        <FieldInput feedback={state} name="name" required className={input} />
      </label>
      <label className="flex flex-col gap-1 text-sm">
        النوع
        <FieldSelect feedback={state} name="gender" defaultValue="male" className={input}>
          <option value="male">ذكر</option>
          <option value="female">أنثى</option>
        </FieldSelect>
      </label>
      <label className="flex flex-col gap-1 text-sm">
        المستوى المستهدف
        <FieldSelect feedback={state} name="level_id" required defaultValue="" className={input}>
          <option value="" disabled>
            — اختر مستوى —
          </option>
          {levels.map((l) => (
            <option key={l.id} value={l.id}>
              {l.label}
            </option>
          ))}
        </FieldSelect>
      </label>
      <button className={btn} disabled={pending}>
        {pending ? "…" : "أضف لقائمة الانتظار"}
      </button>
      {state?.ok === false ? (
        <span className="w-full text-sm text-red-600">{state.error}</span>
      ) : null}
    </form>
  );
}

export function PlacementForm({
  waitingId,
  studentPersonId,
  levels,
  currentLevelId,
}: {
  waitingId: string;
  studentPersonId: string;
  levels: Option[];
  currentLevelId: string;
}) {
  const [state, action, pending] = useActionState<FormResult | null, FormData>(
    recordPlacement,
    null,
  );
  useActionFeedback(state);
  return (
    <form action={action} className="flex flex-wrap items-center gap-2">
      <input type="hidden" name="waiting_id" value={waitingId} />
      <input type="hidden" name="student_person_id" value={studentPersonId} />
      <span className="text-xs text-foreground/50">اختبار تحديد:</span>
      <FieldSelect feedback={state}
        name="result_level_id"
        defaultValue={currentLevelId}
        className={`${input} py-1`}
      >
        {levels.map((l) => (
          <option key={l.id} value={l.id}>
            {l.label}
          </option>
        ))}
      </FieldSelect>
      <FieldInput feedback={state}
        name="notes"
        placeholder="ملاحظات (اختياري)"
        className={`${input} py-1`}
      />
      <button className={btnSm} disabled={pending}>
        {pending ? "…" : "سجّل النتيجة"}
      </button>
      {state?.ok === false ? (
        <span className="text-xs text-red-600">{state.error}</span>
      ) : null}
    </form>
  );
}

export function AssignForm({
  waitingId,
  studentPersonId,
  circles,
}: {
  waitingId: string;
  studentPersonId: string;
  circles: Option[];
}) {
  const [state, action, pending] = useActionState<FormResult | null, FormData>(
    enrollFromWaiting,
    null,
  );
  useActionFeedback(state);
  return (
    <form action={action} className="flex flex-wrap items-center gap-2">
      <input type="hidden" name="waiting_id" value={waitingId} />
      <input type="hidden" name="student_person_id" value={studentPersonId} />
      <span className="text-xs text-foreground/50">إسناد لحلقة:</span>
      <FieldSelect feedback={state} name="circle_id" required defaultValue="" className={`${input} py-1`}>
        <option value="" disabled>
          — اختر حلقة —
        </option>
        {circles.map((c) => (
          <option key={c.id} value={c.id}>
            {c.label}
          </option>
        ))}
      </FieldSelect>
      <button className={btnSm} disabled={pending}>
        {pending ? "…" : "أسنِد وفعّل"}
      </button>
      {state?.ok === false ? (
        <span className="text-xs text-red-600">{state.error}</span>
      ) : null}
    </form>
  );
}
