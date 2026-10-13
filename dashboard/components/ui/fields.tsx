"use client";
import { useId, useState } from "react";

type FormFeedback = { ok: boolean; fieldErrors?: Record<string, string[] | undefined> } | null;
const fieldNames: Record<string,string> = {
  name: 'الاسم', full_name: 'الاسم الكامل', email: 'الإيميل', role: 'الدور',
  type: 'النوع', gender: 'النوع', curriculum_id: 'المنهج', level_id: 'المستوى',
  result_level_id: 'المستوى بعد الاختبار', circle_id: 'الحلقة', teacher_id: 'المعلّم',
  student_person_id: 'الطالب', person_id: 'الشخص', max_size: 'الحد الأقصى',
  monthly_amount: 'الاشتراك الشهري', amount: 'المبلغ', period_month: 'الشهر',
  method: 'طريقة الدفع', status: 'الحالة', state: 'حالة الحفظ', visibility: 'ظهور الملاحظة',
  text: 'الملاحظة', notes: 'ملاحظات', rows: 'أسماء الطلاب', national_id: 'الرقم القومي',
  reason: 'السبب', confirm: 'اكتب الاسم الكامل للتأكيد', subject_person_id: 'المستخدم',
  audience: 'الجمهور', title: 'العنوان', body: 'الرسالة', response: 'الرد',
  kind: 'نوع الشهادة', op: 'العملية', payload: 'قيم JSON', match: 'شرط JSON',
  center_name: 'اسم الدار', center_phone: 'رقم الإدارة', center_address: 'عنوان الدار',
};
function fieldFeedback(feedback: FormFeedback | undefined, name: string | undefined) {
  return name && feedback?.ok === false ? feedback.fieldErrors?.[name]?.[0] : undefined;
}
function useFieldValue<T>(initial:T, feedback:FormFeedback|undefined):[T,(value:T)=>void] {
  const [draft,setDraft]=useState({value:initial,result:feedback,initial});
  // React form actions reset uncontrolled fields even when the action returns an error.
  // Keep the edited value on failure; derive the reset from a new successful result.
  const reset=initial!==draft.initial||(feedback!==draft.result&&feedback?.ok===true);
  return [reset?initial:draft.value,value=>setDraft({value,result:feedback,initial})];
}
export function FieldInput({feedback,...props}:React.InputHTMLAttributes<HTMLInputElement>&{feedback?:FormFeedback}) {
  const id=useId(), error=fieldFeedback(feedback,props.name);
  const [value,setValue]=useFieldValue(String(props.defaultValue??''),feedback);
  const textual=!['checkbox','radio','file'].includes(props.type??'text');
  return <><input {...props} value={textual?(props.value??value):props.value} defaultValue={textual?undefined:props.defaultValue} onChange={event=>{setValue(event.target.value);props.onChange?.(event)}} type={props.type==='number'?'text':props.type} inputMode={props.inputMode??(props.type==='number'?'decimal':undefined)} pattern={props.pattern??(props.type==='number'?'[0-9٠-٩۰-۹]+([.٫][0-9٠-٩۰-۹]+)?':undefined)} aria-label={props['aria-label']??fieldNames[props.name??'']} aria-invalid={!!error} aria-describedby={error?`${id}-error`:props['aria-describedby']} className={`${style} ${props.className??''}`}/>{error&&<span id={`${id}-error`} role="alert" className="block text-sm text-red-700">{error}</span>}</>;
}
export function FieldSelect({feedback,...props}:React.SelectHTMLAttributes<HTMLSelectElement>&{feedback?:FormFeedback}) {
  const id=useId(), error=fieldFeedback(feedback,props.name);
  const [value,setValue]=useFieldValue<React.SelectHTMLAttributes<HTMLSelectElement>['value']>(props.defaultValue??'',feedback);
  return <><select {...props} value={props.value??value} defaultValue={undefined} onChange={event=>{setValue(props.multiple?Array.from(event.target.selectedOptions).map(option=>option.value):event.target.value);props.onChange?.(event)}} aria-label={props['aria-label']??fieldNames[props.name??'']} aria-invalid={!!error} aria-describedby={error?`${id}-error`:props['aria-describedby']} className={`${style} ${props.className??''}`}/>{error&&<span id={`${id}-error`} role="alert" className="block text-sm text-red-700">{error}</span>}</>;
}
export function FieldTextarea({feedback,...props}:React.TextareaHTMLAttributes<HTMLTextAreaElement>&{feedback?:FormFeedback}) {
  const id=useId(), error=fieldFeedback(feedback,props.name);
  const [value,setValue]=useFieldValue(String(props.defaultValue??''),feedback);
  return <><textarea {...props} value={props.value??value} defaultValue={undefined} onChange={event=>{setValue(event.target.value);props.onChange?.(event)}} aria-label={props['aria-label']??fieldNames[props.name??'']} aria-invalid={!!error} aria-describedby={error?`${id}-error`:props['aria-describedby']} className={`${style} ${props.className??''}`}/>{error&&<span id={`${id}-error`} role="alert" className="block text-sm text-red-700">{error}</span>}</>;
}

type FieldProps={label:string;error?:string;className?:string};
const style="min-h-11 w-full rounded-lg border border-border bg-white px-3 py-2 outline-none focus:border-primary";
export function Input({label,error,className,...props}:FieldProps&React.InputHTMLAttributes<HTMLInputElement>){const id=useId();return <div className={className}><label htmlFor={id} className="mb-1 block text-sm">{label}</label><input {...props} id={id} className={style} aria-invalid={!!error} aria-describedby={error?`${id}-error`:undefined}/>{error?<p id={`${id}-error`} role="alert" className="mt-1 text-sm text-red-700">{error}</p>:null}</div>;}
export function Select({label,error,className,children,...props}:FieldProps&React.SelectHTMLAttributes<HTMLSelectElement>){const id=useId();return <div className={className}><label htmlFor={id} className="mb-1 block text-sm">{label}</label><select {...props} id={id} className={style} aria-invalid={!!error} aria-describedby={error?`${id}-error`:undefined}>{children}</select>{error?<p id={`${id}-error`} role="alert" className="mt-1 text-sm text-red-700">{error}</p>:null}</div>;}
export function Textarea({label,error,className,...props}:FieldProps&React.TextareaHTMLAttributes<HTMLTextAreaElement>){const id=useId();return <div className={className}><label htmlFor={id} className="mb-1 block text-sm">{label}</label><textarea {...props} id={id} className={style} aria-invalid={!!error} aria-describedby={error?`${id}-error`:undefined}/>{error?<p id={`${id}-error`} role="alert" className="mt-1 text-sm text-red-700">{error}</p>:null}</div>;}
