"use client";
import { useEffect, useId, useRef } from "react";

export function Dialog({ title, onClose, children }: { title: string; onClose: () => void; children: React.ReactNode }) {
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
  }} onCancel={(event) => { event.preventDefault(); onClose(); }} className="m-auto max-h-[90dvh] w-[min(92vw,32rem)] overflow-y-auto rounded-xl border border-border bg-white p-6 text-foreground shadow-xl backdrop:bg-black/50">
    <div className="mb-5 flex items-start justify-between gap-4"><h2 id={id} className="text-xl font-bold">{title}</h2><button type="button" onClick={onClose} aria-label="إغلاق" className="min-h-11 min-w-11 rounded-lg border border-border">×</button></div>
    {children}
  </dialog>;
}
