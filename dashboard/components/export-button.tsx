"use client";
import { useState } from "react";
import { toast } from "@/components/ui/feedback";
import { Button } from "@/components/ui/button";

export function ExportButton({href,filename}:{href:string;filename:string}) {
  const [busy,setBusy]=useState(false);
  return <Button disabled={busy} onClick={async()=>{
    if(busy)return;setBusy(true);
    try{const response=await fetch(href);if(!response.ok)throw new Error("export_failed");
      const url=URL.createObjectURL(await response.blob());const a=document.createElement("a");a.href=url;a.download=filename;a.click();URL.revokeObjectURL(url);toast("التصدير اكتمل");
    }catch{toast("تعذّر تصدير السجل — جرّب تاني",true);}finally{setBusy(false);}
  }}>{busy?"جارٍ تصدير السجل…":"تصدير كل النتائج CSV"}</Button>;
}
