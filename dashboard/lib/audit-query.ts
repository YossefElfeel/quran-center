import type { SupabaseClient } from "@supabase/supabase-js";
import { z } from "zod";

const filters = z.object({
  action: z.string().max(100).optional(),
  actor: z.union([z.uuid(), z.literal("")]).optional(),
  from: z.union([z.iso.date(), z.literal("")]).optional(),
  to: z.union([z.iso.date(), z.literal("")]).optional(),
});
export type AuditFilters = z.infer<typeof filters>;
export function parseAuditFilters(value: unknown): AuditFilters {
  const result = filters.safeParse(value);
  if (!result.success) throw new Error("invalid_audit_filters");
  return result.data;
}
export function auditQuery(client: SupabaseClient, values: AuditFilters) {
  let query = client.from("audit_log").select("id,action,target_table,target_id,at,actor:actor_person_id(id,full_name,phone)",{count:"exact"}).order("at",{ascending:false}).order("id",{ascending:false});
  if(values.action) query=query.eq("action",values.action);
  if(values.actor) query=query.eq("actor_person_id",values.actor);
  if(values.from) query=query.gte("at",`${values.from}T00:00:00Z`);
  if(values.to) query=query.lte("at",`${values.to}T23:59:59.999Z`);
  return query;
}
