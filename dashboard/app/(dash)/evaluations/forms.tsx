"use client";

import { useActionState } from "react";

import { setRatingHidden, type FormResult } from "./actions";

type Action = (prev: FormResult | null, fd: FormData) => Promise<FormResult>;

const btnSm =
  "rounded-md border border-border px-2 py-1 text-xs hover:bg-border/40 disabled:opacity-50";

export function ApproveButton({ action, id }: { action: Action; id: string }) {
  const [state, formAction, pending] = useActionState<
    FormResult | null,
    FormData
  >(action, null);
  return (
    <form action={formAction} className="inline-flex items-center gap-2">
      <input type="hidden" name="id" value={id} />
      <button
        disabled={pending}
        className="rounded-md border border-green-300 px-3 py-1 text-xs text-green-700 hover:bg-green-50 disabled:opacity-50"
      >
        {pending ? "…" : "اعتمد"}
      </button>
      {state?.ok === false ? (
        <span className="text-xs text-red-600">{state.error}</span>
      ) : null}
    </form>
  );
}

export function RatingToggle({ id, hidden }: { id: string; hidden: boolean }) {
  const [state, action, pending] = useActionState<FormResult | null, FormData>(
    setRatingHidden,
    null,
  );
  return (
    <form action={action} className="inline-flex items-center gap-2">
      <input type="hidden" name="id" value={id} />
      <input type="hidden" name="hidden" value={hidden ? "false" : "true"} />
      <button disabled={pending} className={btnSm}>
        {pending ? "…" : hidden ? "إظهار" : "إخفاء"}
      </button>
      {state?.ok === false ? (
        <span className="text-xs text-red-600">{state.error}</span>
      ) : null}
    </form>
  );
}
