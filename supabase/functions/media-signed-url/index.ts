// Edge Function: media-signed-url  —  ⚠️ مكتوبة، النشر متأجّل (نفس تدوير مفتاح
// الـ service-role المكشوف قبل أي نشر).
//
// بيرجّع رابطًا موقّتًا موقّعًا لعرض وسيط من الـ bucket الخاص. الصلاحية عبر RLS:
// لو المستخدم يقدر يقرا صف public.media (سياسة media_read بتفرض الدور + موافقة وسائط
// البنت) نوقّع الرابط بـ service-role. وبنسجّل الوصول في audit_log عبر الدالة العامة
// public.log_media_access.

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

Deno.serve(async (req: Request): Promise<Response> => {
  if (req.method !== 'POST') {
    return new Response('Method Not Allowed', { status: 405 });
  }

  const authHeader = req.headers.get('Authorization') ?? '';
  if (!authHeader.startsWith('Bearer ')) {
    return new Response('Unauthorized', { status: 401 });
  }

  let mediaId: string | null = null;
  try {
    const body = await req.json();
    mediaId = typeof body?.media_id === 'string' ? body.media_id : null;
  } catch {
    mediaId = null;
  }
  if (!mediaId) return new Response('Bad Request', { status: 400 });

  const userClient = createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_ANON_KEY')!,
    { global: { headers: { Authorization: authHeader } } },
  );

  // RLS: لو مش مسموح يشوف الصف مش هيرجع → 403.
  const { data: row, error } = await userClient
    .from('media')
    .select('storage_path')
    .eq('id', mediaId)
    .maybeSingle();
  if (error || !row) return new Response('Forbidden', { status: 403 });

  // سجّل الوصول (دالة عامة بتشتغل بهوية المستخدم).
  await userClient.rpc('log_media_access', { p_media_id: mediaId });

  const admin = createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
  );
  const signed = await admin.storage
    .from('media')
    .createSignedUrl(row.storage_path as string, 300);
  if (signed.error || !signed.data) {
    return new Response('Sign failed', { status: 500 });
  }

  return new Response(
    JSON.stringify({ url: signed.data.signedUrl }),
    { status: 200, headers: { 'Content-Type': 'application/json' } },
  );
});
