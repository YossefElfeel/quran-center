"use client";

import { useState } from "react";
import Link from "next/link";
import { createClient } from "../lib/supabase";

export function ForgotPasswordForm() {
  const [busy, setBusy] = useState(false);
  const [sent, setSent] = useState(false);
  const [error, setError] = useState("");
  return <form className="space-y-5" onSubmit={async (event) => {
    event.preventDefault();
    if (busy) return;
    const email = String(new FormData(event.currentTarget).get("email")).trim();
    setBusy(true); setError("");
    try {
      const { error } = await createClient().auth.resetPasswordForEmail(email, { redirectTo: `${location.origin}/auth/confirm` });
      if (error) throw error;
      setSent(true);
    } catch { setError("تعذّر إرسال الرابط. اتأكد من الاتصال وجرّب تاني بعد شوية."); }
    finally { setBusy(false); }
  }}>
    <h1 className="text-2xl font-bold">نسيت كلمة السر؟</h1>
    {sent ? <p role="status">لو الإيميل مسجّل هيوصلك رابط. راجع الوارد والبريد غير المرغوب فيه.</p> : <>
      <p>اكتب إيميل حسابك عشان تبعت طلب استعادة.</p>
      <div><label htmlFor="email" className="mb-2 block">الإيميل</label><input id="email" name="email" type="email" autoComplete="email" dir="ltr" required className="w-full rounded-lg border border-gray-300 bg-white p-3" /></div>
      <button disabled={busy} className="rounded-lg bg-[var(--brand)] px-5 py-3 text-white disabled:opacity-50">{busy ? "جاري الإرسال…" : "ابعت رابط استعادة"}</button>
    </>}
    {error && <p role="alert" className="text-red-700">{error}</p>}
    <Link href="/" className="block underline">الرجوع للرئيسية</Link>
  </form>;
}
