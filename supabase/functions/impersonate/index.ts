// Edge Function: impersonate  —  ⚠️ مكتوبة، النشر متأجّل (M6 D4).
// لازم قبل التفعيل: (1) تدوير مفتاح service-role المكشوف، (2) ضبط سرّ JWT في البيئة،
// (3) مراجعة أمنية، (4) التأكد إن المشروع بيوقّع JWT بـ HS256 (السرّ المشترك) مش
// بمفاتيح غير متماثلة (asymmetric). راجع docs/DEPLOY_RUNBOOK.md.
//
// M6 D4 — تقمّص كامل مدقّق (full, audited impersonation): السوبر أدمن يطلب التصرّف
// "كـ" مستخدم. السيرفر:
//   1) يتأكد إن النده سوبر أدمن (عبر service-role + person بتاعه، مش اعتماد على اتساع RLS).
//   2) يرفض تقمّص سوبر أدمن آخر.
//   3) يقفل أي جلسة فعّالة ويفتح صف impersonation_session جديد (تدقيق + توقيت).
//   4) يصدر JWT قصير (٣٠ دقيقة): sub = auth user بتاع الموضوع + claim مخصّص
//      act = { sub: <auth uid للسوبر أدمن>, sid: <session id> } للمساءلة.
//   5) يرجّع access_token؛ اللوحة تستخدمه فتشوفها الـ RLS كـ الموضوع
//      (is_super_admin=false، الكتابة منسوبة للموضوع، و act في الـ claims للتدقيق).
//
// التوقيع HS256 بسرّ JWT المشروع. PostgREST بيتحقّق بنفس السرّ فيقبل التوكن. الـ claim
// act مش بتستخدمه RLS — بس متاح في request.jwt.claims لو حبّينا تدقيق أعمق DB-side.

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const IMPERSONATION_TTL_SECONDS = 30 * 60;

function base64Url(data: Uint8Array | string): string {
  const bytes = typeof data === 'string' ? new TextEncoder().encode(data) : data;
  let binary = '';
  for (const b of bytes) binary += String.fromCharCode(b);
  return btoa(binary).replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/, '');
}

async function signHs256(payload: Record<string, unknown>, secret: string): Promise<string> {
  const header = { alg: 'HS256', typ: 'JWT' };
  const unsigned = `${base64Url(JSON.stringify(header))}.${base64Url(JSON.stringify(payload))}`;
  const key = await crypto.subtle.importKey(
    'raw',
    new TextEncoder().encode(secret),
    { name: 'HMAC', hash: 'SHA-256' },
    false,
    ['sign'],
  );
  const sig = new Uint8Array(
    await crypto.subtle.sign('HMAC', key, new TextEncoder().encode(unsigned)),
  );
  return `${unsigned}.${base64Url(sig)}`;
}

Deno.serve(async (req: Request): Promise<Response> => {
  if (req.method !== 'POST') return new Response('Method Not Allowed', { status: 405 });

  const authHeader = req.headers.get('Authorization') ?? '';
  if (!authHeader.startsWith('Bearer ')) return new Response('Unauthorized', { status: 401 });

  let subjectPersonId: string | null = null;
  let reason: string | null = null;
  try {
    const body = await req.json();
    subjectPersonId = typeof body?.subject_person_id === 'string' ? body.subject_person_id : null;
    reason = typeof body?.reason === 'string' && body.reason.trim() ? body.reason.trim() : null;
  } catch {
    subjectPersonId = null;
  }
  if (!subjectPersonId) return new Response('Bad Request', { status: 400 });

  const url = Deno.env.get('SUPABASE_URL')!;
  const userClient = createClient(url, Deno.env.get('SUPABASE_ANON_KEY')!, {
    global: { headers: { Authorization: authHeader } },
  });
  const admin = createClient(url, Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!);

  // 1) caller identity + super_admin check (by their own person id).
  const { data: caller } = await userClient.auth.getUser();
  const callerUid = caller?.user?.id;
  if (!callerUid) return new Response('Unauthorized', { status: 401 });

  const { data: callerRow } = await admin
    .from('app_user').select('person_id').eq('auth_user_id', callerUid).maybeSingle();
  if (!callerRow) return new Response('Forbidden', { status: 403 });
  const callerPersonId = callerRow.person_id as string;

  const { data: callerRoles } = await admin
    .from('role_assignment').select('role').eq('person_id', callerPersonId);
  if (!(callerRoles ?? []).some((r: { role: string }) => r.role === 'super_admin')) {
    return new Response('Forbidden', { status: 403 });
  }

  // كِل سويتش: التقمّص بالكتابة لازم يكون مفعّل صراحةً (مفتاح write_impersonation).
  const { data: flagRow } = await admin
    .from('feature_flag').select('enabled').eq('key', 'write_impersonation').maybeSingle();
  if (!flagRow?.enabled) {
    return new Response('write impersonation disabled', { status: 403 });
  }

  // 2) subject must not be a super_admin; resolve their auth user.
  const { data: subjectRoles } = await admin
    .from('role_assignment').select('role').eq('person_id', subjectPersonId);
  if ((subjectRoles ?? []).some((r: { role: string }) => r.role === 'super_admin')) {
    return new Response('Forbidden: cannot impersonate a super_admin', { status: 403 });
  }
  const { data: subjectUser } = await admin
    .from('app_user').select('auth_user_id').eq('person_id', subjectPersonId).maybeSingle();
  if (!subjectUser) return new Response('Subject has no login account', { status: 400 });
  const subjectUid = subjectUser.auth_user_id as string;

  // 3) close any active session for this admin, open a fresh audited one.
  await admin.from('impersonation_session')
    .update({ ended_at: new Date().toISOString() })
    .eq('super_admin_person_id', callerPersonId).is('ended_at', null);
  const { data: session, error: sessErr } = await admin
    .from('impersonation_session')
    .insert({ super_admin_person_id: callerPersonId, subject_person_id: subjectPersonId, reason })
    .select('id').single();
  if (sessErr || !session) return new Response('Failed to open session', { status: 500 });

  // تدقيق => بيشغّل تنبيه السوبر أدمن الفوري (trigger على audit_log).
  await admin.from('audit_log').insert({
    actor_person_id: callerPersonId,
    action: 'impersonation_started',
    target_table: 'impersonation_session',
    target_id: session.id,
    meta: { subject_person_id: subjectPersonId, reason },
  });

  // 4) mint a short-lived subject JWT carrying an `act` (actor) claim for accountability.
  const secret = Deno.env.get('SUPABASE_JWT_SECRET');
  if (!secret) return new Response('JWT secret not configured', { status: 500 });
  const now = Math.floor(Date.now() / 1000);
  const token = await signHs256({
    aud: 'authenticated',
    role: 'authenticated',
    sub: subjectUid,
    iat: now,
    exp: now + IMPERSONATION_TTL_SECONDS,
    act: { sub: callerUid, sid: session.id }, // who is really acting
  }, secret);

  return new Response(
    JSON.stringify({ access_token: token, expires_in: IMPERSONATION_TTL_SECONDS, session_id: session.id }),
    { status: 200, headers: { 'Content-Type': 'application/json' } },
  );
});
