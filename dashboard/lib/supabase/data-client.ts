import "server-only";
import { cache } from "react";
import { cookies } from "next/headers";
import { createImpersonatedClient, IMP_COOKIE } from "./impersonated";
import { createSupabaseServerClient } from "./server";

// Keep the operator's authentication separate from the subject's RLS identity.
type DataContext = {client:Awaited<ReturnType<typeof createImpersonatedClient>>;personId?:string;impersonationSessionId?:string};
const getDataContext = cache(async ():Promise<DataContext> => {
  const server = await createSupabaseServerClient();
  const token = (await cookies()).get(IMP_COOKIE)?.value;
  if (!token) return {client:server};
  let claims: { sub?: string; exp?: number; act?: { sub?: string; sid?: string } };
  try { claims = JSON.parse(Buffer.from(token.split(".")[1], "base64url").toString()); }
  catch { throw new Error("invalid_impersonation"); }
  if (typeof claims.exp !== 'number' || claims.exp * 1000 <= Date.now()) return {client:server};
  const { data: { user: operator }, error: operatorError } = await server.auth.getUser();
  if (operatorError || !operator || claims.act?.sub !== operator.id || !claims.act.sid) throw new Error("invalid_impersonation_actor");
  const { data: session, error: sessionError } = await server.from("impersonation_session").select("subject_person_id, started_at, ended_at").eq("id", claims.act.sid).maybeSingle();
  if (sessionError || !session || session.ended_at || Date.now() - new Date(session.started_at).getTime() >= 1800000) throw new Error("impersonation_ended");
  const { data: subject } = await server.from("app_user").select("auth_user_id").eq("person_id", session.subject_person_id).maybeSingle();
  if (!subject || subject.auth_user_id !== claims.sub) throw new Error("invalid_impersonation_subject");
  const client = await createImpersonatedClient();
  const { error } = await client.auth.getUser(token);
  if (error) throw new Error("invalid_impersonation_token");
  return {client,personId:session.subject_person_id,impersonationSessionId:claims.act.sid};
});
export const getDataClient = cache(async () => (await getDataContext()).client);
export const getDataIdentity = cache(async () => {
  const context=await getDataContext();
  if(context.personId)return {personId:context.personId,impersonationSessionId:context.impersonationSessionId};
  const {data:{user},error:authError}=await context.client.auth.getUser();
  if(authError||!user)throw new Error('authentication_required');
  const {data,error}=await context.client.from('app_user').select('person_id').eq('auth_user_id',user.id).single();
  if(error||!data)throw new Error('account_identity_missing');
  return {personId:data.person_id as string,impersonationSessionId:undefined};
});
