"use client";

import { useActionState } from "react";

import { inviteUser, type InviteResult } from "./actions";

const ROLES = [
  { value: "teacher", label: "معلّم" },
  { value: "supervisor", label: "مشرف" },
  { value: "admin", label: "أدمن" },
  { value: "parent", label: "ولي أمر" },
];

export function InviteForm() {
  const [state, formAction, pending] = useActionState<
    InviteResult | null,
    FormData
  >(inviteUser, null);

  return (
    <form
      action={formAction}
      className="flex max-w-md flex-col gap-3 rounded-xl border border-border bg-white p-5"
    >
      <label className="flex flex-col gap-1 text-sm">
        الاسم
        <input
          name="full_name"
          required
          className="rounded-lg border border-border px-3 py-2 outline-none focus:border-primary"
        />
      </label>
      <label className="flex flex-col gap-1 text-sm">
        الإيميل
        <input
          name="email"
          type="email"
          required
          className="rounded-lg border border-border px-3 py-2 outline-none focus:border-primary"
        />
      </label>
      <label className="flex flex-col gap-1 text-sm">
        الدور
        <select
          name="role"
          required
          defaultValue="teacher"
          className="rounded-lg border border-border bg-white px-3 py-2 outline-none focus:border-primary"
        >
          {ROLES.map((r) => (
            <option key={r.value} value={r.value}>
              {r.label}
            </option>
          ))}
        </select>
      </label>

      <button
        type="submit"
        disabled={pending}
        className="self-start rounded-lg bg-primary px-4 py-2 font-bold text-white transition-opacity hover:opacity-90 disabled:opacity-60"
      >
        {pending ? "بنبعت…" : "ابعت الدعوة"}
      </button>

      {state?.ok === false ? (
        <p className="text-sm text-red-600">{state.error}</p>
      ) : null}
      {state?.ok === true ? (
        <div className="flex flex-col gap-1 rounded-lg bg-primary/10 p-3 text-sm">
          <span className="font-bold text-primary">
            الدعوة اتعملت ✅ — ابعت اللينك ده للمستخدم:
          </span>
          <code className="break-all text-xs text-foreground/70">
            {state.actionLink ?? "(مفيش لينك)"}
          </code>
        </div>
      ) : null}
    </form>
  );
}
