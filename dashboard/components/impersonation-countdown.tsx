"use client";
import { useEffect, useState } from "react";
import { useRouter } from "next/navigation";
export function ImpersonationCountdown({ expiresAt }: { expiresAt: number }) {
  const [seconds, setSeconds] = useState<number | null>(null);
  const router = useRouter();
  useEffect(() => {
    const update = () => { const remaining = Math.max(0, Math.ceil((expiresAt - Date.now()) / 1000)); setSeconds(remaining); if (!remaining) router.refresh(); };
    const timer = setInterval(update, 1000); update(); return () => clearInterval(timer);
  }, [expiresAt, router]);
  return <span role="timer" aria-label="الوقت المتبقي للتقمّص">{seconds === null ? "…" : new Intl.NumberFormat("ar-EG").format(Math.floor(seconds / 60)) + ":" + new Intl.NumberFormat("ar-EG", { minimumIntegerDigits: 2 }).format(seconds % 60)}</span>;
}
