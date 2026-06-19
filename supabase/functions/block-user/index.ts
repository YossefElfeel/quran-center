// Edge Function: block-user  —  ⚠️ مكتوبة، النشر متأجّل. راجع docs/DEPLOY_RUNBOOK.md
// (تدوير مفتاح service-role المكشوف قبل التفعيل).
//
// حظر/فك حظر مستخدم (سوبر أدمن فقط، مدقّق). نفس نمط impersonate:
//   1) التأكد إن النده سوبر أدمن "نشط" عبر service-role (مش اعتماد على RLS).
//   2) حواجز: لا تحظر نفسك، السبب مطلوب، لا تحظر آخر سوبر أدمن نشط.
//   3) الحظر = رفع علم person.blocked_at أولًا (قفل RLS فوري) + ban على مستوى Auth
//      (يمنع التحديث/الدخول). التوكن المتبقّي (≤ساعة) أصلًا بيترفض من RLS لأن
//      current_person_id()/has_role() بترجع NULL/false للمحظور.
//   4) تسجيل في audit_log.

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const LONG_BAN = '876000h'; // ~100 سنة

function json(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { 'Content-Type': 'application/json' },
  });
}

Deno.serve(async (req: Request): Promise<Response> => {
  if (req.method !== 'POST') return json({ error: 'method_not_allowed' }, 405);

  const authHeader = req.headers.get('Authorization') ?? '';
  if (!authHeader.startsWith('Bearer ')) return json({ error: 'unauthorized' }, 401);

  let targetPersonId: string | null = null;
  let block = true;
  let reason: string | null = null;
  try {
    const body = await req.json();
    targetPersonId = typeof body?.target_person_id === 'string' ? body.target_person_id : null;
    block = body?.block !== false; // الافتراضي: حظر
    reason = typeof body?.reason === 'string' && body.reason.trim() ? body.reason.trim() : null;
  } catch {
    targetPersonId = null;
  }
  if (!targetPersonId) return json({ error: 'target_person_id required' }, 400);
  if (block && !reason) return json({ error: 'reason required' }, 400);

  const url = Deno.env.get('SUPABASE_URL')!;
  const userClient = createClient(url, Deno.env.get('SUPABASE_ANON_KEY')!, {
    global: { headers: { Authorization: authHeader } },
  });
  const admin = createClient(url, Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!);

  // 1) النده = سوبر أدمن نشط.
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

  // 2) حواجز.
  if (targetPersonId === callerPersonId) return json({ error: 'cannot block yourself' }, 403);
  const { data: target } = await admin
    .from('person').select('id').eq('id', targetPersonId).maybeSingle();
  if (!target) return json({ error: 'target not found' }, 404);

  if (block) {
    const { data: targetRoles } = await admin
      .from('role_assignment').select('role').eq('person_id', targetPersonId);
    if ((targetRoles ?? []).some((r: { role: string }) => r.role === 'super_admin')) {
      const { data: supers } = await admin
        .from('role_assignment')
        .select('person_id, person:person_id(blocked_at, deactivated_at)')
        .eq('role', 'super_admin');
      const activeOthers = (supers ?? []).filter((r: {
        person_id: string;
        person: { blocked_at: string | null; deactivated_at: string | null } | null;
      }) => r.person_id !== targetPersonId && !r.person?.blocked_at && !r.person?.deactivated_at);
      if (activeOthers.length === 0) return json({ error: 'cannot block the last super_admin' }, 409);
    }
  }

  // قد لا يكون للموضوع حساب دخول (طالب/طفل) — وقتها العلم في person هو كل التأثير.
  const { data: targetUser } = await admin
    .from('app_user').select('auth_user_id').eq('person_id', targetPersonId).maybeSingle();
  const targetUid = targetUser?.auth_user_id as string | undefined;

  if (block) {
    const { error: upErr } = await admin.from('person').update({
      blocked_at: new Date().toISOString(),
      blocked_by: callerPersonId,
      blocked_reason: reason,
    }).eq('id', targetPersonId);
    if (upErr) return json({ error: 'update failed' }, 500);

    if (targetUid) {
      await admin.auth.admin.updateUserById(targetUid, { ban_duration: LONG_BAN });
    }
    await admin.from('audit_log').insert({
      actor_person_id: callerPersonId,
      action: 'user_blocked',
      target_table: 'person',
      target_id: targetPersonId,
      meta: { reason },
    });
    return json({ ok: true, target_person_id: targetPersonId, blocked: true });
  }

  // فك الحظر.
  const { error: upErr } = await admin.from('person').update({
    blocked_at: null,
    blocked_by: null,
    blocked_reason: null,
  }).eq('id', targetPersonId);
  if (upErr) return json({ error: 'update failed' }, 500);

  if (targetUid) {
    await admin.auth.admin.updateUserById(targetUid, { ban_duration: 'none' });
  }
  await admin.from('audit_log').insert({
    actor_person_id: callerPersonId,
    action: 'user_unblocked',
    target_table: 'person',
    target_id: targetPersonId,
    meta: { reason },
  });
  return json({ ok: true, target_person_id: targetPersonId, blocked: false });
});
