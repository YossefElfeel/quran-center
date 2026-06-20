// Edge Function: reset-password  —  ⚠️ مكتوبة، النشر متأجّل. راجع docs/DEPLOY_RUNBOOK.md
// (تدوير مفتاح service-role المكشوف قبل التفعيل).
//
// توليد رابط استرجاع كلمة السر لمستخدم (سوبر أدمن فقط، مدقّق). نفس نمط invite-user:
// السيرفر بيتأكد إن النده سوبر أدمن نشط عبر service-role، بيجيب إيميل الموضوع، بيولّد
// رابط recovery عبر Auth Admin API (مابيبعتش — بيرجّع الرابط للأدمن يبعته بنفسه)، وبيسجّل
// في audit_log (action = password_reset_link). مابنتعاملش مع كلمة السر الخام إطلاقًا.

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

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
  let reason: string | null = null;
  try {
    const body = await req.json();
    targetPersonId = typeof body?.target_person_id === 'string' ? body.target_person_id : null;
    reason = typeof body?.reason === 'string' && body.reason.trim() ? body.reason.trim() : null;
  } catch {
    targetPersonId = null;
  }
  if (!targetPersonId) return json({ error: 'target_person_id required' }, 400);
  if (!reason) return json({ error: 'reason required' }, 400);

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

  // إيميل الموضوع (من حساب الدخول).
  const { data: targetUser } = await admin
    .from('app_user').select('auth_user_id').eq('person_id', targetPersonId).maybeSingle();
  const targetUid = targetUser?.auth_user_id as string | undefined;
  if (!targetUid) return json({ error: 'subject has no login account' }, 400);

  const { data: authUser } = await admin.auth.admin.getUserById(targetUid);
  const email = authUser?.user?.email;
  if (!email) return json({ error: 'subject has no email' }, 400);

  const { data: link, error: linkErr } = await admin.auth.admin.generateLink({
    type: 'recovery',
    email,
  });
  if (linkErr) return json({ error: 'failed to generate link' }, 500);

  await admin.from('audit_log').insert({
    actor_person_id: callerPersonId,
    action: 'password_reset_link',
    target_table: 'person',
    target_id: targetPersonId,
    meta: { reason },
  });

  return json({ ok: true, action_link: link?.properties?.action_link ?? null });
});
