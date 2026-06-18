// Edge Function: upload-media  —  ⚠️ SCAFFOLD، لسه ماتنشرش (deploy متأجّل).
//
// الغرض: المعلّم/الأدمن يرفع صورة/فيديو لطالب. السيرفر هو اللي:
//   1) يتأكد من هوية الرافع (JWT) ودوره (معلّم الحلقة / أدمن) — عبر RLS/RPC.
//   2) يرفض وسائط البنت من غير موافقة نشطة (public.media_consent_ok).
//   3) (TODO) يحط علامة مائية ويضغط الفيديو قبل التخزين.
//   4) يخزّن في bucket "media" الخاص ويسجّل صف في public.media.
//
// مهم (أمان): الـ service-role key بيتقري من متغيّر بيئة في رuntime الـ Edge بس،
// وعمره ما يتحط في الكلاينت أو يتكوميت. المفتاح اللي اتعرض قبل كده لازم يتدوّر
// (rotate) قبل أي نشر حقيقي. مفيش إنشاء حسابات/مفاتيح بالمفتاح المكشوف.

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

Deno.serve(async (req: Request): Promise<Response> => {
  if (req.method !== 'POST') {
    return new Response('Method Not Allowed', { status: 405 });
  }

  const authHeader = req.headers.get('Authorization') ?? '';
  if (!authHeader.startsWith('Bearer ')) {
    return new Response('Unauthorized', { status: 401 });
  }

  // عميل بهوية المستخدم (الـ RLS بتتطبّق عليه) — للتأكد إنه مصرّح والموافقة موجودة.
  const userClient = createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_ANON_KEY')!,
    { global: { headers: { Authorization: authHeader } } },
  );

  const form = await req.formData();
  const file = form.get('file') as File | null;
  const studentPersonId = form.get('student_person_id') as string | null;
  const mediaType = form.get('type') as string | null; // 'photo' | 'video'
  if (!file || !studentPersonId || (mediaType !== 'photo' && mediaType !== 'video')) {
    return new Response('Bad Request', { status: 400 });
  }

  // بوابة الموافقة (بتشتغل للبنت؛ الولد بيعدّي): نفس الدالة اللي الـ RLS بتستخدمها.
  const { data: allowed, error: consentErr } = await userClient.rpc(
    'media_consent_ok',
    { p_student: studentPersonId, p_type: mediaType },
  );
  if (consentErr) return new Response('Forbidden', { status: 403 });
  if (allowed !== true) {
    return new Response(
      JSON.stringify({ error: 'consent_required' }),
      { status: 403, headers: { 'Content-Type': 'application/json' } },
    );
  }

  // TODO: watermark + compress (الفيديو) قبل التخزين — مكتبة معالجة في الـ runtime.
  const bytes = new Uint8Array(await file.arrayBuffer());
  const ext = mediaType === 'video' ? 'mp4' : 'jpg';
  const path = `${studentPersonId}/${crypto.randomUUID()}.${ext}`;

  // عميل سيرفر (service-role) للتخزين الخاص + الإدراج الموثوق.
  const admin = createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!, // runtime فقط — اتدوّر المفتاح المكشوف
  );
  const up = await admin.storage.from('media').upload(path, bytes, {
    contentType: file.type,
    upsert: false,
  });
  if (up.error) return new Response('Upload failed', { status: 500 });

  const ins = await admin.from('media').insert({
    student_person_id: studentPersonId,
    type: mediaType,
    storage_path: path,
    watermarked: false, // TODO: true بعد ما الـ watermark يتعمل
  });
  if (ins.error) return new Response('DB insert failed', { status: 500 });

  return new Response(
    JSON.stringify({ ok: true, path }),
    { status: 200, headers: { 'Content-Type': 'application/json' } },
  );
});
