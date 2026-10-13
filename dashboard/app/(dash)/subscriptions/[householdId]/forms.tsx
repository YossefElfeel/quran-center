"use client";
import { FieldSelect } from "@/components/ui/fields";
import { useActionState,useEffect } from "react";
import { SubmitButton } from "@/components/ui/button";
import { toast } from "@/components/ui/feedback";
import { addMember } from "./actions";
export function MemberForm({householdId,people}:{householdId:string;people:{id:string;full_name:string}[]}){
  const [state,action]=useActionState(addMember,null);
  useEffect(()=>{if(state?.ok)toast('العضو اتضاف للأسرة')},[state]);
  return <form action={action} className="flex flex-wrap items-end gap-3"><input type="hidden" name="household_id" value={householdId}/><label>الشخص<FieldSelect feedback={state} name="person_id" required className="ms-3 rounded-lg border border-border p-3"><option value="">اختار شخص</option>{people.map(p=><option key={p.id} value={p.id}>{p.full_name}</option>)}</FieldSelect></label><label>الدور<FieldSelect feedback={state} name="role" className="ms-3 rounded-lg border border-border p-3"><option value="guardian">ولي أمر</option><option value="student">طالب</option></FieldSelect></label><SubmitButton>إضافة عضو</SubmitButton>{state?.ok===false&&<p role="alert">{state.error}</p>}</form>;
}
