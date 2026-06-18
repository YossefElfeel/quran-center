"use client";

import { useState } from "react";

import { createClient } from "@/lib/supabase";

export function ApplicationForm({ competitionId }: { competitionId: string }) {
  const [name, setName] = useState("");
  const [phone, setPhone] = useState("");
  const [youtube, setYoutube] = useState("");
  const [consent, setConsent] = useState(false);
  const [status, setStatus] = useState<"idle" | "sending" | "done">("idle");
  const [error, setError] = useState<string | null>(null);

  async function onSubmit(e: React.FormEvent<HTMLFormElement>) {
    e.preventDefault();
    if (!name.trim() || !phone.trim() || !consent) {
      setError("اكتب الاسم والموبايل ووافق على الشروط.");
      return;
    }
    setStatus("sending");
    setError(null);
    const supabase = createClient();
    const { error: err } = await supabase.functions.invoke(
      "submit-public-application",
      {
        body: {
          competition_id: competitionId,
          name: name.trim(),
          phone: phone.trim(),
          consent_ack: true,
          youtube_url: youtube.trim() || undefined,
        },
      },
    );
    if (err) {
      setStatus("idle");
      setError("مش قادرين نسجّل طلبك — يمكن قدّمت قبل كده أو في مشكلة. جرّب تاني.");
      return;
    }
    setStatus("done");
  }

  if (status === "done") {
    return (
      <div className="rounded-2xl border border-emerald-200 bg-emerald-50 p-6 text-center">
        <p className="text-lg font-semibold text-emerald-700">طلبك اتسجّل ✅</p>
        <p className="mt-1 text-emerald-600">هنتواصل معاك على الموبايل.</p>
      </div>
    );
  }

  return (
    <form onSubmit={onSubmit} className="flex flex-col gap-4">
      <input
        className="rounded-xl border border-gray-300 p-3"
        placeholder="الاسم بالكامل"
        value={name}
        onChange={(e) => setName(e.target.value)}
      />
      <input
        className="rounded-xl border border-gray-300 p-3"
        placeholder="رقم الموبايل"
        inputMode="tel"
        value={phone}
        onChange={(e) => setPhone(e.target.value)}
      />
      <input
        className="rounded-xl border border-gray-300 p-3"
        placeholder="رابط فيديو يوتيوب (اختياري)"
        value={youtube}
        onChange={(e) => setYoutube(e.target.value)}
      />
      <label className="flex items-center gap-2 text-sm text-gray-600">
        <input
          type="checkbox"
          checked={consent}
          onChange={(e) => setConsent(e.target.checked)}
        />
        موافق إن الدار تتواصل معايا وتستخدم بياناتي للمسابقة.
      </label>
      {error ? <p className="text-sm text-red-600">{error}</p> : null}
      <button
        type="submit"
        disabled={status === "sending"}
        className="rounded-xl bg-[var(--brand)] p-3 font-semibold text-white disabled:opacity-60"
      >
        {status === "sending" ? "بنسجّل…" : "قدّم في المسابقة"}
      </button>
    </form>
  );
}
