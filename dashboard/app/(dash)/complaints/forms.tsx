"use client";
import { FieldTextarea, FieldSelect } from "@/components/ui/fields";
import { useActionState, useEffect } from "react";
import { SubmitButton } from "@/components/ui/button";
import { toast } from "@/components/ui/feedback";
import { respondToComplaint } from "./actions";
export function ComplaintResponseForm({ id, response, status }: { id: string; response: string | null; status: string }) {
  const [result, action] = useActionState(respondToComplaint, null);
  useEffect(() => { if (result?.ok) toast("الشكوى اتحدّثت"); }, [result]);
  return <form action={action} className="space-y-3 border-t border-border pt-3"><input type="hidden" name="id" value={id} />
    <label className="block">رد الإدارة<FieldTextarea feedback={result} name="response" rows={3} defaultValue={response ?? ""} maxLength={4000} className="mt-1 w-full rounded-lg border border-border p-3" /></label>
    <label className="block">الحالة<FieldSelect feedback={result} name="status" defaultValue={status === "reopened" ? "open" : status} className="ms-3 rounded-lg border border-border p-2"><option value="open">مفتوحة</option><option value="answered">اترد عليها</option><option value="closed">مقفولة</option></FieldSelect></label>
    {result?.ok === false && <p role="alert" className="text-red-700">{result.error}</p>}<SubmitButton>حفظ الرد والحالة</SubmitButton>
  </form>;
}
