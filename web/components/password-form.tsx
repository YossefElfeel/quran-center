"use client";

import { useEffect, useRef, useState } from "react";
import Link from "next/link";
import { createClient } from "../lib/supabase";

type LinkProblem = "expired" | "used" | "device" | "missing";

const problemText: Record<LinkProblem, string> = {
  expired: "الرابط ده انتهت صلاحيته. اطلب رابط جديد وافتحه على طول.",
  used: "الرابط ده اتستخدم قبل كده أو مش كامل. لو عيّنت كلمة السر خلاص، سجّل دخول من التطبيق؛ غير كده اطلب رابط جديد.",
  device: "افتح الرابط على نفس الجهاز اللي طلبت منه، أو اطلب رابط جديد.",
  missing: "الرابط ده ناقص. افتح الرابط اللي وصلك في الإيميل كامل، أو اطلب رابط جديد.",
};

class LinkError extends Error {
  constructor(readonly problem: LinkProblem) { super(problem); }
}

function errorCode(error: unknown): string | undefined {
  return typeof error === "object" && error !== null && "code" in error && typeof error.code === "string" ? error.code : undefined;
}

// Supabase reports an expired email OTP as otp_expired; anything else from verifyOtp means the
// one-time token was already consumed or is malformed.
function otpProblem(error: unknown): LinkProblem {
  return errorCode(error) === "otp_expired" ? "expired" : "used";
}

// A PKCE ?code= link can only be redeemed by the device holding its code verifier.
function codeProblem(error: unknown): LinkProblem {
  const code = errorCode(error);
  return code === "flow_state_expired" || code === "otp_expired" ? "expired" : "device";
}

// Simple, transparent heuristic: length dominates, variety adds a little, obvious patterns cost.
function passwordStrength(password: string): { score: 0 | 1 | 2 | 3 | 4; label: string } {
  if (!password) return { score: 0, label: "اكتب كلمة السر" };
  let points = 0;
  if (password.length >= 8) points++;
  if (password.length >= 12) points++;
  if (password.length >= 16) points++;
  const kinds = [/[a-z]/, /[A-Z]/, /[0-9٠-٩]/, /[^A-Za-z0-9٠-٩]/].filter((re) => re.test(password)).length;
  if (kinds >= 3) points++;
  if (/^(.)\1+$/.test(password) || /^(?:0123|1234|2345|3456|4567|5678|6789|abcd|qwer|pass|password)/i.test(password)) points = Math.min(points, 1);
  if (password.length < 8) points = 0;
  const score = Math.max(0, Math.min(4, points)) as 0 | 1 | 2 | 3 | 4;
  const labels = ["ضعيفة جدًا", "ضعيفة", "متوسطة", "كويسة", "قوية"];
  return { score, label: labels[score] };
}

export function PasswordForm({ centerPhone }: { centerPhone?: string }) {
  const client = useRef<ReturnType<typeof createClient> | null>(null);
  const verification = useRef<Promise<string> | null>(null);
  const [ready, setReady] = useState(false);
  const [email, setEmail] = useState("");
  const [error, setError] = useState("");
  const [problem, setProblem] = useState<LinkProblem | null>(null);
  const [busy, setBusy] = useState(false);
  const [done, setDone] = useState(false);
  const [visible, setVisible] = useState(false);
  const [copied, setCopied] = useState(false);
  const [password, setPassword] = useState("");
  useEffect(() => {
    const supabase = client.current ??= createClient();
    verification.current ??= (async () => {
      const url = new URL(location.href);
      const hash = new URLSearchParams(url.hash.slice(1));
      if (url.searchParams.has("error") || hash.has("error")) {
        const code = url.searchParams.get("error_code") ?? hash.get("error_code");
        throw new LinkError(code === "otp_expired" ? "expired" : "used");
      }
      const token = url.searchParams.get("token_hash");
      const type = url.searchParams.get("type");
      if (token && (type === "invite" || type === "recovery")) {
        const { error } = await supabase.auth.verifyOtp({ token_hash: token, type });
        if (error) throw new LinkError(otpProblem(error));
      } else if (url.searchParams.get("code")) {
        // Fallback for old PKCE emails: works only on the device that requested the link.
        const { error } = await supabase.auth.exchangeCodeForSession(url.searchParams.get("code")!);
        if (error) throw new LinkError(codeProblem(error));
      } else if (hash.get("access_token") && hash.get("refresh_token") && ["invite", "recovery"].includes(hash.get("type") ?? "")) {
        const { error } = await supabase.auth.setSession({ access_token: hash.get("access_token")!, refresh_token: hash.get("refresh_token")! });
        if (error) throw new LinkError("expired");
      } else { throw new LinkError("missing"); }
      const { data: { user }, error } = await supabase.auth.getUser();
      if (error || !user) throw new LinkError("expired");
      history.replaceState(null, "", "/auth/confirm");
      return user.email ?? "";
    })();
    let active = true;
    verification.current
      .then((email) => { if (active) { setEmail(email); setReady(true); } })
      .catch((reason: unknown) => { if (active) setProblem(reason instanceof LinkError ? reason.problem : "used"); });
    return () => { active = false; };
  }, []);
  const strength = passwordStrength(password);
  const phoneDigits = centerPhone?.replace(/[^0-9]/g, "") ?? "";
  if (done) return <div className="space-y-5"><h1 className="text-2xl font-bold">كلمة السر اتعيّنت</h1><p role="status">تمام — افتح تطبيق الدار وسجّل دخول بالإيميل ده</p><p dir="ltr">{email}</p><button className="rounded-lg border px-5 py-3" onClick={async () => { try { await navigator.clipboard.writeText(email); setCopied(true); } catch { setError("انسخ الإيميل الظاهر فوق يدويًا."); } }}>{copied ? "الإيميل اتنسخ" : "انسخ الإيميل"}</button>{process.env.NEXT_PUBLIC_PLAY_STORE_URL && <a className="block underline" href={process.env.NEXT_PUBLIC_PLAY_STORE_URL}>نزّل تطبيق الدار</a>}{error && <p role="alert">{error}</p>}<Link href="/" className="block underline">الرئيسية</Link></div>;
  if (problem) return <div className="space-y-5">
    <h1 className="text-2xl font-bold">{problem === "expired" ? "الرابط انتهى" : problem === "device" ? "افتح الرابط من نفس الجهاز" : "الرابط مش شغّال"}</h1>
    <p role="alert" className="text-red-700">{problemText[problem]}</p>
    <Link href="/auth/forgot" className="inline-block rounded-lg bg-[var(--brand)] px-5 py-3 text-white">اطلب رابط جديد</Link>
    {phoneDigits && <div className="space-y-2 rounded-lg border border-gray-200 bg-white p-4">
      <p>محتاج مساعدة؟ كلّم إدارة الدار:</p>
      <div className="flex flex-wrap gap-4"><a href={`tel:${centerPhone}`} dir="ltr" className="underline">{centerPhone}</a><a href={`https://wa.me/${phoneDigits}`} className="underline">واتساب الإدارة</a></div>
    </div>}
  </div>;
  return <form className="space-y-5" onSubmit={async (event) => {
    event.preventDefault(); if (!ready || busy) return;
    const data = new FormData(event.currentTarget);
    if (password.length < 8) { setError("استخدم ٨ أحرف على الأقل."); return; }
    if (password !== data.get("confirm")) { setError("كلمتا السر مختلفتين."); return; }
    setBusy(true); setError("");
    try {
      const { error } = await client.current!.auth.updateUser({ password });
      if (error) throw error;
      await client.current!.auth.signOut();
      setDone(true);
    } catch { setError("تعذّر حفظ كلمة السر. جرّب كلمة أقوى أو اطلب رابط جديد."); }
    finally { setBusy(false); }
  }}>
    <h1 className="text-2xl font-bold">عيّن كلمة السر</h1>
    {!ready && <p role="status">جاري التحقق من الرابط…</p>}
    {ready && <><p dir="ltr">{email}</p>
      <div><label htmlFor="password" className="mb-2 block">كلمة السر الجديدة</label><input id="password" name="password" value={password} onChange={(event) => setPassword(event.target.value)} type={visible ? "text" : "password"} autoComplete="new-password" minLength={8} required dir="ltr" aria-describedby="password-hint password-strength" className="w-full rounded-lg border border-gray-300 bg-white p-3" />
        <div className="mt-2 flex gap-1" aria-hidden="true">{[1, 2, 3, 4].map((step) => <span key={step} className={`h-2 flex-1 rounded-full ${password && strength.score >= step ? (strength.score >= 3 ? "bg-[var(--brand)]" : strength.score === 2 ? "bg-amber-500" : "bg-red-600") : "bg-gray-200"}`} />)}</div>
        <p id="password-strength" aria-live="polite" className="mt-1 text-sm">قوة كلمة السر: {strength.label}</p>
      </div>
      <div><label htmlFor="confirm" className="mb-2 block">تأكيد كلمة السر</label><input id="confirm" name="confirm" type={visible ? "text" : "password"} autoComplete="new-password" minLength={8} required dir="ltr" className="w-full rounded-lg border border-gray-300 bg-white p-3" /></div>
      <p id="password-hint" className="text-sm">٨ أحرف على الأقل. خليها طويلة، وفيها حروف وأرقام ورموز.</p><button type="button" aria-pressed={visible} onClick={() => setVisible(!visible)} className="underline">{visible ? "إخفاء كلمة السر" : "إظهار كلمة السر"}</button><button disabled={busy} className="block rounded-lg bg-[var(--brand)] px-5 py-3 text-white disabled:opacity-50">{busy ? "جاري الحفظ…" : "حفظ كلمة السر"}</button></>}
    {error && <p role="alert" className="text-red-700">{error}</p>}
    <Link href="/auth/forgot" className="block underline">اطلب رابط استعادة جديد</Link>
  </form>;
}
