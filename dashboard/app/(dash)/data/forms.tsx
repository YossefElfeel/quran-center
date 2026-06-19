"use client";

import { useRouter } from "next/navigation";
import { useActionState, useTransition } from "react";

import { deleteRow, writeJson, type FormResult } from "./actions";

const input =
  "rounded-lg border border-border px-3 py-2 text-sm outline-none focus:border-primary";
const mono =
  "rounded-lg border border-border px-3 py-2 font-mono text-xs outline-none focus:border-primary";
const btn =
  "rounded-lg bg-primary px-4 py-2 text-sm font-bold text-white transition-opacity hover:opacity-90 disabled:opacity-60";
const btnDanger =
  "rounded-md border border-red-300 px-2 py-1 text-xs text-red-600 hover:bg-red-50 disabled:opacity-50";

export function TableSelect({
  tables,
  current,
}: {
  tables: string[];
  current: string;
}) {
  const router = useRouter();
  return (
    <select
      value={current}
      onChange={(e) => router.push(`/data?table=${e.target.value}`)}
      className={input}
    >
      {tables.map((t) => (
        <option key={t} value={t}>
          {t}
        </option>
      ))}
    </select>
  );
}

export function DeleteRowButton({ table, id }: { table: string; id: string }) {
  const [pending, start] = useTransition();
  return (
    <button
      disabled={pending}
      className={btnDanger}
      onClick={() => {
        const reason = window.prompt(`حذف صف من «${table}»؟ اكتب السبب:`);
        if (!reason) return;
        const fd = new FormData();
        fd.set("table", table);
        fd.set("id", id);
        fd.set("reason", reason);
        start(async () => {
          const r = await deleteRow(null, fd);
          if (!r.ok) window.alert(r.error);
        });
      }}
    >
      {pending ? "…" : "حذف"}
    </button>
  );
}

export function WriteForm({ table }: { table: string }) {
  const [state, action, pending] = useActionState<FormResult | null, FormData>(
    writeJson,
    null,
  );
  return (
    <form
      action={action}
      className="flex flex-col gap-3 rounded-xl border border-border bg-white p-4"
    >
      <input type="hidden" name="table" value={table} />
      <div className="flex flex-wrap items-end gap-3">
        <label className="flex flex-col gap-1 text-sm">
          العملية
          <select name="op" defaultValue="insert" className={input}>
            <option value="insert">إضافة صف</option>
            <option value="update">تعديل صفوف</option>
            <option value="delete">حذف صفوف</option>
          </select>
        </label>
        <label className="flex flex-1 flex-col gap-1 text-sm">
          السبب (مطلوب — للتدقيق)
          <input name="reason" required className={input} />
        </label>
      </div>
      <label className="flex flex-col gap-1 text-sm">
        القيم (JSON) — مثال {`{"name":"...","status":"active"}`}
        <textarea name="payload" rows={3} className={mono} dir="ltr" />
      </label>
      <label className="flex flex-col gap-1 text-sm">
        الشرط للتعديل (JSON) — مثال {`{"id":"..."}`}
        <textarea name="match" rows={2} className={mono} dir="ltr" />
      </label>
      <button className={`${btn} self-start`} disabled={pending}>
        {pending ? "…" : "نفّذ"}
      </button>
      {state?.ok === false ? (
        <span className="text-sm text-red-600">{state.error}</span>
      ) : null}
      {state?.ok === true ? (
        <span className="text-sm text-primary">تمّ ✅</span>
      ) : null}
    </form>
  );
}
