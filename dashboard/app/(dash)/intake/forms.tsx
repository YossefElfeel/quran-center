"use client";
import { SubmitButton } from "@/components/ui/button";
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

export function ApplicantForm({ levels }: { levels: Option[] }) {
  const [state, action] = useActionState<FormResult | null, FormData>(
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
        المستوى المستهدف
        <FieldSelect feedback={state} name="level_id" required defaultValue="" className="text-sm">
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
      <SubmitButton className="text-sm">أضف لقائمة الانتظار</SubmitButton>
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
  const [state, action] = useActionState<FormResult | null, FormData>(
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
        className="py-1 text-sm"
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
        className="py-1 text-sm"
      />
      <SubmitButton size="sm" variant="secondary">سجّل النتيجة</SubmitButton>
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
  const [state, action] = useActionState<FormResult | null, FormData>(
    enrollFromWaiting,
    null,
  );
  useActionFeedback(state);
  return (
    <form action={action} className="flex flex-wrap items-center gap-2">
      <input type="hidden" name="waiting_id" value={waitingId} />
      <input type="hidden" name="student_person_id" value={studentPersonId} />
      <span className="text-xs text-foreground/50">إسناد لحلقة:</span>
      <FieldSelect feedback={state} name="circle_id" required defaultValue="" className="py-1 text-sm">
        <option value="" disabled>
          — اختر حلقة —
        </option>
        {circles.map((c) => (
          <option key={c.id} value={c.id}>
            {c.label}
          </option>
        ))}
      </FieldSelect>
      <SubmitButton size="sm" variant="secondary">أسنِد وفعّل</SubmitButton>
      {state?.ok === false ? (
        <span className="text-xs text-red-600">{state.error}</span>
      ) : null}
    </form>
  );
}
