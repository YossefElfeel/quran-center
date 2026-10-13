"use client";

import { useEffect, useRef, useState } from "react";
import Link from "next/link";
import { createClient } from "../lib/supabase";

export function PasswordForm() {
  const client = useRef<ReturnType<typeof createClient> | null>(null);
  const verification = useRef<Promise<string> | null>(null);
  const [ready, setReady] = useState(false);
  const [email, setEmail] = useState("");
  const [error, setError] = useState("");
  const [busy, setBusy] = useState(false);
  const [done, setDone] = useState(false);
  const [visible, setVisible] = useState(false);
  const [copied, setCopied] = useState(false);
  useEffect(() => {
    const supabase = client.current ??= createClient();
    verification.current ??= (async () => {
      const url = new URL(location.href);
      const hash = new URLSearchParams(url.hash.slice(1));
      if (url.searchParams.has("error") || hash.has("error")) throw new Error("expired");
      const token = url.searchParams.get("token_hash");
      const type = url.searchParams.get("type");
      if (token && (type === "invite" || type === "recovery")) {
        const { error } = await supabase.auth.verifyOtp({ token_hash: token, type });
        if (error) throw error;
      } else if (url.searchParams.get("code")) {
        const { error } = await supabase.auth.exchangeCodeForSession(url.searchParams.get("code")!);
        if (error) throw error;
      } else if (hash.get("access_token") && hash.get("refresh_token") && ["invite", "recovery"].includes(hash.get("type") ?? "")) {
        const { error } = await supabase.auth.setSession({ access_token: hash.get("access_token")!, refresh_token: hash.get("refresh_token")! });
        if (error) throw error;
      } else { throw new Error("missing_link"); }
      const { data: { user }, error } = await supabase.auth.getUser();
      if (error || !user) throw error ?? new Error("expired");
      history.replaceState(null, "", "/auth/confirm");
      return user.email ?? "";
    })();
    let active = true;
    verification.current.then((email) => { if (active) { setEmail(email); setReady(true); } }).catch(() => { if (active) setError("الرابط انتهى أو اتستخدم قبل كده. اطلب رابط جديد من الإدارة، أو استخدم استعادة كلمة السر."); });
    return () => { active = false; };
  }, []);
  if (done) return <div className="space-y-5"><h1 className="text-2xl font-bold">كلمة السر اتعيّنت</h1><p role="status">تمام — افتح تطبيق الدار وسجّل دخول بالإيميل ده</p><p dir="ltr">{email}</p><button className="rounded-lg border px-5 py-3" onClick={async () => { try { await navigator.clipboard.writeText(email); setCopied(true); } catch { setError("انسخ الإيميل الظاهر فوق يدويًا."); } }}>{copied ? "الإيميل اتنسخ" : "انسخ الإيميل"}</button>{process.env.NEXT_PUBLIC_PLAY_STORE_URL && <a className="block underline" href={process.env.NEXT_PUBLIC_PLAY_STORE_URL}>نزّل تطبيق الدار</a>}{error && <p role="alert">{error}</p>}<Link href="/" className="block underline">الرئيسية</Link></div>;
  return <form className="space-y-5" onSubmit={async (event) => {
    event.preventDefault(); if (!ready || busy) return;
    const data = new FormData(event.currentTarget);
    const password = String(data.get("password"));
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
    {!ready && !error && <p role="status">جاري التحقق من الرابط…</p>}
    {ready && <><p dir="ltr">{email}</p>{["password", "confirm"].map((name) => <div key={name}><label htmlFor={name} className="mb-2 block">{name === "password" ? "كلمة السر الجديدة" : "تأكيد كلمة السر"}</label><input id={name} name={name} type={visible ? "text" : "password"} autoComplete="new-password" minLength={8} required dir="ltr" className="w-full rounded-lg border border-gray-300 bg-white p-3" /></div>)}<p className="text-sm">٨ أحرف على الأقل. خليها طويلة، وفيها حروف وأرقام ورموز.</p><button type="button" aria-pressed={visible} onClick={() => setVisible(!visible)} className="underline">{visible ? "إخفاء كلمة السر" : "إظهار كلمة السر"}</button><button disabled={busy} className="block rounded-lg bg-[var(--brand)] px-5 py-3 text-white disabled:opacity-50">{busy ? "جاري الحفظ…" : "حفظ كلمة السر"}</button></>}
    {error && <p role="alert" className="text-red-700">{error}</p>}
    <Link href="/auth/forgot" className="block underline">اطلب رابط استعادة جديد</Link>
  </form>;
}
