import type { Metadata } from "next";
import Link from "next/link";
import { ApplicationForm } from "@/components/application-form";
import { supabaseAnon } from "@/lib/supabase-server";
export const dynamic="force-dynamic";
export const metadata:Metadata={title:'المسابقات',description:'المسابقات المفتوحة وشروط التقديم في دار التحفيظ'};
async function serverTime() { return Date.now(); }
type Competition={id:string;name:string;year:number|null;rules:string|null;deadline:string|null;prize:string|null};
export default async function CompetitionPage(){
  const {data,error}=await supabaseAnon().from('competition').select('id,name,year,rules,deadline,prize').eq('status','open').order('year',{ascending:false});
  const now = await serverTime();
  return <main className="mx-auto w-full max-w-2xl space-y-8 px-5 py-12"><h1 className="text-3xl font-bold text-[var(--brand)]">مسابقات دار التحفيظ</h1>
    {error?<p role="alert">تعذّر تحميل المسابقات. جرّب تحديث الصفحة بعد شوية.</p>:!data?.length?<div className="space-y-4"><p>مفيش مسابقة مفتوحة دلوقتي — تابعنا قريب.</p><Link href="/courses" className="underline">تصفّح الكورسات المجانية</Link></div>:(data as Competition[]).map(comp=><section key={comp.id} className="space-y-5 border-b border-gray-200 pb-8"><h2 className="text-2xl font-semibold">{comp.name}{comp.year?` — ${new Intl.NumberFormat('ar-EG',{useGrouping:false}).format(comp.year)}`:''}</h2>{comp.rules&&<p className="whitespace-pre-wrap">{comp.rules}</p>}{comp.prize&&<p>الجائزة: {comp.prize}</p>}{comp.deadline&&<p>آخر موعد: {new Intl.DateTimeFormat('ar-EG',{dateStyle:'long',timeZone:'Africa/Cairo'}).format(new Date(comp.deadline))}</p>}{comp.deadline&&Date.parse(comp.deadline)<now?<p>موعد التقديم انتهى</p>:<ApplicationForm competitionId={comp.id}/>}</section>)}
  </main>;
}
