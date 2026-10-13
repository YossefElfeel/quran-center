"use client";
import { SubmitButton } from "@/components/ui/button";
import { FieldSelect, FieldInput } from "@/components/ui/fields";
import { useActionFeedback } from "@/components/ui/feedback";

import { useActionState, useEffect, useRef } from "react";

import { addBehavioralNote, correctLedger, type FormResult } from "./actions";

export type Student = { id: string; name: string };

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
  const [state, action] = useActionState<FormResult | null, FormData>(
    correctLedger,
    null,
  );
  useActionFeedback(state);
  return (
    <form action={action} className="flex items-center gap-2">
      <input type="hidden" name="student_person_id" value={studentPersonId} />
      <input type="hidden" name="portion_id" value={portionId} />
      <input type="hidden" name="circle_id" value={circleId} />
      <FieldSelect feedback={state} name="state" defaultValue={current} className="py-1 text-sm">
        <option value="assigned">مُسنَد</option>
        <option value="failed_retry">رسب/إعادة</option>
        <option value="passed">عدّى</option>
      </FieldSelect>
      <SubmitButton size="sm" variant="secondary">صحّح</SubmitButton>
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
  const [state, action] = useActionState<FormResult | null, FormData>(
    addBehavioralNote,
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
      <input type="hidden" name="circle_id" value={circleId} />
      <label className="flex flex-col gap-1 text-sm">
        الطالب
        <FieldSelect feedback={state} name="student_person_id" required defaultValue="" className="text-sm">
          <option value="" disabled>
            — اختر طالب —
          </option>
          {students.map((s) => (
            <option key={s.id} value={s.id}>
              {s.name}
            </option>
          ))}
        </FieldSelect>
      </label>
      <label className="flex flex-1 flex-col gap-1 text-sm">
        الملاحظة
        <FieldInput feedback={state} name="text" required className="text-sm" />
      </label>
      <label className="flex flex-col gap-1 text-sm">
        الظهور
        <FieldSelect feedback={state} name="visibility" defaultValue="internal" className="text-sm">
          <option value="internal">داخلي</option>
          <option value="parent">لولي الأمر</option>
        </FieldSelect>
      </label>
      <SubmitButton className="text-sm">أضف ملاحظة</SubmitButton>
      {state?.ok === false ? (
        <span className="w-full text-sm text-red-600">{state.error}</span>
      ) : null}
    </form>
  );
}
