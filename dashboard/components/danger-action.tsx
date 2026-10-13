"use client";
import { FieldTextarea, FieldInput } from "@/components/ui/fields";

import { useActionState, useEffect, useState } from "react";
import { Dialog } from "./ui/dialog";
import { toast } from "./ui/feedback";

// نتيجة موحّدة (نفس شكل FormResult/ActionResult في باقي اللوحة).
export type DangerResult = { ok: true } | { ok: false; error: string };

type DangerActionFn = (
  prev: DangerResult | null,
  fd: FormData,
) => Promise<DangerResult>;

// زر «إجراء خطر» موحّد: بيفتح Modal بيفرض سبب مكتوب (+ اختياريًا كلمة تأكيد لازم
// تتكتب بالظبط) قبل ما ينفّذ server action. بيقفل لوحده عند النجاح، وبيعرض الخطأ
// inline عند الفشل. ده الغلاف القياسي لكل العمليات المدمّرة في اللوحة.
export function DangerAction({
  action,
  label,
  title,
  description,
  confirmWord,
  requireReason = true,
  reasonPlaceholder = "السبب (مطلوب — للتدقيق)",
  submitLabel,
  tone = "danger",
  hidden = {},
  triggerClassName,
  onDone,
  children,
}: {
  action: DangerActionFn;
  label: string;
  title: string;
  description?: string;
  confirmWord?: string;
  requireReason?: boolean;
  reasonPlaceholder?: string;
  submitLabel?: string;
  tone?: "danger" | "warn";
  hidden?: Record<string, string>;
  triggerClassName?: string;
  onDone?: () => void;
  children?: React.ReactNode;
}) {
  const [open, setOpen] = useState(false);
  const trigger =
    triggerClassName ??
    (tone === "danger"
      ? "rounded-md border border-red-300 px-2 py-1 text-xs text-red-600 transition-colors hover:bg-red-50 disabled:opacity-50"
      : "rounded-md border border-amber-300 px-2 py-1 text-xs text-amber-700 transition-colors hover:bg-amber-50 disabled:opacity-50");

  return (
    <>
      <button type="button" className={trigger} onClick={() => setOpen(true)}>
        {label}
      </button>
      {open ? (
        <DangerModal title={title} tone={tone} onClose={() => setOpen(false)}>
          <DangerForm
            action={action}
            description={description}
            confirmWord={confirmWord}
            requireReason={requireReason}
            reasonPlaceholder={reasonPlaceholder}
            submitLabel={submitLabel ?? label}
            tone={tone}
            hidden={hidden}
            onDone={() => {
              setOpen(false);
              onDone?.();
            }}
          >
            {children}
          </DangerForm>
        </DangerModal>
      ) : null}
    </>
  );
}

function DangerModal({title,onClose,children}: {title:string;tone:'danger'|'warn';onClose:()=>void;children:React.ReactNode}) {
  return <Dialog title={title} onClose={onClose}><div className="flex flex-col gap-3">{children}</div></Dialog>;
}

function DangerForm({
  action,
  description,
  confirmWord,
  requireReason,
  reasonPlaceholder,
  submitLabel,
  tone,
  hidden,
  onDone,
  children,
}: {
  action: DangerActionFn;
  description?: string;
  confirmWord?: string;
  requireReason: boolean;
  reasonPlaceholder: string;
  submitLabel: string;
  tone: "danger" | "warn";
  hidden: Record<string, string>;
  onDone: () => void;
  children?: React.ReactNode;
}) {
  const [state, formAction, pending] = useActionState<
    DangerResult | null,
    FormData
  >(action, null);
  const [reason, setReason] = useState("");
  const [confirm, setConfirm] = useState("");

  useEffect(() => {
    if (state?.ok) { toast("تم التنفيذ"); onDone(); }
  }, [state, onDone]);

  const reasonOk = !requireReason || reason.trim().length > 0;
  const confirmOk = !confirmWord || confirm.trim() === confirmWord;
  const submit =
    tone === "danger"
      ? "self-start rounded-lg bg-red-600 px-4 py-2 text-sm font-bold text-white transition-opacity hover:opacity-90 disabled:opacity-50"
      : "self-start rounded-lg bg-amber-600 px-4 py-2 text-sm font-bold text-white transition-opacity hover:opacity-90 disabled:opacity-50";

  return (
    <form action={formAction} className="flex flex-col gap-3">
      {Object.entries(hidden).map(([k, v]) => (
        <input key={k} type="hidden" name={k} value={v} />
      ))}
      {description ? (
        <p
          className={`rounded-lg p-2 text-xs ${
            tone === "danger"
              ? "bg-red-50 text-red-700"
              : "bg-amber-50 text-amber-700"
          }`}
        >
          {description}
        </p>
      ) : null}
      {children}
      {requireReason ? (
        <FieldTextarea feedback={state}
          name="reason"
          required
          rows={2}
          value={reason}
          onChange={(e) => setReason(e.target.value)}
          placeholder={reasonPlaceholder}
          className="rounded-lg border border-border px-3 py-2 text-sm outline-none focus:border-primary"
        />
      ) : null}
      {confirmWord ? (
        <FieldInput feedback={state}
          name="confirm"
          value={confirm}
          onChange={(e) => setConfirm(e.target.value)}
          placeholder={confirmWord}
          autoComplete="off"
          dir="auto"
          className="rounded-lg border border-border px-3 py-2 text-sm outline-none focus:border-red-400"
        />
      ) : null}
      <button
        type="submit"
        disabled={pending || !reasonOk || !confirmOk}
        className={submit}
      >
        {pending ? "…" : submitLabel}
      </button>
      {state?.ok === false ? (
        <p className="text-sm text-red-600">{state.error}</p>
      ) : null}
    </form>
  );
}
