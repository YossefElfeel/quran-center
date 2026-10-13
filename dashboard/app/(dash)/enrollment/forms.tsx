"use client";
import { Button, SubmitButton } from "@/components/ui/button";
import { FieldInput, FieldSelect, FieldTextarea } from "@/components/ui/fields";
import { useActionFeedback } from "@/components/ui/feedback";

import { useActionState, useEffect, useRef } from "react";

import {
  bulkEnroll,
  type BulkResult,
  enrollStudent,
  updateEnrollment,
  type FormResult,
} from "./actions";

export type CircleOption = { id: string; label: string };

export function EnrollForm({ circles }: { circles: CircleOption[] }) {
  const [state, action] = useActionState<FormResult | null, FormData>(
    enrollStudent,
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
        اسم الطالب
        <FieldInput feedback={state} name="name" required className="text-sm" />
      </label>
      <label className="flex flex-col gap-1 text-sm">
        النوع
        <FieldSelect feedback={state} name="gender" defaultValue="male" className="text-sm">
          <option value="male">ذكر</option>
          <option value="female">أنثى</option>
        </FieldSelect>
      </label>
      <label className="flex flex-col gap-1 text-sm">
        الحلقة
        <FieldSelect feedback={state} name="circle_id" required defaultValue="" className="text-sm">
          <option value="" disabled>
            — اختر حلقة —
          </option>
          {circles.map((c) => (
            <option key={c.id} value={c.id}>
              {c.label}
            </option>
          ))}
        </FieldSelect>
      </label>
      <label className="flex flex-col gap-1 text-sm">
        الرقم القومي (اختياري)
        <FieldInput feedback={state}
          name="national_id"
          inputMode="numeric"
          dir="ltr"
          className="w-44 text-sm"
        />
      </label>
      <SubmitButton className="text-sm">سجّل الطالب</SubmitButton>
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
  const [state, action] = useActionState<FormResult | null, FormData>(
    updateEnrollment,
    null,
  );
  useActionFeedback(state);
  return (
    <form action={action} className="flex flex-wrap items-center gap-2">
      <input type="hidden" name="id" value={enrollmentId} />
      <FieldSelect feedback={state}
        name="circle_id"
        defaultValue={currentCircleId}
        className="py-1 text-sm"
      >
        {circles.map((c) => (
          <option key={c.id} value={c.id}>
            {c.label}
          </option>
        ))}
      </FieldSelect>
      <FieldSelect feedback={state}
        name="status"
        defaultValue={currentStatus}
        className="py-1 text-sm"
      >
        <option value="active">نشط</option>
        <option value="paused">موقوف مؤقتًا</option>
        <option value="graduated">متخرّج</option>
        <option value="dropped">منسحب</option>
        <option value="transferred">منقول</option>
      </FieldSelect>
      <SubmitButton size="sm" variant="secondary">حفظ</SubmitButton>
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
  useActionFeedback(state);
  return (
    <form
      action={action}
      className="flex flex-col gap-3 rounded-xl border border-border bg-white p-4"
    >
      <label className="flex flex-col gap-1 text-sm">
        الحلقة
        <FieldSelect feedback={state} name="circle_id" required defaultValue="" className="text-sm">
          <option value="" disabled>
            — اختر حلقة —
          </option>
          {circles.map((c) => (
            <option key={c.id} value={c.id}>
              {c.label}
            </option>
          ))}
        </FieldSelect>
      </label>
      <label className="flex flex-col gap-1 text-sm">
        الأسماء (كل سطر: الاسم[,ذكر/أنثى]) — حتى ١٠٠
        <FieldTextarea feedback={state}
          name="rows"
          rows={5}
          placeholder={"محمد علي\nسارة أحمد,أنثى"}
          className="text-sm"
        />
      </label>
      <Button className="self-start text-sm" disabled={pending} aria-busy={pending}>
        {pending ? "بنسجّل…" : "سجّل الكل"}
      </Button>
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
