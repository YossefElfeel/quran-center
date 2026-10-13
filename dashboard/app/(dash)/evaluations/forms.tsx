"use client";
import { useActionFeedback } from "@/components/ui/feedback";
import { DangerAction } from "@/components/danger-action";

import { useActionState } from "react";

import { returnEvaluation, setRatingHidden, type FormResult } from "./actions";

type Action = (prev: FormResult | null, fd: FormData) => Promise<FormResult>;

const btnSm =
  "rounded-md border border-border px-2 py-1 text-xs hover:bg-border/40 disabled:opacity-50";

export function ApproveButton({action,id}: {action:Action;id:string}) {
  return <DangerAction action={action} hidden={{id}} label="اعتماد" title="اعتماد التقييم؟" requireReason={false} tone="warn"/>;
}
export function ReturnButton({id,table}: {id:string;table:'teacher_development'|'monthly_student_evaluation'}) {
  return <DangerAction action={returnEvaluation} hidden={{id,table}} label="رجّعه للمعلّم" title="إرجاع التقييم للتعديل" requireReason={true} tone="warn"/>;
}

export function RatingToggle({ id, hidden }: { id: string; hidden: boolean }) {
  const [state, action, pending] = useActionState<FormResult | null, FormData>(
    setRatingHidden,
    null,
  );
  useActionFeedback(state);
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
