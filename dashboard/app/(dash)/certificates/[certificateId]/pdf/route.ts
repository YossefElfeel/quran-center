import { z } from "zod";
import { getSuperAdmin } from "@/lib/auth";
import { getDataClient } from "@/lib/supabase/data-client";
import { certificatePdf } from "@/lib/certificate-pdf";
import { formatDate } from "@/lib/format";

export const runtime="nodejs";
export async function GET(request: Request,{params}:{params:Promise<{certificateId:string}>}){
  if(!await getSuperAdmin())return new Response("Forbidden",{status:403});
  const {certificateId}=await params;
  if(!z.uuid().safeParse(certificateId).success)return new Response("Not found",{status:404});
  const client=await getDataClient();
  const [cert,settings]=await Promise.all([
    client.from("certificate").select("id,kind,issued_at,student:student_person_id(full_name)").eq("id",certificateId).maybeSingle(),
    client.from("system_settings").select("value").eq("key","center_name").maybeSingle(),
  ]);
  if(cert.error||settings.error)return new Response("Load failed",{status:500});
  if(!cert.data)return new Response("Not found",{status:404});
  const row=cert.data as unknown as {id:string;kind:string;issued_at:string;student:{full_name:string}|null};
  const labels:Record<string,string>={juz_amma:"جزء عمّ",half:"نصف القرآن",full:"إتمام القرآن",honor:"تكريم"};
  const bytes=await certificatePdf({name:row.student?.full_name??"الطالب",kind:labels[row.kind]??row.kind,date:formatDate(row.issued_at),center:String(settings.data?.value??"دار تحفيظ القرآن"),id:row.id});
  const disposition=new URL(request.url).searchParams.has("download")?"attachment":"inline";
  return new Response(new Uint8Array(bytes),{headers:{"Content-Type":"application/pdf","Content-Disposition":`${disposition}; filename=certificate-${row.id}.pdf`,"Cache-Control":"private, no-store"}});
}
