"use client";
import { DangerAction } from "./danger-action";
export type FormResult={ok:true}|{ok:false;error:string};
type Action=(previous:FormResult|null,fd:FormData)=>Promise<FormResult>;
export function DeleteButton({action,hidden,label,confirmMessage}:{action:Action;hidden:Record<string,string>;label:string;confirmMessage:string}){
  return <DangerAction action={action} hidden={hidden} label={label} title={confirmMessage} requireReason={false} />;
}
