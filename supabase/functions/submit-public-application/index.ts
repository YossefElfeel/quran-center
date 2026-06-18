// Edge Function: submit-public-application  —  ⚠️ SCAFFOLD، لسه ماتنشرش.
//
// الغرض: الصفحة العامة (Flutter Web) — أي حد يقدّم للمسابقة بتسجيل بسيط
// (اسم + موبايل + إقرار موافقة)، من غير حساب كامل. السيرفر:
//   1) يرفض من غير consent_ack=true.
//   2) يتأكد إن المسابقة مفتوحة (status='open').
//   3) يطبّع الموبايل ويمنع التكرار لنفس المسابقة (competition, normalized_phone).
//   4) ينشئ public_registration + competition_application(origin='public').
//
// ⚠️ بيستخدم service-role (الجداول دي RLS = أدمن بس). النشر بعد تدوير المفتاح
//    المكشوف. rate-limit/OTP على بوابة الـ Edge قبل الإنتاج (مكافحة السبام).

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

interface Body {
  competition_id: string;
  category_id?: string;
  name: string;
  phone: string;
  consent_ack: boolean;
  youtube_url?: string;
}

Deno.serve(async (req: Request): Promise<Response> => {
  if (req.method !== 'POST') return new Response('Method Not Allowed', { status: 405 });
  const b = (await req.json()) as Body;
  if (!b.competition_id || !b.name || !b.phone || b.consent_ack !== true) {
    return new Response('Bad Request (consent required)', { status: 400 });
  }

  const admin = createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!, // runtime فقط — مفتاح مدوّر
  );

  // 2) المسابقة لازم تكون مفتوحة.
  const { data: comp } = await admin
    .from('competition')
    .select('status')
    .eq('id', b.competition_id)
    .maybeSingle();
  if (!comp || comp.status !== 'open') {
    return new Response('competition not open', { status: 409 });
  }

  // 3) تطبيع الموبايل + منع التكرار لنفس المسابقة.
  const normalized = b.phone.replace(/\D/g, '');
  const { data: dupe } = await admin
    .from('competition_application')
    .select('id, public_registration:public_registration_id(normalized_phone)')
    .eq('competition_id', b.competition_id)
    .eq('origin', 'public');
  const already = (dupe ?? []).some(
    (r: { public_registration?: { normalized_phone?: string } }) =>
      r.public_registration?.normalized_phone === normalized,
  );
  if (already) return new Response('already applied', { status: 409 });

  // 4) إنشاء التسجيل + الطلب.
  const { data: reg, error: regErr } = await admin
    .from('public_registration')
    .insert({ name: b.name, phone: b.phone, normalized_phone: normalized, consent_ack: true })
    .select('id')
    .single();
  if (regErr || !reg) return new Response('registration failed', { status: 500 });

  const { error: appErr } = await admin.from('competition_application').insert({
    competition_id: b.competition_id,
    category_id: b.category_id ?? null,
    origin: 'public',
    public_registration_id: reg.id,
    youtube_url: b.youtube_url ?? null,
  });
  if (appErr) return new Response('application failed', { status: 500 });

  return new Response(
    JSON.stringify({ ok: true }),
    { status: 200, headers: { 'Content-Type': 'application/json' } },
  );
});
