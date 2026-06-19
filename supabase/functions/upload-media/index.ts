// Edge Function: upload-media  —  ⚠️ مكتوبة، النشر متأجّل لحد ما يتدوّر مفتاح
// الـ service-role المكشوف.
//
// المعلّم/الأدمن يرفع صورة/فيديو لطالب. البايتس بتوصل **معالَجة من الجهاز** (علامة
// مائية + ضغط)، فالـ Edge مابيعالجش (ffmpeg مش متاح في Deno Edge — القرار: معالجة
// على الجهاز). الأمان كله على RLS:
//   1) التخزين في الـ bucket الخاص "media" بـ service-role.
//   2) إدراج صف public.media **بهوية المستخدم** → سياسة media_write بتفرض الدور
//      (معلّم الحلقة/أدمن) + الموافقة (private.has_active_media_consent لوسائط البنت).
//      لو RLS رفض، بننظّف الملف المرفوع ونرجّع 403.
// الميتاداتا في query params والبايتس في جسم الطلب الخام (يناسب functions.invoke).
//
// أمان: SERVICE_ROLE_KEY بيتقري من بيئة الـ runtime بس وعمره ما يتكوميت؛ المفتاح
// اللي اتعرض قبل كده لازم يتدوّر (rotate) قبل أي نشر.

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

Deno.serve(async (req: Request): Promise<Response> => {
  if (req.method !== 'POST') {
    return new Response('Method Not Allowed', { status: 405 });
  }

  const authHeader = req.headers.get('Authorization') ?? '';
  if (!authHeader.startsWith('Bearer ')) {
    return new Response('Unauthorized', { status: 401 });
  }

  const url = new URL(req.url);
  const studentPersonId = url.searchParams.get('student_person_id');
  const mediaType = url.searchParams.get('type'); // 'photo' | 'video'
  const watermarked = url.searchParams.get('watermarked') === 'true';
  if (!studentPersonId || (mediaType !== 'photo' && mediaType !== 'video')) {
    return new Response('Bad Request', { status: 400 });
  }

  const bytes = new Uint8Array(await req.arrayBuffer());
  if (bytes.length === 0) return new Response('Bad Request', { status: 400 });

  const userClient = createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_ANON_KEY')!,
    { global: { headers: { Authorization: authHeader } } },
  );
  const admin = createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!, // runtime فقط — اتدوّر المفتاح المكشوف
  );

  const ext = mediaType === 'video' ? 'mp4' : 'jpg';
  const contentType = mediaType === 'video' ? 'video/mp4' : 'image/jpeg';
  const path = `${studentPersonId}/${crypto.randomUUID()}.${ext}`;

  // 1) خزّن البايتس في الـ bucket الخاص (service-role).
  const up = await admin.storage.from('media').upload(path, bytes, {
    contentType,
    upsert: false,
  });
  if (up.error) return new Response('Upload failed', { status: 500 });

  // 2) أدرج الصف بهوية المستخدم → RLS بتفرض الدور + الموافقة. التنظيف لو اترفض.
  const ins = await userClient.from('media').insert({
    student_person_id: studentPersonId,
    type: mediaType,
    storage_path: path,
    watermarked,
  });
  if (ins.error) {
    await admin.storage.from('media').remove([path]);
    return new Response(
      JSON.stringify({ error: 'forbidden_or_consent_required' }),
      { status: 403, headers: { 'Content-Type': 'application/json' } },
    );
  }

  return new Response(
    JSON.stringify({ ok: true, path }),
    { status: 200, headers: { 'Content-Type': 'application/json' } },
  );
});
