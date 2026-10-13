"use client";
import { useEffect, useId, useRef } from "react";

const VARIANT_CLASS = {
  modal: "m-auto max-h-[90dvh] w-[min(92vw,32rem)] rounded-xl border p-6",
  // درج جانبي ملزوق بحافة البداية (اليمين في RTL)، بطول الشاشة، وبيدخل بانزلاق (globals.css: .dialog-drawer).
  drawer: "dialog-drawer fixed inset-y-0 start-0 end-auto m-0 h-dvh max-h-dvh w-[min(85vw,20rem)] max-w-none rounded-none border-e p-4",
} as const;

export function Dialog({ title, onClose, children, variant = "modal" }: { title: string; onClose: () => void; children: React.ReactNode; variant?: keyof typeof VARIANT_CLASS }) {
  const ref = useRef<HTMLDialogElement>(null);
  const id = useId();
  useEffect(() => {
    const dialog = ref.current!;
    const previous = document.activeElement as HTMLElement | null;
    dialog.showModal();
    return () => { dialog.close(); previous?.focus(); };
  }, []);
  return <dialog ref={ref} aria-labelledby={id} aria-modal="true" onKeyDown={event => {
    if(event.key !== 'Tab') return;
    const controls=Array.from(event.currentTarget.querySelectorAll<HTMLElement>('button:not(:disabled), input:not(:disabled):not([type="hidden"]), select:not(:disabled), textarea:not(:disabled), a[href], [tabindex="0"]')).filter(element=>element.getClientRects().length>0);
    const first=controls[0],last=controls.at(-1);
    if(event.shiftKey&&document.activeElement===first) {event.preventDefault();last?.focus();}
    else if(!event.shiftKey&&document.activeElement===last) {event.preventDefault();first?.focus();}
  }} onCancel={(event) => { event.preventDefault(); onClose(); }} className={`${VARIANT_CLASS[variant]} overflow-y-auto border-border bg-white text-foreground shadow-xl backdrop:bg-black/50`}>
    <div className="mb-5 flex items-start justify-between gap-4"><h2 id={id} className="text-xl font-bold">{title}</h2><button type="button" onClick={onClose} aria-label="إغلاق" className="min-h-11 min-w-11 rounded-lg border border-border">×</button></div>
    {children}
  </dialog>;
}
