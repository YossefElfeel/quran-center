import Link from "next/link";
import { notFound } from "next/navigation";
import { z } from "zod";
import { getDataClient } from "@/lib/supabase/data-client";

export default async function CertificatePreview({params}:{params:Promise<{certificateId:string}>}){
  const {certificateId}=await params;if(!z.uuid().safeParse(certificateId).success)notFound();
  const client=await getDataClient();const {data,error}=await client.from("certificate").select("id").eq("id",certificateId).maybeSingle();
  if(error)throw error;if(!data)notFound();
  return <div className="flex flex-col gap-4"><Link href="/certificates" className="text-primary">→ الشهادات</Link><h1 className="text-2xl font-bold">عرض الشهادة</h1><a href={`/certificates/${certificateId}/pdf?download=1`} className="self-start rounded-lg bg-primary px-4 py-3 font-bold text-white">تحميل PDF</a><iframe title="معاينة الشهادة بصيغة PDF" src={`/certificates/${certificateId}/pdf`} className="min-h-[70vh] w-full rounded-xl border border-border"/></div>;
}
