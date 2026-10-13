"use client";
import { SubmitButton } from "@/components/ui/button";
import { FieldSelect, FieldInput, FieldTextarea } from "@/components/ui/fields";
import { useActionFeedback } from "@/components/ui/feedback";

import { useActionState, useEffect, useRef } from "react";

import { broadcast, type FormResult } from "./actions";

export { DeleteButton } from "@/components/admin-controls";

const AUDIENCES = [
  { value: "all", label: "كل المستخدمين" },
  { value: "parent", label: "أولياء الأمور" },
  { value: "teacher", label: "المعلّمون" },
  { value: "supervisor", label: "المشرفون" },
  { value: "admin", label: "الأدمن" },
];

export function BroadcastForm() {
  const [state, action] = useActionState<FormResult | null, FormData>(
    broadcast,
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
      className="flex flex-col gap-3 rounded-xl border border-border bg-white p-4"
    >
      <div className="flex flex-wrap items-end gap-3">
        <label className="flex flex-col gap-1 text-sm">
          الجمهور
          <FieldSelect feedback={state} name="audience" defaultValue="all" className="text-sm">
            {AUDIENCES.map((a) => (
              <option key={a.value} value={a.value}>
                {a.label}
              </option>
            ))}
          </FieldSelect>
        </label>
        <label className="flex flex-1 flex-col gap-1 text-sm">
          العنوان
          <FieldInput feedback={state} name="title" required className="text-sm" />
        </label>
      </div>
      <label className="flex flex-col gap-1 text-sm">
        النص (اختياري)
        <FieldTextarea feedback={state} name="body" rows={2} className="text-sm" />
      </label>
      <SubmitButton className="self-start text-sm">ابعت البثّ</SubmitButton>
      {state?.ok === false ? (
        <span className="text-sm text-red-600">{state.error}</span>
      ) : null}
      {state?.ok === true ? (
        <span className="text-sm text-primary">اتبعت ✅</span>
      ) : null}
    </form>
  );
}
