import "server-only";
import { cache } from "react";
import { cookies } from "next/headers";
import { impersonationOver, impersonationTokenExpired, readImpersonationClaims } from "@/lib/impersonation-timing";
import { createImpersonatedClient, IMP_COOKIE } from "./impersonated";
import { createSupabaseServerClient } from "./server";

// Keep the operator's authentication separate from the subject's RLS identity.
// Any token that is malformed, expired, ended, or not issued to this operator is treated as
// "no impersonation" (operator client) instead of throwing; proxy.ts clears such cookies,
// because Server Components cannot modify cookies.
type DataContext = {client:Awaited<ReturnType<typeof createImpersonatedClient>>;personId?:string;impersonationSessionId?:string};
const getDataContext = cache(async ():Promise<DataContext> => {
  const server = await createSupabaseServerClient();
  const operatorContext = {client:server};
  const token = (await cookies()).get(IMP_COOKIE)?.value;
  if (!token) return operatorContext;
  const claims = readImpersonationClaims(token);
  if (!claims || impersonationTokenExpired(claims.exp)) return operatorContext;
  const { data: { user: operator }, error: operatorError } = await server.auth.getUser();
  if (operatorError || !operator || claims.act?.sub !== operator.id || !claims.act.sid) return operatorContext;
  const { data: session, error: sessionError } = await server.from("impersonation_session").select("subject_person_id, started_at, ended_at").eq("id", claims.act.sid).maybeSingle();
  if (sessionError || !session || session.ended_at || impersonationOver(session.started_at)) return operatorContext;
  const { data: subject } = await server.from("app_user").select("auth_user_id").eq("person_id", session.subject_person_id).maybeSingle();
  if (!subject || subject.auth_user_id !== claims.sub) return operatorContext;
  const client = await createImpersonatedClient();
  const { error } = await client.auth.getUser(token);
  if (error) return operatorContext;
  return {client,personId:session.subject_person_id,impersonationSessionId:claims.act.sid};
});
export const getDataClient = cache(async () => (await getDataContext()).client);
// True only while a valid impersonation is in effect for this request.
export const isDataImpersonated = cache(async () => Boolean((await getDataContext()).personId));
export const getDataIdentity = cache(async () => {
  const context=await getDataContext();
  if(context.personId)return {personId:context.personId,impersonationSessionId:context.impersonationSessionId};
  const {data:{user},error:authError}=await context.client.auth.getUser();
  if(authError||!user)throw new Error('authentication_required');
  const {data,error}=await context.client.from('app_user').select('person_id').eq('auth_user_id',user.id).single();
  if(error||!data)throw new Error('account_identity_missing');
  return {personId:data.person_id as string,impersonationSessionId:undefined};
});
