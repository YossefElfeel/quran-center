"use client";
import { Button } from "@/components/ui/button";
import { useActionFeedback } from "@/components/ui/feedback";

import { useActionState } from "react";

import { decideExcuse, type FormResult } from "./actions";

export function ExcuseDecision({
  id,
  enrollmentId,
  sessionId,
}: {
  id: string;
  enrollmentId: string;
  sessionId: string;
}) {
  const [state, action, pending] = useActionState<FormResult | null, FormData>(
    decideExcuse,
    null,
  );
  useActionFeedback(state);
  return (
    <form action={action} className="flex items-center gap-2">
      <input type="hidden" name="id" value={id} />
      <input type="hidden" name="enrollment_id" value={enrollmentId} />
      <input type="hidden" name="session_id" value={sessionId} />
      <Button
        type="submit"
        size="sm"
        variant="secondary"
        name="decision"
        value="approved"
        disabled={pending}
        aria-busy={pending}
        className="border-green-300 text-green-700 hover:bg-green-50"
      >
        قبول
      </Button>
      <Button
        type="submit"
        size="sm"
        variant="secondary"
        name="decision"
        value="rejected"
        disabled={pending}
        aria-busy={pending}
        className="border-red-300 text-red-600 hover:bg-red-50"
      >
        رفض
      </Button>
      {state?.ok === false ? (
        <span className="text-xs text-red-600">{state.error}</span>
      ) : null}
    </form>
  );
}
