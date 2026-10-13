"use client";
import { SubmitButton } from "@/components/ui/button";import { FieldSelect, FieldInput, FieldTextarea } from "@/components/ui/fields";
import { useActionFeedback } from "@/components/ui/feedback";

import { useRouter } from "next/navigation";
import { useActionState } from "react";

import { DangerAction } from "@/components/danger-action";

import { deleteRow, writeJson, type FormResult } from "./actions";

export function TableSelect({
  tables,
  current,
}: {
  tables: string[];
  current: string;
}) {
  const router = useRouter();
  return (
    <FieldSelect
      aria-label="الجدول"
      value={current}
      onChange={(e) => router.push(`/data?table=${e.target.value}`)}
      className="max-w-xs text-sm"
    >
      {tables.map((t) => (
        <option key={t} value={t}>
          {t}
        </option>
      ))}
    </FieldSelect>
  );
}

export function DeleteRowButton({ table, id }: { table: string; id: string }) {
  return (
    <DangerAction
      action={deleteRow}
      label="حذف"
      title={`حذف صف من «${table}»`}
      description="⚠️ حذف صف مباشر من قاعدة البيانات — لا رجعة فيه."
      hidden={{ table, id }}
      submitLabel="احذف الصف"
    />
  );
}

export function WriteForm({ table }: { table: string }) {
  const [state, action] = useActionState<FormResult | null, FormData>(
    writeJson,
    null,
  );
  useActionFeedback(state);
  return (
    <form
      action={action}
      className="flex flex-col gap-3 rounded-xl border border-border bg-white p-4"
    >
      <input type="hidden" name="table" value={table} />
      <div className="flex flex-wrap items-end gap-3">
        <label className="flex flex-col gap-1 text-sm">
          العملية
          <FieldSelect feedback={state} name="op" defaultValue="insert" className="text-sm">
            <option value="insert">إضافة صف</option>
            <option value="update">تعديل صفوف</option>
            <option value="delete">حذف صفوف</option>
          </FieldSelect>
        </label>
        <label className="flex flex-1 flex-col gap-1 text-sm">
          السبب (مطلوب — للتدقيق)
          <FieldInput feedback={state} name="reason" required className="text-sm" />
        </label>
      </div>
      <label className="flex flex-col gap-1 text-sm">
        القيم (JSON) — مثال {`{"name":"...","status":"active"}`}
        <FieldTextarea feedback={state} name="payload" rows={3} className="font-mono text-xs" dir="ltr" />
      </label>
      <label className="flex flex-col gap-1 text-sm">
        الشرط للتعديل (JSON) — مثال {`{"id":"..."}`}
        <FieldTextarea feedback={state} name="match" rows={2} className="font-mono text-xs" dir="ltr" />
      </label>
      <SubmitButton className="self-start text-sm">نفّذ</SubmitButton>
      {state?.ok === false ? (
        <span className="text-sm text-red-600">{state.error}</span>
      ) : null}
      {state?.ok === true ? (
        <span className="text-sm text-primary">تمّ ✅</span>
      ) : null}
    </form>
  );
}
