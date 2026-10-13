"use client";
import { FieldInput, FieldSelect } from "@/components/ui/fields";
import { normalizeNumber } from "@/lib/validation";
import { useActionState,useEffect,useState } from "react";
import { DangerAction } from "@/components/danger-action";
import { Dialog } from "@/components/ui/dialog";
import { SubmitButton,Button } from "@/components/ui/button";
import { toast } from "@/components/ui/feedback";
import {createHousehold,recordPayment,voidPayment} from './actions';
export function HouseholdForm(){const [state,action]=useActionState(createHousehold,null);useEffect(()=>{if(state?.ok)toast('الأسرة اتضافت')},[state]);return <form action={action} className="flex flex-wrap items-end gap-3"><label>اسم الأسرة<FieldInput feedback={state} name="name" required className="ms-3"/></label><label>الاشتراك الشهري<FieldInput feedback={state} name="monthly_amount" type="text" inputMode="decimal" pattern="[0-9٠-٩۰-۹]+([.٫][0-9٠-٩۰-۹]{1,2})?" defaultValue={10} className="ms-3 w-28"/></label><SubmitButton>أضف أسرة</SubmitButton>{state?.ok===false&&<p role="alert">{state.error}</p>}</form>}
export function PaymentForm({householdId,defaultAmount}:{householdId:string;defaultAmount:number}){
  const [open,setOpen]=useState(false);
  return <><Button variant="secondary" onClick={()=>setOpen(true)}>تسجيل دفعة</Button>{open&&<Dialog title="تسجيل دفعة" onClose={()=>setOpen(false)}><PaymentFields householdId={householdId} amount={defaultAmount}/></Dialog>}</>;
}
function PaymentFields({householdId,amount}:{householdId:string;amount:number}){
  const [state,action]=useActionState(recordPayment,null);const [review,setReview]=useState(false);const [period,setPeriod]=useState(()=>(()=>{const parts=new Intl.DateTimeFormat('en-CA',{year:'numeric',month:'2-digit',timeZone:'Africa/Cairo'}).formatToParts(new Date());return parts.find(p=>p.type==='year')!.value+'-'+parts.find(p=>p.type==='month')!.value})());const [value,setValue]=useState(String(amount));const [method,setMethod]=useState('cash');
  useEffect(()=>{if(state?.ok)toast('الدفعة اتسجّلت')},[state]);
  if(state?.ok)return <div className="space-y-4"><p role="status">الدفعة اتسجّلت</p>{state.paymentId&&<DangerAction action={voidPayment} label="تراجع عن الدفعة" title="إلغاء الدفعة؟" hidden={{id:state.paymentId}}/>}</div>;
  return <form action={action} className="space-y-4"><input type="hidden" name="household_id" value={householdId}/><label className="block">الشهر<FieldInput feedback={state} name="period_month" type="month" value={period} onChange={e=>{setPeriod(e.target.value);setReview(false)}} required className="mt-1"/></label><label className="block">المبلغ (ج.م)<FieldInput feedback={state} name="amount" type="number" min={0} step="0.01" required value={value} onChange={e=>{setValue(e.target.value);setReview(false)}} className="mt-1"/></label><label className="block">الطريقة<FieldSelect feedback={state} name="method" value={method} onChange={e=>{setMethod(e.target.value);setReview(false)}} className="mt-1"><option value="cash">كاش</option><option value="instapay">InstaPay</option><option value="other">أخرى</option></FieldSelect></label>{state?.ok===false&&<p role="alert" className="text-red-700">{state.error}</p>}{review?<div className="space-y-3"><p>راجع: {period} — {new Intl.NumberFormat('ar-EG').format(Number(normalizeNumber(value)))} ج.م — {method==='cash'?'كاش':method==='instapay'?'InstaPay':'أخرى'}</p><SubmitButton>تأكيد تسجيل الدفعة</SubmitButton></div>:<Button type="button" onClick={event=>{if(event.currentTarget.form?.reportValidity())setReview(true)}}>مراجعة الدفعة</Button>}</form>;
}
export function VoidButton({paymentId}:{paymentId:string}){return <DangerAction action={voidPayment} hidden={{id:paymentId}} label="إبطال الدفعة" title="إبطال الدفعة؟" description="الدفعة الملغاة مش هتُحسب في حالة الاشتراك."/>}
