"use client";

import { useActionState } from "react";

import { setMediaRetained, type FormResult } from "./actions";

export { DeleteButton } from "@/components/admin-controls";

const btnSm =
  "rounded-md border border-border px-2 py-1 text-xs hover:bg-border/40 disabled:opacity-50";

export function RetainToggle({
  id,
  retained,
}: {
  id: string;
  retained: boolean;
}) {
  const [state, action, pending] = useActionState<FormResult | null, FormData>(
    setMediaRetained,
    null,
  );
  return (
    <form action={action} className="inline-flex items-center gap-2">
      <input type="hidden" name="id" value={id} />
      <input type="hidden" name="retained" value={retained ? "false" : "true"} />
      <button disabled={pending} className={btnSm}>
        {pending ? "…" : retained ? "حذف ناعم" : "استرجاع"}
      </button>
      {state?.ok === false ? (
        <span className="text-xs text-red-600">{state.error}</span>
      ) : null}
    </form>
  );
}
