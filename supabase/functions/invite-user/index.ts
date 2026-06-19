// Edge Function: invite-user  —  ⚠️ SCAFFOLD، لسه ماتنشرش (deploy متأجّل).
//
// الغرض: الأدمن يدعو مستخدم (ولي أمر / معلّم / مشرف) — مفيش self-signup مفتوح.
// الفلو:
//   1) التأكد إن النده أدمن (is_admin) — غير كده 403.
//   2) إنشاء/إيجاد Person + role_assignment بالدور المطلوب.
//   3) (لولي الأمر) ربط guardian_link بالأطفال.
//   4) توليد رابط دعوة (invite link) — Supabase بينشئ auth user ويبعت لينك
//      يكمّل بيه الباسورد. وربط app_user(auth_user_id → person_id).
//
// ⚠️ أمان مهم:
//   - الـ service-role key بيتقري من env في runtime الـ Edge بس، وعمره ما
//     يتكوميت أو يتحط في الكلاينت.
//   - المفتاح السري اللي اتعرض في الشات قبل كده **لازم يتدوّر (rotate)** من
//     لوحة Supabase قبل أي نشر. مفيش إنشاء حسابات بالمفتاح المكشوف.
//   - النشر: `supabase functions deploy invite-user` بعد ضبط الـ secrets:
//     SUPABASE_URL / SUPABASE_ANON_KEY / SUPABASE_SERVICE_ROLE_KEY (المدوّر).

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

interface InviteBody {
  email: string;
  full_name: string;
  role: 'parent' | 'teacher' | 'supervisor' | 'admin';
  child_person_ids?: string[]; // لولي الأمر
}

Deno.serve(async (req: Request): Promise<Response> => {
  if (req.method !== 'POST') return new Response('Method Not Allowed', { status: 405 });

  const authHeader = req.headers.get('Authorization') ?? '';
  if (!authHeader.startsWith('Bearer ')) return new Response('Unauthorized', { status: 401 });

  // 1) لازم النده يكون أدمن أو سوبر أدمن. بنفحص أدواره مباشرةً عبر RLS (قراءة
  //    أدواره هو) بدل rpc('is_admin') — لأن دوال is_* اتنقلت لـ schema private
  //    (M2.3) فمابقتش متاحة كـ RPC عبر PostgREST، وكمان عشان نشمل super_admin.
  const caller = createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_ANON_KEY')!,
    { global: { headers: { Authorization: authHeader } } },
  );
  const { data: callerAuth } = await caller.auth.getUser();
  const callerUserId = callerAuth?.user?.id;
  if (!callerUserId) return new Response('Unauthorized', { status: 401 });

  const { data: callerAppUser } = await caller
    .from('app_user')
    .select('person_id')
    .eq('auth_user_id', callerUserId)
    .maybeSingle();
  const callerPersonId = callerAppUser?.person_id as string | undefined;
  if (!callerPersonId) return new Response('Forbidden', { status: 403 });

  const { data: callerRoles } = await caller
    .from('role_assignment')
    .select('role')
    .eq('person_id', callerPersonId);
  const allowed = (callerRoles ?? []).some(
    (r: { role: string }) => r.role === 'admin' || r.role === 'super_admin',
  );
  if (!allowed) return new Response('Forbidden', { status: 403 });

  const body = (await req.json()) as InviteBody;
  if (!body.email || !body.full_name || !body.role) {
    return new Response('Bad Request', { status: 400 });
  }

  // عميل سيرفر (service-role) للكتابة الموثوقة + إنشاء الحساب.
  const admin = createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!, // runtime فقط — مفتاح مدوّر
  );

  // 2) Person + role_assignment.
  const { data: person, error: pErr } = await admin
    .from('person')
    .insert({ full_name: body.full_name, is_minor: false })
    .select('id')
    .single();
  if (pErr || !person) return new Response('person insert failed', { status: 500 });

  const { error: rErr } = await admin
    .from('role_assignment')
    .insert({ person_id: person.id, role: body.role });
  if (rErr) return new Response('role insert failed', { status: 500 });

  // 3) ربط الأطفال (لولي الأمر).
  if (body.role === 'parent' && body.child_person_ids?.length) {
    const links = body.child_person_ids.map((sid) => ({
      guardian_person_id: person.id,
      student_person_id: sid,
    }));
    const { error: glErr } = await admin.from('guardian_link').insert(links);
    if (glErr) return new Response('guardian_link insert failed', { status: 500 });
  }

  // 4) رابط دعوة (بينشئ auth user) + ربط app_user.
  const { data: linkData, error: linkErr } = await admin.auth.admin.generateLink({
    type: 'invite',
    email: body.email,
  });
  if (linkErr || !linkData?.user) return new Response('invite link failed', { status: 500 });

  const { error: auErr } = await admin
    .from('app_user')
    .insert({ auth_user_id: linkData.user.id, person_id: person.id });
  if (auErr) return new Response('app_user link failed', { status: 500 });

  return new Response(
    JSON.stringify({
      ok: true,
      person_id: person.id,
      action_link: linkData.properties?.action_link, // يتبعت للمستخدم (واتساب/إيميل لاحقًا)
    }),
    { status: 200, headers: { 'Content-Type': 'application/json' } },
  );
});
