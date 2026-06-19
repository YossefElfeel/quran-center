"use client";

import { useActionState, useEffect, useRef } from "react";

import {
  bulkEnroll,
  type BulkResult,
  enrollStudent,
  updateEnrollment,
  type FormResult,
} from "./actions";

export type CircleOption = { id: string; label: string };

const input =
  "rounded-lg border border-border px-3 py-2 text-sm outline-none focus:border-primary";
const btn =
  "rounded-lg bg-primary px-4 py-2 text-sm font-bold text-white transition-opacity hover:opacity-90 disabled:opacity-60";
const btnSm =
  "rounded-md border border-border px-2 py-1 text-xs hover:bg-border/40 disabled:opacity-50";

export function EnrollForm({ circles }: { circles: CircleOption[] }) {
  const [state, action, pending] = useActionState<FormResult | null, FormData>(
    enrollStudent,
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
        اسم الطالب
        <input name="name" required className={input} />
      </label>
      <label className="flex flex-col gap-1 text-sm">
        النوع
        <select name="gender" defaultValue="male" className={input}>
          <option value="male">ذكر</option>
          <option value="female">أنثى</option>
        </select>
      </label>
      <label className="flex flex-col gap-1 text-sm">
        الحلقة
        <select name="circle_id" required defaultValue="" className={input}>
          <option value="" disabled>
            — اختر حلقة —
          </option>
          {circles.map((c) => (
            <option key={c.id} value={c.id}>
              {c.label}
            </option>
          ))}
        </select>
      </label>
      <label className="flex flex-col gap-1 text-sm">
        الرقم القومي (اختياري)
        <input
          name="national_id"
          inputMode="numeric"
          dir="ltr"
          className={`${input} w-44`}
        />
      </label>
      <button className={btn} disabled={pending}>
        {pending ? "…" : "سجّل الطالب"}
      </button>
      {state?.ok === false ? (
        <span className="w-full text-sm text-red-600">{state.error}</span>
      ) : null}
    </form>
  );
}

export function EnrollmentControls({
  enrollmentId,
  currentCircleId,
  currentStatus,
  circles,
}: {
  enrollmentId: string;
  currentCircleId: string;
  currentStatus: string;
  circles: CircleOption[];
}) {
  const [state, action, pending] = useActionState<FormResult | null, FormData>(
    updateEnrollment,
    null,
  );
  return (
    <form action={action} className="flex flex-wrap items-center gap-2">
      <input type="hidden" name="id" value={enrollmentId} />
      <select
        name="circle_id"
        defaultValue={currentCircleId}
        className={`${input} py-1`}
      >
        {circles.map((c) => (
          <option key={c.id} value={c.id}>
            {c.label}
          </option>
        ))}
      </select>
      <select
        name="status"
        defaultValue={currentStatus}
        className={`${input} py-1`}
      >
        <option value="active">نشط</option>
        <option value="paused">موقوف مؤقتًا</option>
        <option value="graduated">متخرّج</option>
        <option value="dropped">منسحب</option>
        <option value="transferred">منقول</option>
      </select>
      <button className={btnSm} disabled={pending}>
        {pending ? "…" : "حفظ"}
      </button>
      {state?.ok === false ? (
        <span className="text-xs text-red-600">{state.error}</span>
      ) : null}
    </form>
  );
}

export function BulkEnrollForm({ circles }: { circles: CircleOption[] }) {
  const [state, action, pending] = useActionState<BulkResult | null, FormData>(
    bulkEnroll,
    null,
  );
  return (
    <form
      action={action}
      className="flex flex-col gap-3 rounded-xl border border-border bg-white p-4"
    >
      <label className="flex flex-col gap-1 text-sm">
        الحلقة
        <select name="circle_id" required defaultValue="" className={input}>
          <option value="" disabled>
            — اختر حلقة —
          </option>
          {circles.map((c) => (
            <option key={c.id} value={c.id}>
              {c.label}
            </option>
          ))}
        </select>
      </label>
      <label className="flex flex-col gap-1 text-sm">
        الأسماء (كل سطر: الاسم[,ذكر/أنثى]) — حتى ١٠٠
        <textarea
          name="rows"
          rows={5}
          placeholder={"محمد علي\nسارة أحمد,أنثى"}
          className={input}
        />
      </label>
      <button className={`${btn} self-start`} disabled={pending}>
        {pending ? "بنسجّل…" : "سجّل الكل"}
      </button>
      {state?.ok === false ? (
        <span className="text-sm text-red-600">{state.error}</span>
      ) : null}
      {state?.ok === true ? (
        <span className="text-sm text-primary">
          اتسجّل {state.enrolled} • فشل {state.failed}
          {state.sample.length ? ` (${state.sample.join("، ")})` : ""}
        </span>
      ) : null}
    </form>
  );
}
