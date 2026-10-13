"use client";
import { FieldInput, FieldSelect, FieldTextarea } from "@/components/ui/fields";
import { useActionFeedback } from "@/components/ui/feedback";
import { DangerAction } from "@/components/danger-action";
import { Input,Textarea } from "@/components/ui/fields";
import { Button, SubmitButton } from "@/components/ui/button";
import { toast } from "@/components/ui/feedback";

import { useActionState, useEffect, useRef } from "react";

import {
  addCourse,
  updateCourse,
  createCompetition,
  updateCompetition,
  setApplicationStatus,
  setCompetitionStatus,
  type FormResult,
} from "./actions";

export { DeleteButton } from "@/components/admin-controls";

const COMP_STATUS = [
  { value: "draft", label: "مسودّة" },
  { value: "open", label: "مفتوحة" },
  { value: "judging", label: "تحكيم" },
  { value: "closed", label: "مقفولة" },
];

export function CourseForm({course}: {course?: {id:string;title:string;description:string|null;video_url:string}}) {
 const [state,action,pending]=useActionState<FormResult|null,FormData>(course?updateCourse:addCourse,null);const ref=useRef<HTMLFormElement>(null);
 useEffect(()=>{if(state?.ok){if(!course)ref.current?.reset();toast(course?'تعديل الكورس اتحفظ':'الكورس اتضاف');}},[state,course]);
 const fields=state?.ok===false?state.fieldErrors:undefined;
 return <form ref={ref} action={action} className="flex flex-wrap items-end gap-4 rounded-xl border border-border bg-white p-4">
  {course?<input type="hidden" name="id" value={course.id}/>:null}
  <Input label="عنوان الكورس" name="title" required maxLength={200} defaultValue={course?.title} error={fields?.title?.[0]}/>
  <Input label="رابط الفيديو" name="video_url" type="url" required defaultValue={course?.video_url} dir="ltr" error={fields?.video_url?.[0]} className="flex-1"/>
  <Textarea label="الوصف" name="description" maxLength={5000} defaultValue={course?.description??''} error={fields?.description?.[0]} className="w-full"/>
  <Button type="submit" disabled={pending}>{pending?'جاري الحفظ…':course?'حفظ التعديل':'أضف كورس'}</Button>
  {state?.ok===false?<p role="alert" className="w-full text-sm text-red-700">{state.error}</p>:null}
 </form>;
}
export function CompetitionForm(){
 const [state,action,pending]=useActionState<FormResult|null,FormData>(createCompetition,null);const ref=useRef<HTMLFormElement>(null);
 useEffect(()=>{if(state?.ok){ref.current?.reset();toast('المسابقة اتضافت كمسودّة');}},[state]);
 const fields=state?.ok===false?state.fieldErrors:undefined;
 return <form ref={ref} action={action} className="flex flex-wrap items-end gap-4 rounded-xl border border-border bg-white p-4">
  <Input label="اسم المسابقة" name="name" required maxLength={200} error={fields?.name?.[0]}/>
  <Input label="السنة" name="year" inputMode="numeric" error={fields?.year?.[0]} className="w-28"/>
  <Textarea label="الشروط" name="rules" maxLength={10000} error={fields?.rules?.[0]} className="w-full"/>
  <Input label="الجائزة" name="prize" maxLength={2000} error={fields?.prize?.[0]}/>
  <Input label="آخر موعد — بتوقيت القاهرة" name="deadline" type="datetime-local" error={fields?.deadline?.[0]}/>
  <Button type="submit" disabled={pending}>{pending?'جاري الحفظ…':'أضف مسابقة'}</Button>
  {state?.ok===false?<p role="alert" className="w-full text-sm text-red-700">{state.error}</p>:null}
 </form>;
}

export type CompetitionDetails = { id: string; name: string; rules: string | null; prize: string | null; deadlineLocal: string };
export function CompetitionEditForm({ competition }: { competition: CompetitionDetails }) {
  const [state, action, pending] = useActionState<FormResult | null, FormData>(updateCompetition, null);
  useActionFeedback(state, "تعديل المسابقة اتحفظ");
  return (
    <form action={action} className="flex flex-wrap items-end gap-4 rounded-xl border border-border bg-white p-4">
      <input type="hidden" name="id" value={competition.id} />
      <label className="flex flex-col gap-1 text-sm">
        اسم المسابقة
        <FieldInput feedback={state} name="name" aria-label="اسم المسابقة" required maxLength={200} defaultValue={competition.name} />
      </label>
      <label className="flex flex-col gap-1 text-sm">
        الجائزة
        <FieldInput feedback={state} name="prize" maxLength={2000} defaultValue={competition.prize ?? ""} />
      </label>
      <label className="flex flex-col gap-1 text-sm">
        آخر موعد — بتوقيت القاهرة
        <FieldInput feedback={state} name="deadline" type="datetime-local" defaultValue={competition.deadlineLocal} />
      </label>
      <label className="flex w-full flex-col gap-1 text-sm">
        الشروط
        <FieldTextarea feedback={state} name="rules" rows={4} maxLength={10000} defaultValue={competition.rules ?? ""} />
      </label>
      <Button type="submit" disabled={pending} aria-busy={pending}>{pending ? "جاري الحفظ…" : "حفظ التعديل"}</Button>
      {state?.ok === false ? <p role="alert" className="w-full text-sm text-red-700">{state.error}</p> : null}
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
  const [state, action] = useActionState<FormResult | null, FormData>(
    setCompetitionStatus,
    null,
  );
  useActionFeedback(state);
  return (
    <form action={action} className="flex items-center gap-2">
      <input type="hidden" name="id" value={id} />
      <FieldSelect feedback={state} name="status" defaultValue={current} className="py-1 text-sm">
        {COMP_STATUS.map((s) => (
          <option key={s.value} value={s.value}>
            {s.label}
          </option>
        ))}
      </FieldSelect>
      <SubmitButton size="sm" variant="secondary">حفظ</SubmitButton>
      {state?.ok === false ? (
        <span className="text-xs text-red-600">{state.error}</span>
      ) : null}
    </form>
  );
}

export function ApplicationDecision({id,competitionId}: {id:string;competitionId:string}) {
  const [state,action,pending]=useActionState(setApplicationStatus,null);
  useActionFeedback(state);
  return <div className="flex flex-wrap gap-2"><form action={action}><input type="hidden" name="id" value={id}/><input type="hidden" name="competition_id" value={competitionId}/><Button size="sm" variant="secondary" name="status" value="accepted" disabled={pending} aria-busy={pending}>قبول</Button></form>
    <DangerAction action={setApplicationStatus} hidden={{id,competition_id:competitionId,status:'rejected'}} label="رفض" title="رفض طلب المسابقة؟" description="راجع بيانات المتقدّم قبل الرفض." requireReason={false}/>
    {state?.ok===false&&<span role="alert" className="text-red-700">{state.error}</span>}
  </div>;
}
