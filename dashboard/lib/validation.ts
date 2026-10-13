import { z } from "zod";
export type ValidationFailure={ok:false;error:string;fieldErrors?:Record<string,string[]|undefined>};
export const idSchema=z.uuid({error:'المعرّف غير صحيح'});
export const nameSchema=z.string().trim().min(2,'اكتب الاسم كاملًا').max(200,'الاسم أطول من اللازم');
export const webUrlSchema=z.url({error:'اكتب رابطًا صحيحًا'}).refine(value=>['http:','https:'].includes(new URL(value).protocol),'استخدم رابط HTTP أو HTTPS');
export function validationError(result:z.ZodSafeParseResult<unknown>):ValidationFailure|null{return result.success?null:{ok:false,error:'راجع الحقول المعلّمة وأعد المحاولة',fieldErrors:z.flattenError(result.error).fieldErrors as Record<string,string[]|undefined>};}
export function normalizeNumber(value:string){return value.replace(/[٠-٩۰-۹]/g,char=>String(char.charCodeAt(0)-(char.charCodeAt(0)>=0x6f0?0x6f0:0x660))).replace('٫','.');}
// datetime-local fields are center time, independent of the server's timezone.
export function cairoDateTime(value:string):string|null{
  if(!/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}$/.test(value))return null;
  const desired=Date.parse(`${value}:00Z`);if(!Number.isFinite(desired))return null;
  const format=new Intl.DateTimeFormat('sv-SE',{timeZone:'Africa/Cairo',year:'numeric',month:'2-digit',day:'2-digit',hour:'2-digit',minute:'2-digit',second:'2-digit',hourCycle:'h23'});
  let timestamp=desired;
  for(let i=0;i<3;i++){const parts=Object.fromEntries(format.formatToParts(new Date(timestamp)).map(p=>[p.type,p.value]));const local=`${parts.year}-${parts.month}-${parts.day}T${parts.hour}:${parts.minute}`;if(local===value)return new Date(timestamp).toISOString();timestamp+=desired-Date.parse(`${local}:00Z`);}
  return null;
}
