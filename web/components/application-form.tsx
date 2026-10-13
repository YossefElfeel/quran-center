"use client";
import { useId, useState } from "react";
import Link from "next/link";
import { createClient } from "@/lib/supabase";
const normalize=(text:string)=>text.replace(/[٠-٩۰-۹]/g,char=>String(char.charCodeAt(0)-(char.charCodeAt(0)>=0x6f0?0x6f0:0x660)));
function youtubeUrl(value:string){try{const url=new URL(value);return ['https:','http:'].includes(url.protocol)&&['youtube.com','www.youtube.com','m.youtube.com','youtu.be','youtube-nocookie.com','www.youtube-nocookie.com'].includes(url.hostname);}catch{return false;}}
export function ApplicationForm({competitionId}:{competitionId:string}){
  const id=useId();const [busy,setBusy]=useState(false);const [reference,setReference]=useState('');const [errors,setErrors]=useState<Record<string,string>>({});
  const reviewDays=process.env.NEXT_PUBLIC_APPLICATION_REVIEW_DAYS;
  if(reference)return <div role="status" className="space-y-5 rounded-xl border border-emerald-200 bg-emerald-50 p-6"><h3 className="text-xl font-bold">طلبك اتسجّل</h3><p>رقم المتابعة: <b dir="ltr">{reference}</b></p><ol className="list-inside list-decimal space-y-2"><li>الإدارة تراجع الطلب والفيديو.</li><li>{reviewDays?`نتواصل على الموبايل خلال ${reviewDays} أيام بعد المراجعة.`:'الإدارة تتواصل على الموبايل بعد المراجعة.'}</li></ol><div className="flex gap-5"><Link href="/" className="underline">الرئيسية</Link><Link href="/courses" className="underline">الكورسات</Link></div></div>;
  return <form className="space-y-5" onSubmit={async event=>{
    event.preventDefault();if(busy)return;const form=new FormData(event.currentTarget);const name=String(form.get('name')).trim();const phone=normalize(String(form.get('phone'))).replace(/[\s()-]/g,'');const youtube=String(form.get('youtube')).trim();const next:Record<string,string>={};
    if(name.length<2)next.name='اكتب الاسم بالكامل';if(!/^\+?[0-9]{10,15}$/.test(phone))next.phone='اكتب رقم موبايل صحيح من ١٠ إلى ١٥ رقم';if(youtube&&!youtubeUrl(youtube))next.youtube='اكتب رابط فيديو يوتيوب صحيح';if(!form.get('consent'))next.consent='الموافقة مطلوبة للتقديم';setErrors(next);if(Object.keys(next).length)return;
    setBusy(true);try{const {data,error}=await createClient().functions.invoke('submit-public-application',{body:{competition_id:competitionId,name,phone,consent_ack:true,youtube_url:youtube||undefined}});if(error||!data?.application_id)throw error??new Error('missing_reference');setReference(data.application_id);}catch{setErrors({form:'تعذّر تسجيل الطلب — راجع الاتصال. لو قدّمت قبل كده، تواصل مع الإدارة.'});}finally{setBusy(false);}
  }} noValidate>
    {[['name','الاسم بالكامل','text'],['phone','رقم الموبايل','tel'],['youtube','رابط فيديو يوتيوب (اختياري)','url']].map(([field,label,type])=><div key={field}><label htmlFor={`${id}-${field}`} className="mb-2 block">{label}</label><input id={`${id}-${field}`} name={field} type={type} required={field!=='youtube'} autoComplete={field==='name'?'name':field==='phone'?'tel':'off'} dir={field==='name'?'auto':'ltr'} aria-invalid={!!errors[field]} aria-describedby={errors[field]?`${id}-${field}-error`:undefined} className="w-full rounded-lg border border-gray-300 bg-white p-3"/>{errors[field]&&<p id={`${id}-${field}-error`} role="alert" className="mt-1 text-sm text-red-700">{errors[field]}</p>}</div>)}
    <label className="flex items-start gap-3"><input type="checkbox" name="consent" className="mt-1 size-5" required/>موافق إن الدار تتواصل معايا وتستخدم بياناتي للمسابقة.</label>{errors.consent&&<p role="alert" className="text-red-700">{errors.consent}</p>}{errors.form&&<p role="alert" className="text-red-700">{errors.form}</p>}<button disabled={busy} className="w-full rounded-lg bg-[var(--brand)] p-3 font-semibold text-white disabled:opacity-50">{busy?'جاري التسجيل…':'قدّم في المسابقة'}</button>
  </form>;
}
