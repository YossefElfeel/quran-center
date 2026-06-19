"use client";

import { useActionState } from "react";

// نتيجة موحّدة لكل server actions في اللوحة.
export type FormResult = { ok: true } | { ok: false; error: string };

type Action = (
  prev: FormResult | null,
  fd: FormData,
) => Promise<FormResult>;

// زر حذف عام مع تأكيد + عرض الخطأ inline.
export function DeleteButton({
  action,
  hidden,
  label,
  confirmMessage,
}: {
  action: Action;
  hidden: Record<string, string>;
  label: string;
  confirmMessage: string;
}) {
  const [state, formAction, pending] = useActionState<
    FormResult | null,
    FormData
  >(action, null);
  return (
    <form action={formAction} className="inline-flex items-center gap-2">
      {Object.entries(hidden).map(([k, v]) => (
        <input key={k} type="hidden" name={k} value={v} />
      ))}
      <button
        type="submit"
        disabled={pending}
        className="rounded-md border border-red-300 px-2 py-1 text-xs text-red-600 hover:bg-red-50 disabled:opacity-50"
        onClick={(e) => {
          if (!window.confirm(confirmMessage)) e.preventDefault();
        }}
      >
        {pending ? "…" : label}
      </button>
      {state?.ok === false ? (
        <span className="text-xs text-red-600">{state.error}</span>
      ) : null}
    </form>
  );
}
