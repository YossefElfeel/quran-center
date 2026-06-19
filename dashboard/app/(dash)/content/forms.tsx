"use client";

import { useActionState, useEffect, useRef } from "react";

import {
  addCourse,
  createCompetition,
  setApplicationStatus,
  setCompetitionStatus,
  type FormResult,
} from "./actions";

export { DeleteButton } from "@/components/admin-controls";

const input =
  "rounded-lg border border-border px-3 py-2 text-sm outline-none focus:border-primary";
const btn =
  "rounded-lg bg-primary px-4 py-2 text-sm font-bold text-white transition-opacity hover:opacity-90 disabled:opacity-60";
const btnSm =
  "rounded-md border border-border px-2 py-1 text-xs hover:bg-border/40 disabled:opacity-50";

const COMP_STATUS = [
  { value: "draft", label: "مسودّة" },
  { value: "open", label: "مفتوحة" },
  { value: "judging", label: "تحكيم" },
  { value: "closed", label: "مقفولة" },
];

export function CourseForm() {
  const [state, action, pending] = useActionState<FormResult | null, FormData>(
    addCourse,
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
        عنوان الكورس
        <input name="title" required className={input} />
      </label>
      <label className="flex flex-1 flex-col gap-1 text-sm">
        رابط الفيديو
        <input name="video_url" required dir="ltr" className={input} />
      </label>
      <button className={btn} disabled={pending}>
        {pending ? "…" : "أضف كورس"}
      </button>
      {state?.ok === false ? (
        <span className="w-full text-sm text-red-600">{state.error}</span>
      ) : null}
    </form>
  );
}

export function CompetitionForm() {
  const [state, action, pending] = useActionState<FormResult | null, FormData>(
    createCompetition,
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
        اسم المسابقة
        <input name="name" required className={input} />
      </label>
      <label className="flex flex-col gap-1 text-sm">
        السنة
        <input name="year" type="number" className={`${input} w-28`} />
      </label>
      <button className={btn} disabled={pending}>
        {pending ? "…" : "أضف مسابقة"}
      </button>
      {state?.ok === false ? (
        <span className="w-full text-sm text-red-600">{state.error}</span>
      ) : null}
    </form>
  );
}

export function CompetitionStatus({
  id,
  current,
}: {
  id: string;
  current: string;
}) {
  const [state, action, pending] = useActionState<FormResult | null, FormData>(
    setCompetitionStatus,
    null,
  );
  return (
    <form action={action} className="flex items-center gap-2">
      <input type="hidden" name="id" value={id} />
      <select name="status" defaultValue={current} className={`${input} py-1`}>
        {COMP_STATUS.map((s) => (
          <option key={s.value} value={s.value}>
            {s.label}
          </option>
        ))}
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

export function ApplicationDecision({
  id,
  competitionId,
}: {
  id: string;
  competitionId: string;
}) {
  const [state, action, pending] = useActionState<FormResult | null, FormData>(
    setApplicationStatus,
    null,
  );
  return (
    <form action={action} className="flex items-center gap-2">
      <input type="hidden" name="id" value={id} />
      <input type="hidden" name="competition_id" value={competitionId} />
      <button
        name="status"
        value="accepted"
        disabled={pending}
        className="rounded-md border border-green-300 px-3 py-1 text-xs text-green-700 hover:bg-green-50 disabled:opacity-50"
      >
        قبول
      </button>
      <button
        name="status"
        value="rejected"
        disabled={pending}
        className="rounded-md border border-red-300 px-3 py-1 text-xs text-red-600 hover:bg-red-50 disabled:opacity-50"
      >
        رفض
      </button>
      {state?.ok === false ? (
        <span className="text-xs text-red-600">{state.error}</span>
      ) : null}
    </form>
  );
}
