"use client";
import { useId, useState } from "react";

export function RowActions({children}: {children: React.ReactNode}) {
  const [open,setOpen]=useState(false);
  const id=useId();
  return <div className="relative">
    <button type="button" aria-label="إجراءات الصف" aria-expanded={open} aria-controls={id} onClick={()=>setOpen(value=>!value)} className="min-h-11 min-w-11 rounded-lg border border-border text-xl lg:hidden">⋯</button>
    <div id={id} className={`${open?'flex':'hidden'} mt-2 flex-wrap items-center gap-2 lg:mt-0 lg:flex`}>{children}</div>
  </div>;
}
