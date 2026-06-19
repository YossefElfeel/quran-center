// Edge Function: data-console-write  —  ⚠️ مكتوبة، النشر متأجّل. راجع docs/DEPLOY_RUNBOOK.md
// (تدوير مفتاح service-role المكشوف قبل التفعيل).
//
// كتابة عامّة محروسة من «وحدة التحكّم بالبيانات» (سوبر أدمن فقط، مدقّقة). service-role
// بيتخطّى RLS، فالحواجز هنا هي الحماية:
//   - النده لازم يكون سوبر أدمن "نشط" (تحقّق عبر service-role، مش اعتماد على RLS).
//   - deny-list لجداول حسّاسة (app_user, audit_log, role_assignment) — تُدار بمسارات مخصّصة.
//   - تجريد أعمدة PII (الرقم القومي) من أي insert/update.
//   - السبب مطلوب. كل عملية بتتسجّل في audit_log.
//   - update/delete لازم لها match (مايسمحش بمسح/تعديل جدول كامل).

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const DENY_TABLES = ['app_user', 'audit_log', 'role_assignment'];
const PII_COLS = ['national_id_encrypted', 'national_id_hmac', 'national_id_last4'];

function json(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { 'Content-Type': 'application/json' },
  });
}

function strip(obj: Record<string, unknown>): Record<string, unknown> {
  const out: Record<string, unknown> = {};
  for (const [k, v] of Object.entries(obj)) {
    if (!PII_COLS.includes(k)) out[k] = v;
  }
  return out;
}

Deno.serve(async (req: Request): Promise<Response> => {
  if (req.method !== 'POST') return json({ error: 'method_not_allowed' }, 405);
  const authHeader = req.headers.get('Authorization') ?? '';
  if (!authHeader.startsWith('Bearer ')) return json({ error: 'unauthorized' }, 401);

  let table = '';
  let op = '';
  let payload: Record<string, unknown> = {};
  let match: Record<string, unknown> = {};
  let reason: string | null = null;
  try {
    const body = await req.json();
    table = typeof body?.table === 'string' ? body.table : '';
    op = typeof body?.op === 'string' ? body.op : '';
    payload = body?.payload && typeof body.payload === 'object' ? body.payload : {};
    match = body?.match && typeof body.match === 'object' ? body.match : {};
    reason = typeof body?.reason === 'string' && body.reason.trim() ? body.reason.trim() : null;
  } catch {
    table = '';
  }
  if (!table) return json({ error: 'table required' }, 400);
  if (!['insert', 'update', 'delete'].includes(op)) return json({ error: 'invalid op' }, 400);
  if (!reason) return json({ error: 'reason required' }, 400);
  if (DENY_TABLES.includes(table)) {
    return json({ error: `table '${table}' is managed by a dedicated tool, not the console` }, 403);
  }
  if ((op === 'update' || op === 'delete') && Object.keys(match).length === 0) {
    return json({ error: 'match required for update/delete' }, 400);
  }

  const url = Deno.env.get('SUPABASE_URL')!;
  const userClient = createClient(url, Deno.env.get('SUPABASE_ANON_KEY')!, {
    global: { headers: { Authorization: authHeader } },
  });
  const admin = createClient(url, Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!);

  // النده = سوبر أدمن نشط.
  const { data: caller } = await userClient.auth.getUser();
  const callerUid = caller?.user?.id;
  if (!callerUid) return json({ error: 'unauthorized' }, 401);
  const { data: callerRow } = await admin
    .from('app_user').select('person_id').eq('auth_user_id', callerUid).maybeSingle();
  if (!callerRow) return json({ error: 'forbidden' }, 403);
  const callerPersonId = callerRow.person_id as string;
  const { data: callerPerson } = await admin
    .from('person').select('blocked_at, deactivated_at').eq('id', callerPersonId).maybeSingle();
  if (!callerPerson || callerPerson.blocked_at || callerPerson.deactivated_at) {
    return json({ error: 'forbidden' }, 403);
  }
  const { data: callerRoles } = await admin
    .from('role_assignment').select('role').eq('person_id', callerPersonId);
  if (!(callerRoles ?? []).some((r: { role: string }) => r.role === 'super_admin')) {
    return json({ error: 'forbidden' }, 403);
  }

  const clean = strip(payload);
  let opErr: { message?: string } | null = null;
  if (op === 'insert') {
    const { error } = await admin.from(table).insert(clean);
    opErr = error;
  } else if (op === 'update') {
    const { error } = await admin.from(table).update(clean).match(match);
    opErr = error;
  } else {
    const { error } = await admin.from(table).delete().match(match);
    opErr = error;
  }
  if (opErr) return json({ error: opErr.message ?? 'write failed' }, 400);

  await admin.from('audit_log').insert({
    actor_person_id: callerPersonId,
    action: `data_console_${op}`,
    target_table: table,
    target_id: typeof match?.id === 'string' ? match.id : null,
    meta: { reason, match, columns: Object.keys(clean) },
  });
  return json({ ok: true, table, op });
});
