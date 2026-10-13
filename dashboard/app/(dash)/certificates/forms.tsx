"use client";
import { FieldSelect } from "@/components/ui/fields";
import { useActionFeedback } from "@/components/ui/feedback";

import Link from "next/link";
import { useActionState } from "react";

import { issueCertificate, type FormResult } from "./actions";

export { DeleteButton } from "@/components/admin-controls";

export type Student = { id: string; name: string };

const input =
  "rounded-lg border border-border px-3 py-2 text-sm outline-none focus:border-primary";
const btn =
  "rounded-lg bg-primary px-4 py-2 text-sm font-bold text-white transition-opacity hover:opacity-90 disabled:opacity-60";

const KINDS = [
  { value: "juz_amma", label: "جزء عمّ" },
  { value: "half", label: "النصف" },
  { value: "full", label: "كامل" },
  { value: "honor", label: "تكريم (يتخطّى الأهلية)" },
];

export function IssueForm({ students,selectedStudent }: { students: Student[];selectedStudent?:string }) {
  const [state, action, pending] = useActionState<FormResult | null, FormData>(
    issueCertificate,
    null,
  );
  useActionFeedback(state);
  return (
    <form
      action={action}
      className="flex flex-wrap items-end gap-3 rounded-xl border border-border bg-white p-4"
    >
      <label className="flex flex-col gap-1 text-sm">
        الطالب
        <FieldSelect feedback={state} name="student_person_id" required defaultValue={students.some(s=>s.id===selectedStudent)?selectedStudent:""} className={input}>
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
      <label className="flex flex-col gap-1 text-sm">
        النوع
        <FieldSelect feedback={state} name="kind" defaultValue="full" className={input}>
          {KINDS.map((k) => (
            <option key={k.value} value={k.value}>
              {k.label}
            </option>
          ))}
        </FieldSelect>
      </label>
      <button className={btn} disabled={pending}>
        {pending ? "…" : "أصدِر الشهادة"}
      </button>
      {state?.ok===true?<p role="status" className="w-full text-primary">الشهادة صدرت. {state.certificateId?<Link href={`/certificates/${state.certificateId}`} className="underline">عرض PDF</Link>:null}</p>:null}
      {state?.ok === false ? (
        <span role="alert" className="w-full text-sm text-red-600">{state.error}</span>
      ) : null}
    </form>
  );
}
