"use client";
import { FieldInput, FieldTextarea } from "@/components/ui/fields";
import { useActionState, useEffect } from "react";
import { SubmitButton } from "@/components/ui/button";
import { toast } from "@/components/ui/feedback";
import { updateSettings } from "./actions";
import { SETTINGS } from "./meta";
export function SettingsForm({ values }: { values: Record<string, string | number> }) {
  const [state, action] = useActionState(updateSettings, null);
  useEffect(() => { if (state?.ok) toast("الإعدادات اتحفظت"); }, [state]);
  return <form action={action} className="space-y-4">{SETTINGS.map((s) => <label key={s.key} className="block space-y-1"><span>{s.label}</span><FieldInput feedback={state} name={s.key} type="number" min={s.min} max={s.max} defaultValue={Number(values[s.key] ?? s.min)} required className="w-full rounded-lg border border-border bg-white p-3" /></label>)}
    {[['center_name','اسم الدار'],['center_phone','رقم الإدارة (بكود الدولة)'],['center_address','عنوان الدار']].map(([key,label]) => <label key={key} className="block space-y-1"><span>{label}</span><FieldInput feedback={state} name={key} type={key === 'center_phone' ? 'tel' : 'text'} defaultValue={String(values[key] ?? (key === 'center_name' ? 'دار تحفيظ القرآن' : ''))} required={key === 'center_name'} className="w-full rounded-lg border border-border bg-white p-3" /></label>)}
    <label className="block space-y-1"><span>سبب التغيير (للتدقيق)</span><FieldTextarea feedback={state} name="reason" required className="w-full rounded-lg border border-border bg-white p-3" /></label>
    {state?.ok === false && <p role="alert" className="text-red-700">{state.error}</p>}<SubmitButton>حفظ الإعدادات</SubmitButton>
  </form>;
}
