import { logError,logInfo } from '../_shared/log.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.108.2';
const origins = (Deno.env.get('ALLOWED_ORIGINS') ?? 'https://quran-web-sage.vercel.app,http://localhost:3000,http://127.0.0.1:3000').split(',');
const normalize = (text: string) => text.replace(/[٠-٩۰-۹]/g, char => String(char.charCodeAt(0) - (char.charCodeAt(0) >= 0x6f0 ? 0x6f0 : 0x660)));
Deno.serve(async (req: Request): Promise<Response> => {
  const origin = req.headers.get('origin') ?? '';
  const headers = { 'Content-Type': 'application/json', 'Access-Control-Allow-Origin': origins.includes(origin) ? origin : origins[0], 'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type', 'Access-Control-Allow-Methods': 'POST, OPTIONS', 'Vary': 'Origin' };
  const json = (body: unknown, status = 200) => new Response(JSON.stringify(body), { status, headers });
  if (origin && !origins.includes(origin)) return json({ error: 'origin not allowed' }, 403);
  if (req.method === 'OPTIONS') return new Response(null, { status: 204, headers });
  if (req.method !== 'POST') return json({ error: 'method not allowed' }, 405);
  let body: { competition_id?: string; name?: string; phone?: string; consent_ack?: boolean; youtube_url?: string; category_id?: string };
  try { body = await req.json(); } catch { return json({ error: 'invalid JSON' }, 400); }
  if (typeof body.name !== 'string' || body.name.trim().length < 2 || body.name.length > 200 || typeof body.phone !== 'string' || body.consent_ack !== true || !body.competition_id) return json({ error: 'invalid details or missing consent' }, 400);
  const phone = normalize(body.phone).replace(/[\s()-]/g, '');
  if (!/^\+?[0-9]{10,15}$/.test(phone)) return json({ error: 'invalid phone' }, 400);
  if (body.youtube_url) {
    try { const url = new URL(body.youtube_url); if (!['http:', 'https:'].includes(url.protocol) || !['youtube.com','m.youtube.com','youtu.be','youtube-nocookie.com'].includes(url.hostname.replace(/^www\./,''))) throw new Error(); }
    catch { return json({ error: 'invalid YouTube URL' }, 400); }
  }
  const admin = createClient(Deno.env.get('SUPABASE_URL')!, Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!);
  const { data, error } = await admin.rpc('submit_public_competition_application', { p_competition_id: body.competition_id, p_name: body.name.trim(), p_phone: phone, p_normalized_phone: phone.replace(/\D/g,''), p_youtube_url: body.youtube_url || null, p_consent: true, p_category_id: body.category_id || null });
  if(error)logError('submit-public-application','submission_failed',{code:error.code});
  if (error) return json({ error: error.code === '54000' ? 'too many requests' : 'application unavailable' }, error.code === '54000' ? 429 : 400);
  logInfo('submit-public-application','application_received',{application_id:data});
  return json({ ok: true, application_id: data });
});
