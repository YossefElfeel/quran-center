import { getSuperAdmin } from "@/lib/auth";
import { getDataClient } from "@/lib/supabase/data-client";
import { auditQuery,parseAuditFilters } from "@/lib/audit-query";
import { actionLabel } from "@/lib/action-labels";
import { formatDateTime } from "@/lib/format";

type Row={id:string;at:string;action:string;target_table:string|null;target_id:string|null;actor:{full_name:string}|null};
function cell(value: string) {
  const safe=/^[=+\-@\t\r]/.test(value)?`'${value}`:value;
  return `"${safe.replaceAll('"','""')}"`;
}
export async function GET(request: Request) {
  if(!await getSuperAdmin())return new Response("Forbidden",{status:403});
  try {
    const values=parseAuditFilters(Object.fromEntries(new URL(request.url).searchParams));
    const client=await getDataClient();const snapshot=new Date().toISOString();
    const first=await auditQuery(client,values).lte("at",snapshot).limit(500);
    if(first.error)throw first.error;
    let rows=(first.data??[]) as unknown as Row[];const encoder=new TextEncoder();
    const stream=new ReadableStream<Uint8Array>({async start(controller){
      try{
        controller.enqueue(encoder.encode('\uFEFFالتاريخ,الفاعل,الإجراء,الجدول,المعرّف\r\n'));
        while(rows.length){
          controller.enqueue(encoder.encode(rows.map(r=>[formatDateTime(r.at),r.actor?.full_name??"—",actionLabel(r.action),r.target_table??"",r.target_id??""].map(cell).join(",")).join("\r\n")+"\r\n"));
          const last=rows[rows.length-1];
          const next=await auditQuery(client,values).lte("at",snapshot).or(`at.lt.${last.at},and(at.eq.${last.at},id.lt.${last.id})`).limit(500);
          if(next.error)throw next.error;rows=(next.data??[]) as unknown as Row[];
        }controller.close();
      }catch(error){controller.error(error);}
    }});
    return new Response(stream,{headers:{"Content-Type":"text/csv; charset=utf-8","Content-Disposition":"attachment; filename=audit_log.csv","Cache-Control":"no-store"}});
  }catch{return new Response("Export failed",{status:400});}
}
