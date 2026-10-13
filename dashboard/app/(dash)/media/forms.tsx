"use client";
import { SubmitButton } from "@/components/ui/button";
import { useActionFeedback } from "@/components/ui/feedback";

import { useActionState } from "react";

import { setMediaRetained, type FormResult } from "./actions";

export { DeleteButton } from "@/components/admin-controls";

export function RetainToggle({
  id,
  retained,
}: {
  id: string;
  retained: boolean;
}) {
  const [state, action] = useActionState<FormResult | null, FormData>(
    setMediaRetained,
    null,
  );
  useActionFeedback(state);
  return (
    <form action={action} className="inline-flex items-center gap-2">
      <input type="hidden" name="id" value={id} />
      <input type="hidden" name="retained" value={retained ? "false" : "true"} />
      <SubmitButton size="sm" variant="secondary">{retained ? "حذف ناعم" : "استرجاع"}</SubmitButton>
      {state?.ok === false ? (
        <span className="text-xs text-red-600">{state.error}</span>
      ) : null}
    </form>
  );
}
