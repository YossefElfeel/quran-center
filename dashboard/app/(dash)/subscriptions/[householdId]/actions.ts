"use server";
import { validateAction } from "@/lib/action-schemas";
import { revalidatePath } from "next/cache";
import { z } from "zod";
import { getDataClient } from "@/lib/supabase/data-client";
import { logAudit } from "@/lib/audit";
import type { FormResult } from "@/lib/guard";
export async function addMember(_previous:FormResult|null,fd:FormData):Promise<FormResult>{
  const formError = validateAction("addMember", fd);
  if (formError) return formError;

  const parsed=z.object({household_id:z.uuid(),person_id:z.uuid(),role:z.enum(['guardian','student'])}).safeParse(Object.fromEntries(fd));
  if(!parsed.success)return{ok:false,error:'اختار الشخص ودوره في الأسرة.'};
  const client=await getDataClient();const {error}=await client.from('household_member').insert(parsed.data);
  if(error)return{ok:false,error:error.code==='23505'?'الشخص مضاف لأسرة بالفعل.':'تعذّر إضافة العضوية.'};
  await logAudit({action:'household_member_added',targetTable:'household',targetId:parsed.data.household_id});revalidatePath(`/subscriptions/${parsed.data.household_id}`);return{ok:true};
}
export async function removeMember(_previous:FormResult|null,fd:FormData):Promise<FormResult>{
  const formError = validateAction("removeMember", fd);
  if (formError) return formError;

  const id=String(fd.get('id')??''),household=String(fd.get('household_id')??'');
  if(!z.uuid().safeParse(id).success||!z.uuid().safeParse(household).success)return{ok:false,error:'عضوية غير صحيحة.'};
  const client=await getDataClient();const {error}=await client.from('household_member').delete().eq('id',id).eq('household_id',household).select('id').single();
  if(error)return{ok:false,error:'تعذّر إزالة العضوية.'};
  await logAudit({action:'household_member_removed',targetTable:'household',targetId:household});revalidatePath(`/subscriptions/${household}`);return{ok:true};
}
