"use client";

import { useActionState, useEffect, useState } from "react";

import { DangerAction } from "@/components/danger-action";

import {
  blockUser,
  deleteUser,
  forceLogout,
  manageRole,
  resetPassword,
  type ActionResult,
  type ResetResult,
} from "./actions";

const ALL_ROLES: { value: string; label: string }[] = [
  { value: "super_admin", label: "سوبر أدمن" },
  { value: "admin", label: "أدمن" },
  { value: "supervisor", label: "مشرف" },
  { value: "teacher", label: "معلّم" },
  { value: "parent", label: "ولي أمر" },
];

type Status = "active" | "blocked" | "deactivated";

type AdminAction = (
  prev: ActionResult | null,
  fd: FormData,
) => Promise<ActionResult>;

const btn =
  "rounded-md border border-border px-2 py-1 text-xs transition-colors hover:bg-border/40 disabled:opacity-50";
const btnDanger =
  "rounded-md border border-red-300 px-2 py-1 text-xs text-red-600 transition-colors hover:bg-red-50 disabled:opacity-50";

export function UserActions({
  personId,
  fullName,
  status,
  roles,
  isSelf,
}: {
  personId: string;
  fullName: string;
  status: Status;
  roles: string[];
  isSelf: boolean;
}) {
  const [open, setOpen] = useState<
    null | "block" | "deactivate" | "delete" | "roles"
  >(null);
  const close = () => setOpen(null);

  return (
    <div className="flex flex-wrap items-center justify-end gap-1">
      <button className={btn} onClick={() => setOpen("roles")}>
        الأدوار
      </button>

      {!isSelf && status === "active" ? (
        <>
          <button className={btn} onClick={() => setOpen("block")}>
            حظر
          </button>
          <button className={btn} onClick={() => setOpen("deactivate")}>
            إيقاف
          </button>
          <ResetPasswordButton personId={personId} fullName={fullName} />
          <DangerAction
            action={forceLogout}
            tone="warn"
            label="خروج"
            title={`تسجيل خروج «${fullName}»`}
            description="هيتم إنهاء كل جلسات المستخدم — هيحتاج يسجّل دخول تاني."
            submitLabel="سجّل خروجه"
            reasonPlaceholder="سبب تسجيل الخروج (مطلوب)"
            hidden={{ target_person_id: personId }}
          />
        </>
      ) : null}

      {!isSelf && status === "blocked" ? (
        <UnblockForm personId={personId} />
      ) : null}

      {!isSelf && status === "deactivated" ? (
        <RestoreForm personId={personId} />
      ) : null}

      {isSelf ? (
        <span className="text-xs text-foreground/40">(أنت)</span>
      ) : (
        <button className={btnDanger} onClick={() => setOpen("delete")}>
          حذف نهائي
        </button>
      )}

      {open === "block" ? (
        <Modal title={`حظر «${fullName}»`} onClose={close}>
          <ReasonForm
            action={blockUser}
            onDone={close}
            hidden={{ target_person_id: personId, block: "true" }}
            submitLabel="احظر"
            placeholder="سبب الحظر (مطلوب)"
          />
        </Modal>
      ) : null}

      {open === "deactivate" ? (
        <Modal title={`إيقاف «${fullName}»`} onClose={close}>
          <p className="text-xs text-foreground/60">
            الإيقاف بيمنع الدخول بس بيحفظ كل السجلّ — قابل للاسترجاع.
          </p>
          <ReasonForm
            action={deleteUser}
            onDone={close}
            hidden={{ target_person_id: personId, mode: "soft" }}
            submitLabel="أوقف"
            placeholder="سبب الإيقاف (مطلوب)"
          />
        </Modal>
      ) : null}

      {open === "delete" ? (
        <Modal title={`حذف «${fullName}» نهائيًا`} onClose={close}>
          <DeleteForm personId={personId} fullName={fullName} onDone={close} />
        </Modal>
      ) : null}

      {open === "roles" ? (
        <Modal title={`أدوار «${fullName}»`} onClose={close}>
          <RolesForm personId={personId} roles={roles} isSelf={isSelf} />
        </Modal>
      ) : null}
    </div>
  );
}

function Modal({
  title,
  onClose,
  children,
}: {
  title: string;
  onClose: () => void;
  children: React.ReactNode;
}) {
  return (
    <div
      className="fixed inset-0 z-50 flex items-center justify-center bg-black/30 p-4"
      onClick={onClose}
    >
      <div
        className="w-full max-w-sm rounded-xl border border-border bg-white p-5 shadow-lg"
        onClick={(e) => e.stopPropagation()}
      >
        <div className="mb-3 flex items-center justify-between gap-3">
          <h3 className="font-bold">{title}</h3>
          <button
            className="text-foreground/50 hover:text-foreground"
            onClick={onClose}
            aria-label="إغلاق"
          >
            ✕
          </button>
        </div>
        <div className="flex flex-col gap-3">{children}</div>
      </div>
    </div>
  );
}

function ReasonForm({
  action,
  onDone,
  hidden,
  submitLabel,
  placeholder,
}: {
  action: AdminAction;
  onDone: () => void;
  hidden: Record<string, string>;
  submitLabel: string;
  placeholder: string;
}) {
  const [state, formAction, pending] = useActionState<
    ActionResult | null,
    FormData
  >(action, null);
  useEffect(() => {
    if (state?.ok) onDone();
  }, [state, onDone]);

  return (
    <form action={formAction} className="flex flex-col gap-3">
      {Object.entries(hidden).map(([k, v]) => (
        <input key={k} type="hidden" name={k} value={v} />
      ))}
      <textarea
        name="reason"
        required
        rows={3}
        placeholder={placeholder}
        className="rounded-lg border border-border px-3 py-2 text-sm outline-none focus:border-primary"
      />
      <button
        type="submit"
        disabled={pending}
        className="self-start rounded-lg bg-primary px-4 py-2 text-sm font-bold text-white transition-opacity hover:opacity-90 disabled:opacity-60"
      >
        {pending ? "…" : submitLabel}
      </button>
      {state?.ok === false ? (
        <p className="text-sm text-red-600">{state.error}</p>
      ) : null}
    </form>
  );
}

function DeleteForm({
  personId,
  fullName,
  onDone,
}: {
  personId: string;
  fullName: string;
  onDone: () => void;
}) {
  const [state, formAction, pending] = useActionState<
    ActionResult | null,
    FormData
  >(deleteUser, null);
  const [confirm, setConfirm] = useState("");
  useEffect(() => {
    if (state?.ok) onDone();
  }, [state, onDone]);

  return (
    <form action={formAction} className="flex flex-col gap-3">
      <input type="hidden" name="target_person_id" value={personId} />
      <input type="hidden" name="mode" value="hard" />
      <p className="rounded-lg bg-red-50 p-2 text-xs text-red-700">
        ⚠️ حذف نهائي لا رجعة فيه. لو فيه سجلّ مرتبط استخدم الإيقاف. اكتب الاسم
        الكامل للتأكيد.
      </p>
      <textarea
        name="reason"
        required
        rows={2}
        placeholder="سبب الحذف (مطلوب)"
        className="rounded-lg border border-border px-3 py-2 text-sm outline-none focus:border-primary"
      />
      <input
        name="confirm"
        value={confirm}
        onChange={(e) => setConfirm(e.target.value)}
        placeholder={fullName}
        autoComplete="off"
        className="rounded-lg border border-border px-3 py-2 text-sm outline-none focus:border-red-400"
      />
      <button
        type="submit"
        disabled={pending || confirm.trim() !== fullName}
        className="self-start rounded-lg bg-red-600 px-4 py-2 text-sm font-bold text-white transition-opacity hover:opacity-90 disabled:opacity-50"
      >
        {pending ? "…" : "احذف نهائيًا"}
      </button>
      {state?.ok === false ? (
        <p className="text-sm text-red-600">{state.error}</p>
      ) : null}
    </form>
  );
}

function RolesForm({
  personId,
  roles,
  isSelf,
}: {
  personId: string;
  roles: string[];
  isSelf: boolean;
}) {
  return (
    <div className="flex flex-col gap-2">
      {ALL_ROLES.map((r) => (
        <RoleToggle
          key={r.value}
          personId={personId}
          role={r}
          has={roles.includes(r.value)}
          isSelf={isSelf}
        />
      ))}
      <p className="text-xs text-foreground/50">
        التغيير بيتسجّل في سجل التدقيق فورًا.
      </p>
    </div>
  );
}

function RoleToggle({
  personId,
  role,
  has,
  isSelf,
}: {
  personId: string;
  role: { value: string; label: string };
  has: boolean;
  isSelf: boolean;
}) {
  const [state, formAction, pending] = useActionState<
    ActionResult | null,
    FormData
  >(manageRole, null);
  // الواجهة بتمنع سحب السوبر أدمن من نفسك (السيرفر بيمنع برضه).
  const disabled = pending || (isSelf && role.value === "super_admin" && has);

  return (
    <form action={formAction} className="flex items-center justify-between gap-2">
      <input type="hidden" name="target_person_id" value={personId} />
      <input type="hidden" name="role" value={role.value} />
      <input type="hidden" name="op" value={has ? "revoke" : "grant"} />
      <span className="text-sm">{role.label}</span>
      <div className="flex items-center gap-2">
        {state?.ok === false ? (
          <span className="text-xs text-red-600">{state.error}</span>
        ) : null}
        <button
          type="submit"
          disabled={disabled}
          className={
            has
              ? "rounded-md bg-primary/10 px-3 py-1 text-xs text-primary disabled:opacity-50"
              : "rounded-md border border-border px-3 py-1 text-xs disabled:opacity-50"
          }
        >
          {pending ? "…" : has ? "مفعّل ✓ (للسحب)" : "امنح"}
        </button>
      </div>
    </form>
  );
}

function UnblockForm({ personId }: { personId: string }) {
  const [, formAction, pending] = useActionState<ActionResult | null, FormData>(
    blockUser,
    null,
  );
  return (
    <form action={formAction} className="inline">
      <input type="hidden" name="target_person_id" value={personId} />
      <input type="hidden" name="block" value="false" />
      <button type="submit" disabled={pending} className={btn}>
        {pending ? "…" : "فك الحظر"}
      </button>
    </form>
  );
}

function RestoreForm({ personId }: { personId: string }) {
  const [, formAction, pending] = useActionState<ActionResult | null, FormData>(
    deleteUser,
    null,
  );
  return (
    <form action={formAction} className="inline">
      <input type="hidden" name="target_person_id" value={personId} />
      <input type="hidden" name="mode" value="restore" />
      <button type="submit" disabled={pending} className={btn}>
        {pending ? "…" : "استرجاع"}
      </button>
    </form>
  );
}

function ResetPasswordButton({
  personId,
  fullName,
}: {
  personId: string;
  fullName: string;
}) {
  const [open, setOpen] = useState(false);
  const [state, formAction, pending] = useActionState<
    ResetResult | null,
    FormData
  >(resetPassword, null);

  return (
    <>
      <button className={btn} onClick={() => setOpen(true)}>
        كلمة السر
      </button>
      {open ? (
        <Modal title={`إعادة كلمة سر «${fullName}»`} onClose={() => setOpen(false)}>
          <form action={formAction} className="flex flex-col gap-3">
            <input type="hidden" name="target_person_id" value={personId} />
            <p className="text-xs text-foreground/60">
              بيتولّد رابط استرجاع — انسخه وابعته للمستخدم بنفسك (مش بيتبعت تلقائيًا).
            </p>
            <textarea
              name="reason"
              required
              rows={2}
              placeholder="السبب (مطلوب)"
              className="rounded-lg border border-border px-3 py-2 text-sm outline-none focus:border-primary"
            />
            <button
              type="submit"
              disabled={pending}
              className="self-start rounded-lg bg-primary px-4 py-2 text-sm font-bold text-white transition-opacity hover:opacity-90 disabled:opacity-60"
            >
              {pending ? "…" : "ولّد الرابط"}
            </button>
            {state?.ok === false ? (
              <p className="text-sm text-red-600">{state.error}</p>
            ) : null}
            {state?.ok === true ? (
              <div className="flex flex-col gap-1 rounded-lg bg-primary/10 p-3 text-sm">
                <span className="font-bold text-primary">
                  اتولّد الرابط ✅ — ابعته للمستخدم:
                </span>
                <code className="break-all text-xs text-foreground/70">
                  {state.actionLink ?? "(مفيش لينك)"}
                </code>
              </div>
            ) : null}
          </form>
        </Modal>
      ) : null}
    </>
  );
}
