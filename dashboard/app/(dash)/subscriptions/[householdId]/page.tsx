import Link from "next/link";
import { notFound } from "next/navigation";
import { getDataClient } from "@/lib/supabase/data-client";
import { formatMonth,formatNumber } from "@/lib/format";
import { Button } from "@/components/ui/button";
import { FieldInput } from "@/components/ui/fields";
import { DangerAction } from "@/components/danger-action";
import { PaymentForm } from "../forms";
import { MemberForm } from "./forms";
import { removeMember } from "./actions";
export default async function HouseholdPage({params,searchParams}:{params:Promise<{householdId:string}>;searchParams:Promise<{q?:string}>}){
  const {householdId}=await params,{q}=await searchParams;if(!/^[0-9a-f-]{36}$/i.test(householdId))notFound();
  const client=await getDataClient();let peopleQuery=client.from('person').select('id,full_name').order('full_name').limit(50);if(q)peopleQuery=peopleQuery.ilike('full_name',`%${q}%`);
  const [household,members,payments,people]=await Promise.all([client.from('household').select('id,name,monthly_amount').eq('id',householdId).maybeSingle(),client.from('household_member').select('id,role,person:person_id(id,full_name)').eq('household_id',householdId),client.from('subscription_payment').select('id,amount,period_month,voided').eq('household_id',householdId).order('period_month',{ascending:false}).limit(24),peopleQuery]);
  if(household.error||members.error||payments.error||people.error)throw new Error('household_load_failed');if(!household.data)notFound();
  return <div className="max-w-4xl space-y-6"><Link href="/subscriptions" className="text-primary underline">→ الاشتراكات</Link><h1 className="text-2xl font-bold">{household.data.name}</h1><p>الاشتراك الشهري: {formatNumber(household.data.monthly_amount)} ج.م</p><PaymentForm householdId={householdId} defaultAmount={household.data.monthly_amount}/><h2 className="text-xl font-semibold">أعضاء الأسرة</h2>{(members.data??[]).map(row=>{const person=row.person as unknown as {id:string;full_name:string}|null;return <div key={row.id} className="flex flex-wrap justify-between gap-3 border-b border-border py-3">{person&&<Link href={`/users/${person.id}`} className="text-primary underline">{person.full_name}</Link>}<span>{row.role==='guardian'?'ولي أمر':'طالب'}</span><DangerAction action={removeMember} hidden={{id:row.id,household_id:householdId}} label="إزالة العضوية" title="إزالة العضو من الأسرة؟" description="إزالة ولي الأمر ممكن توقف وصوله لبوابة المتابعة." /></div>})}<form className="flex flex-wrap items-center gap-3"><label className="flex items-center gap-3">بحث عن عضو<FieldInput name="q" defaultValue={q} aria-label="بحث عن عضو" className="w-auto" /></label><Button type="submit" variant="secondary">بحث</Button></form><MemberForm householdId={householdId} people={people.data??[]}/><h2 className="text-xl font-semibold">سجل الدفعات</h2>{(payments.data??[]).map(p=><p key={p.id}>{formatMonth(p.period_month)} — {formatNumber(p.amount)} ج.م — {p.voided?'ملغاة':'مدفوعة'}</p>)}</div>;
}
