// Admin-only invitations; links are returned for sharing, generateLink does not send email.
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.108.2';

interface InviteBody {
  email: string;
  full_name: string;
  role: 'parent' | 'teacher' | 'supervisor' | 'admin';
  existing_person_id?: string;
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

  let body: InviteBody;
  try { body = await req.json(); } catch { return new Response('Invalid JSON', { status: 400 }); }
  const webUrl = (Deno.env.get('WEB_URL') ?? 'https://quran-web-sage.vercel.app').replace(/\/$/, '');
  if (!webUrl || !/^https?:\/\//.test(webUrl)) return new Response('WEB_URL not configured', { status: 500 });
  if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(body.email ?? '') || !body.full_name?.trim() || !['parent', 'teacher', 'supervisor', 'admin'].includes(body.role)) {
    return new Response('Bad Request', { status: 400 });
  }

  // عميل سيرفر (service-role) للكتابة الموثوقة + إنشاء الحساب.
  const admin = createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!, // runtime فقط — مفتاح مدوّر
  );

  let personId = body.existing_person_id;
  // Existing identities must already have the requested role. Never grant roles here.
  if (personId) {
    const { data: person } = await admin.from('person').select('id, is_minor, blocked_at, deactivated_at').eq('id', personId).maybeSingle();
    const { data: role } = await admin.from('role_assignment').select('role').eq('person_id', personId).eq('role', body.role).maybeSingle();
    if (!person || person.is_minor || person.blocked_at || person.deactivated_at || !role) return new Response('Invalid existing person', { status: 400 });
    const { data: login } = await admin.from('app_user').select('auth_user_id').eq('person_id', personId).maybeSingle();
    if (login) return new Response('Person already has a login', { status: 409 });
    if (body.role === 'parent') {
      const { data: member } = await admin.from('household_member').select('person_id').eq('person_id', personId).maybeSingle();
      const { data: children } = await admin.from('guardian_link').select('student_person_id').eq('guardian_person_id', personId).limit(1);
      if (!member || !children?.length) return new Response('Parent needs a household and child link', { status: 400 });
    }
  } else if (body.role === 'parent') {
    return new Response('Create parents through the family flow', { status: 400 });
  }

  // 4) رابط دعوة (بينشئ auth user) + ربط app_user.
  const { data: linkData, error: linkErr } = await admin.auth.admin.generateLink({
    type: 'invite',
    email: body.email.trim(),
    options: { redirectTo: `${webUrl}/auth/confirm` },
  });
  if (linkErr || !linkData?.user) return new Response('invite link failed', { status: 500 });

  if (!linkData.properties?.action_link) {await admin.auth.admin.deleteUser(linkData.user.id);return new Response('invite link missing',{status:500});}
  if (!personId) {
    const { data: person, error } = await admin.from('person').insert({ full_name: body.full_name.trim(), is_minor: false }).select('id').single();
    if (error || !person) { await admin.auth.admin.deleteUser(linkData.user.id); return new Response('person insert failed', { status: 500 }); }
    personId = person.id;
    const { error: roleError } = await admin.from('role_assignment').insert({ person_id: personId, role: body.role });
    if (roleError) { await admin.from('person').delete().eq('id', personId); await admin.auth.admin.deleteUser(linkData.user.id); return new Response('role insert failed', { status: 500 }); }
  }

  const { error: auErr } = await admin
    .from('app_user')
    .insert({ auth_user_id: linkData.user.id, person_id: personId });
  if (auErr) {
    await admin.auth.admin.deleteUser(linkData.user.id);
    if (!body.existing_person_id) {
      await admin.from('role_assignment').delete().eq('person_id', personId);
      await admin.from('person').delete().eq('id', personId);
    }
    return new Response('app_user link failed', { status: 500 });
  }

  return new Response(
    JSON.stringify({
      ok: true,
      person_id: personId,
      action_link: linkData.properties?.action_link, // يتبعت للمستخدم (واتساب/إيميل لاحقًا)
    }),
    { status: 200, headers: { 'Content-Type': 'application/json' } },
  );
});
