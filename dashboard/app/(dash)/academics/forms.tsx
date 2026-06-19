"use client";

import { useActionState, useEffect, useRef } from "react";

import {
  createCircle,
  createCurriculum,
  createLevel,
  updateCircle,
  type FormResult,
} from "./actions";

export type Teacher = { id: string; name: string };
export type Circle = {
  id: string;
  level_id: string;
  name: string;
  max_size: number;
  status: string;
  teacher_id: string | null;
};

// DeleteButton مشترك لكل أقسام اللوحة.
export { DeleteButton } from "@/components/admin-controls";

const input =
  "rounded-lg border border-border px-3 py-2 text-sm outline-none focus:border-primary";
const btn =
  "rounded-lg bg-primary px-4 py-2 text-sm font-bold text-white transition-opacity hover:opacity-90 disabled:opacity-60";
const btnSm =
  "rounded-md border border-border px-2 py-1 text-xs hover:bg-border/40 disabled:opacity-50";
export function CurriculumForm() {
  const [state, action, pending] = useActionState<FormResult | null, FormData>(
    createCurriculum,
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
        اسم المنهج
        <input name="name" required className={input} />
      </label>
      <label className="flex flex-col gap-1 text-sm">
        النوع
        <select name="type" defaultValue="quran" className={input}>
          <option value="quran">قرآن</option>
          <option value="arabic_foundation">تأسيس عربي</option>
        </select>
      </label>
      <button className={btn} disabled={pending}>
        {pending ? "…" : "أضف منهج"}
      </button>
      {state?.ok === false ? (
        <span className="w-full text-sm text-red-600">{state.error}</span>
      ) : null}
    </form>
  );
}

export function LevelForm({ curriculumId }: { curriculumId: string }) {
  const [state, action, pending] = useActionState<FormResult | null, FormData>(
    createLevel,
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
      <input type="hidden" name="curriculum_id" value={curriculumId} />
      <label className="flex flex-col gap-1 text-sm">
        اسم المستوى
        <input name="name" required className={input} />
      </label>
      <button className={btn} disabled={pending}>
        {pending ? "…" : "أضف مستوى"}
      </button>
      {state?.ok === false ? (
        <span className="w-full text-sm text-red-600">{state.error}</span>
      ) : null}
    </form>
  );
}

export function CircleForm({
  levelId,
  curriculumId,
  teachers,
}: {
  levelId: string;
  curriculumId: string;
  teachers: Teacher[];
}) {
  const [state, action, pending] = useActionState<FormResult | null, FormData>(
    createCircle,
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
      <input type="hidden" name="level_id" value={levelId} />
      <input type="hidden" name="curriculum_id" value={curriculumId} />
      <label className="flex flex-col gap-1 text-sm">
        اسم الحلقة
        <input name="name" required className={input} />
      </label>
      <label className="flex flex-col gap-1 text-sm">
        المعلّم
        <select name="teacher_id" defaultValue="" className={input}>
          <option value="">— بدون معلّم —</option>
          {teachers.map((t) => (
            <option key={t.id} value={t.id}>
              {t.name}
            </option>
          ))}
        </select>
      </label>
      <label className="flex flex-col gap-1 text-sm">
        الحد الأقصى
        <input
          name="max_size"
          type="number"
          min={1}
          defaultValue={30}
          className={`${input} w-24`}
        />
      </label>
      <button className={btn} disabled={pending}>
        {pending ? "…" : "أضف حلقة"}
      </button>
      {state?.ok === false ? (
        <span className="w-full text-sm text-red-600">{state.error}</span>
      ) : null}
    </form>
  );
}

// تعديل حلقة قائمة: المعلّم + الحالة + الحد الأقصى.
export function CircleControls({
  circle,
  curriculumId,
  teachers,
}: {
  circle: Circle;
  curriculumId: string;
  teachers: Teacher[];
}) {
  const [state, action, pending] = useActionState<FormResult | null, FormData>(
    updateCircle,
    null,
  );
  return (
    <form action={action} className="flex flex-wrap items-center gap-2">
      <input type="hidden" name="id" value={circle.id} />
      <input type="hidden" name="level_id" value={circle.level_id} />
      <input type="hidden" name="curriculum_id" value={curriculumId} />
      <select
        name="teacher_id"
        defaultValue={circle.teacher_id ?? ""}
        className={`${input} py-1`}
      >
        <option value="">— بدون معلّم —</option>
        {teachers.map((t) => (
          <option key={t.id} value={t.id}>
            {t.name}
          </option>
        ))}
      </select>
      <select
        name="status"
        defaultValue={circle.status}
        className={`${input} py-1`}
      >
        <option value="forming">قيد التكوين</option>
        <option value="active">نشطة</option>
        <option value="graduated">متخرّجة</option>
      </select>
      <input
        name="max_size"
        type="number"
        min={1}
        defaultValue={circle.max_size}
        className={`${input} w-20 py-1`}
      />
      <button className={btnSm} disabled={pending}>
        {pending ? "…" : "حفظ"}
      </button>
      {state?.ok === false ? (
        <span className="text-xs text-red-600">{state.error}</span>
      ) : null}
    </form>
  );
}

