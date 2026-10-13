"use client";
import { SubmitButton } from "@/components/ui/button";
import { FieldInput, FieldSelect } from "@/components/ui/fields";
import { useActionFeedback } from "@/components/ui/feedback";

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

export function CurriculumForm() {
  const [state, action] = useActionState<FormResult | null, FormData>(
    createCurriculum,
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
        اسم المنهج
        <FieldInput feedback={state} name="name" required className="text-sm" />
      </label>
      <label className="flex flex-col gap-1 text-sm">
        النوع
        <FieldSelect feedback={state} name="type" defaultValue="quran" className="text-sm">
          <option value="quran">قرآن</option>
          <option value="arabic_foundation">تأسيس عربي</option>
        </FieldSelect>
      </label>
      <SubmitButton className="text-sm">أضف منهج</SubmitButton>
      {state?.ok === false ? (
        <span className="w-full text-sm text-red-600">{state.error}</span>
      ) : null}
    </form>
  );
}

export function LevelForm({ curriculumId }: { curriculumId: string }) {
  const [state, action] = useActionState<FormResult | null, FormData>(
    createLevel,
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
      <input type="hidden" name="curriculum_id" value={curriculumId} />
      <label className="flex flex-col gap-1 text-sm">
        اسم المستوى
        <FieldInput feedback={state} name="name" required className="text-sm" />
      </label>
      <SubmitButton className="text-sm">أضف مستوى</SubmitButton>
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
  const [state, action] = useActionState<FormResult | null, FormData>(
    createCircle,
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
      <input type="hidden" name="level_id" value={levelId} />
      <input type="hidden" name="curriculum_id" value={curriculumId} />
      <label className="flex flex-col gap-1 text-sm">
        اسم الحلقة
        <FieldInput feedback={state} name="name" required className="text-sm" />
      </label>
      <label className="flex flex-col gap-1 text-sm">
        المعلّم
        <FieldSelect feedback={state} name="teacher_id" defaultValue="" className="text-sm">
          <option value="">— بدون معلّم —</option>
          {teachers.map((t) => (
            <option key={t.id} value={t.id}>
              {t.name}
            </option>
          ))}
        </FieldSelect>
      </label>
      <label className="flex flex-col gap-1 text-sm">
        الحد الأقصى
        <FieldInput feedback={state}
          name="max_size"
          type="number"
          min={1}
          defaultValue={30}
          className="w-24 text-sm"
        />
      </label>
      <SubmitButton className="text-sm">أضف حلقة</SubmitButton>
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
  const [state, action] = useActionState<FormResult | null, FormData>(
    updateCircle,
    null,
  );
  useActionFeedback(state);
  return (
    <form action={action} className="flex flex-wrap items-center gap-2">
      <input type="hidden" name="id" value={circle.id} />
      <input type="hidden" name="level_id" value={circle.level_id} />
      <input type="hidden" name="curriculum_id" value={curriculumId} />
      <FieldSelect feedback={state}
        name="teacher_id"
        defaultValue={circle.teacher_id ?? ""}
        className="py-1 text-sm"
      >
        <option value="">— بدون معلّم —</option>
        {teachers.map((t) => (
          <option key={t.id} value={t.id}>
            {t.name}
          </option>
        ))}
      </FieldSelect>
      <FieldSelect feedback={state}
        name="status"
        defaultValue={circle.status}
        className="py-1 text-sm"
      >
        <option value="forming">قيد التكوين</option>
        <option value="active">نشطة</option>
        <option value="graduated">متخرّجة</option>
      </FieldSelect>
      <FieldInput feedback={state}
        name="max_size"
        type="number"
        min={1}
        defaultValue={circle.max_size}
        className="w-20 py-1 text-sm"
      />
      <SubmitButton size="sm" variant="secondary">حفظ</SubmitButton>
      {state?.ok === false ? (
        <span className="text-xs text-red-600">{state.error}</span>
      ) : null}
    </form>
  );
}

