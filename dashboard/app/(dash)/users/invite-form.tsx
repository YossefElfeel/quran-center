"use client";
import { Button } from "@/components/ui/button";
import { FieldInput, FieldSelect } from "@/components/ui/fields";
import { useActionFeedback } from "@/components/ui/feedback";

import { useActionState } from "react";

import { inviteUser, type InviteResult } from "./actions";

const ROLES = [
  { value: "teacher", label: "معلّم" },
  { value: "supervisor", label: "مشرف" },
  { value: "admin", label: "أدمن" },
];

export function InviteForm() {
  const [state, formAction, pending] = useActionState<
    InviteResult | null,
    FormData
  >(inviteUser, null);
  useActionFeedback(state);

  return (
    <form
      action={formAction}
      className="flex max-w-md flex-col gap-3 rounded-xl border border-border bg-white p-5"
    >
      <label className="flex flex-col gap-1 text-sm">
        الاسم
        <FieldInput feedback={state}
          name="full_name"
          required
        />
      </label>
      <label className="flex flex-col gap-1 text-sm">
        الإيميل
        <FieldInput feedback={state}
          name="email"
          type="email"
          required
        />
      </label>
      <label className="flex flex-col gap-1 text-sm">
        الدور
        <FieldSelect feedback={state}
          name="role"
          required
          defaultValue="teacher"
        >
          {ROLES.map((r) => (
            <option key={r.value} value={r.value}>
              {r.label}
            </option>
          ))}
        </FieldSelect>
      </label>

      <p className="text-sm text-foreground/60">لأولياء الأمور استخدم «إضافة ولي أمر» من بطاقة الطالب في التطبيق، عشان تربط الأسرة والطفل.</p>
      <Button
        type="submit"
        disabled={pending}
        aria-busy={pending}
        className="self-start"
      >
        {pending ? "جاري إنشاء الرابط…" : "إنشاء رابط دعوة"}
      </Button>

      {state?.ok === false ? (
        <p role="alert" className="text-sm text-red-600">{state.error}</p>
      ) : null}
      {state?.ok === true ? (
        <div className="flex flex-col gap-1 rounded-lg bg-primary/10 p-3 text-sm">
          <span className="font-bold text-primary">
            رابط الدعوة اتعمل — الإيميل لم يُرسل تلقائيًا. شارك الرابط مع المستخدم:
          </span>
          <code className="break-all text-xs text-foreground/70">
            {state.actionLink ?? "(مفيش لينك)"}
          </code>
        </div>
      ) : null}
    </form>
  );
}
