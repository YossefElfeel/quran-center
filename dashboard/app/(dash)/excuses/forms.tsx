"use client";

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
  return (
    <form action={action} className="flex items-center gap-2">
      <input type="hidden" name="id" value={id} />
      <input type="hidden" name="enrollment_id" value={enrollmentId} />
      <input type="hidden" name="session_id" value={sessionId} />
      <button
        name="decision"
        value="approved"
        disabled={pending}
        className="rounded-md border border-green-300 px-3 py-1 text-xs text-green-700 hover:bg-green-50 disabled:opacity-50"
      >
        قبول
      </button>
      <button
        name="decision"
        value="rejected"
        disabled={pending}
        className="rounded-md border border-red-300 px-3 py-1 text-xs text-red-600 hover:bg-red-50 disabled:opacity-50"
      >
        رفض
      </button>
      {state?.ok === false ? (
        <span className="text-xs text-red-600">{state.error}</span>
      ) : null}
    </form>
  );
}
