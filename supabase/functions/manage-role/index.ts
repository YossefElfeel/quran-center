// Edge Function: manage-role  —  ⚠️ مكتوبة، النشر متأجّل. راجع docs/DEPLOY_RUNBOOK.md
// (تدوير مفتاح service-role المكشوف قبل التفعيل).
//
// منح/سحب أي دور لأي مستخدم (سوبر أدمن فقط، مدقّق). اخترنا Edge function بدل كتابة RLS
// مباشرة عشان: (أ) حاجز "آخر سوبر أدمن" محتاج COUNT عبر صفوف (مش ممكن في policy صف-صف)،
// (ب) اتساق التدقيق مع block/delete، (ج) منع سحب السوبر أدمن من نفسك في مكان واحد.
// trigger enforce_last_super_admin في الـ DB بيضمن الثبات حتى من SQL editor.

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const ROLES = ['super_admin', 'admin', 'supervisor', 'teacher', 'parent'];

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
  let role: string | null = null;
  let op: 'grant' | 'revoke' = 'grant';
  try {
    const body = await req.json();
    targetPersonId = typeof body?.target_person_id === 'string' ? body.target_person_id : null;
    role = typeof body?.role === 'string' ? body.role : null;
    if (body?.op === 'revoke') op = 'revoke';
  } catch {
    targetPersonId = null;
  }
  if (!targetPersonId) return json({ error: 'target_person_id required' }, 400);
  if (!role || !ROLES.includes(role)) return json({ error: 'valid role required' }, 400);

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

  // الهدف موجود.
  const { data: target } = await admin
    .from('person').select('id').eq('id', targetPersonId).maybeSingle();
  if (!target) return json({ error: 'target not found' }, 404);

  // حواجز السوبر أدمن: مينفعش تسحب السوبر أدمن من نفسك. حماية "آخر سوبر أدمن نشط"
  // بيفرضها trigger enforce_last_super_admin (بيعدّ النشطين بس) ونمسكها كـ 23514 تحت —
  // فمصدر حقيقة واحد، من غير عدّ ثاني هنا ممكن يختلف عنه.
  if (op === 'revoke' && role === 'super_admin' && targetPersonId === callerPersonId) {
    return json({ error: 'cannot revoke your own super_admin' }, 403);
  }

  if (op === 'grant') {
    const { error } = await admin
      .from('role_assignment')
      .upsert({ person_id: targetPersonId, role }, { onConflict: 'person_id,role', ignoreDuplicates: true });
    if (error) return json({ error: 'grant failed' }, 500);
  } else {
    const { error } = await admin
      .from('role_assignment').delete().eq('person_id', targetPersonId).eq('role', role);
    if (error) {
      // trigger enforce_last_super_admin (23514) أو غيره.
      const code = (error as { code?: string }).code;
      if (code === '23514') return json({ error: 'cannot remove the last super_admin' }, 409);
      return json({ error: 'revoke failed' }, 500);
    }
  }

  await admin.from('audit_log').insert({
    actor_person_id: callerPersonId,
    action: op === 'grant' ? 'role_granted' : 'role_revoked',
    target_table: 'role_assignment',
    target_id: targetPersonId,
    meta: { role },
  });
  return json({ ok: true, target_person_id: targetPersonId, role, op });
});
