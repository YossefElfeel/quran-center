// Edge Function: delete-user  —  ⚠️ مكتوبة، النشر متأجّل. راجع docs/DEPLOY_RUNBOOK.md
// (تدوير مفتاح service-role المكشوف قبل التفعيل).
//
// حذف مستخدم (سوبر أدمن فقط، مدقّق). ثلاث أوضاع:
//   - soft:    إيقاف ناعم (deactivated_at) + ban. بيحفظ كل السجلّ الأكاديمي/المالي. قابل للعكس.
//   - restore: استرجاع موقوف (مسح deactivated_at) + فك ban.
//   - hard:    حذف نهائي. لازم confirm == الاسم الكامل. بنفصل المراجع اللي من غير cascade
//              (audit_log.actor_person_id, system_settings.updated_by, impersonation_session)
//              قبل الحذف، وإلا الـ FK بيوقف الـ cascade. لو فيه سجلّ مرتبط تاني بيمنع الحذف
//              بنرجّع 409 ونقترح الإيقاف الناعم.
//
// حواجز مشتركة: السبب مطلوب، لا تحذف نفسك، حماية آخر سوبر أدمن نشط.

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const LONG_BAN = '876000h';

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
  let mode: 'soft' | 'hard' | 'restore' = 'soft';
  let reason: string | null = null;
  let confirm: string | null = null;
  try {
    const body = await req.json();
    targetPersonId = typeof body?.target_person_id === 'string' ? body.target_person_id : null;
    if (body?.mode === 'hard' || body?.mode === 'restore') mode = body.mode;
    reason = typeof body?.reason === 'string' && body.reason.trim() ? body.reason.trim() : null;
    confirm = typeof body?.confirm === 'string' ? body.confirm.trim() : null;
  } catch {
    targetPersonId = null;
  }
  if (!targetPersonId) return json({ error: 'target_person_id required' }, 400);
  if (mode !== 'restore' && !reason) return json({ error: 'reason required' }, 400);

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

  // حواجز.
  if (targetPersonId === callerPersonId) return json({ error: 'cannot delete yourself' }, 403);
  const { data: target } = await admin
    .from('person').select('id, full_name').eq('id', targetPersonId).maybeSingle();
  if (!target) return json({ error: 'target not found' }, 404);

  const { data: targetUser } = await admin
    .from('app_user').select('auth_user_id').eq('person_id', targetPersonId).maybeSingle();
  const targetUid = targetUser?.auth_user_id as string | undefined;

  // حماية آخر سوبر أدمن نشط (soft/hard، مش restore).
  if (mode !== 'restore') {
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
      if (activeOthers.length === 0) return json({ error: 'cannot delete the last super_admin' }, 409);
    }
  }

  // ---- restore ----
  if (mode === 'restore') {
    const { error } = await admin.from('person').update({
      deactivated_at: null, deactivated_by: null, deactivated_reason: null,
    }).eq('id', targetPersonId);
    if (error) return json({ error: 'update failed' }, 500);
    if (targetUid) await admin.auth.admin.updateUserById(targetUid, { ban_duration: 'none' });
    await admin.from('audit_log').insert({
      actor_person_id: callerPersonId, action: 'user_restored',
      target_table: 'person', target_id: targetPersonId, meta: { reason },
    });
    return json({ ok: true, mode, target_person_id: targetPersonId });
  }

  // ---- soft (إيقاف ناعم) ----
  if (mode === 'soft') {
    const { error } = await admin.from('person').update({
      deactivated_at: new Date().toISOString(),
      deactivated_by: callerPersonId,
      deactivated_reason: reason,
    }).eq('id', targetPersonId);
    if (error) return json({ error: 'update failed' }, 500);
    if (targetUid) await admin.auth.admin.updateUserById(targetUid, { ban_duration: LONG_BAN });
    await admin.from('audit_log').insert({
      actor_person_id: callerPersonId, action: 'user_soft_deleted',
      target_table: 'person', target_id: targetPersonId, meta: { reason },
    });
    return json({ ok: true, mode, target_person_id: targetPersonId });
  }

  // ---- hard (حذف نهائي) ----
  if (!confirm || confirm !== (target.full_name as string)) {
    return json({ error: 'confirm must equal full_name' }, 400);
  }
  // لقطة للتدقيق (الصف على وشك يختفي؛ audit_log.target_id مفيهوش FK لـ person،
  // و actor = النده اللي لسه موجود — فالصف بيفضل صالح بعد الحذف).
  const { data: roles } = await admin
    .from('role_assignment').select('role').eq('person_id', targetPersonId);
  const snapshot = {
    reason,
    full_name: target.full_name,
    had_login: !!targetUid,
    roles: (roles ?? []).map((r: { role: string }) => r.role),
  };

  // حذف الـ person نفسه: بيعمل cascade للـ app_user + role_assignment + كل أبناء الطالب
  // (enrollment/daily_tasmee/attendance/media/...) عبر FK بـ ON DELETE CASCADE.
  // لو الشخص مرجوع له كـ "فاعل" من غير cascade (معلّم سجّل تسميع، محكّم، مُصدِر شهادة...)
  // الـ FK بيمنع الحذف => 409 ونقترح الإيقاف الناعم (الأنسب لحفظ التاريخ). مفيش فصل مراجع
  // مسبق عشان حذف اتمنع ما يسيبش ضرر جانبي.
  const { error: delErr } = await admin.from('person').delete().eq('id', targetPersonId);
  if (delErr) {
    return json({
      error: 'cannot hard-delete: user has linked history. Use soft delete (deactivate) instead.',
    }, 409);
  }
  // الـ person اتشال (والـ app_user معاه عبر cascade) — نشيل حساب الدخول اليتيم كمان.
  if (targetUid) {
    await admin.auth.admin.deleteUser(targetUid);
  }

  await admin.from('audit_log').insert({
    actor_person_id: callerPersonId, action: 'user_hard_deleted',
    target_table: 'person', target_id: targetPersonId, meta: snapshot,
  });
  return json({ ok: true, mode, target_person_id: targetPersonId });
});
