"use client";

import { useEffect, useState } from "react";

import { actionLabel } from "@/lib/action-labels";
import { createSupabaseBrowserClient } from "@/lib/supabase/client";

type Alert = {
  id: string;
  severity: string;
  action: string;
};

// بيشترك في super_admin_alert (RLS بيقصره على السوبر أدمن) ويعرض توست فوري لأي عملية
// حسّاسة. بيتركّب في layout اللوحة.
export function AlertToaster() {
  const [toasts, setToasts] = useState<Alert[]>([]);

  useEffect(() => {
    const supabase = createSupabaseBrowserClient();
    const dismissTimers: ReturnType<typeof setTimeout>[] = [];

    const channel = supabase
      .channel("sa-alerts")
      .on(
        "postgres_changes",
        { event: "INSERT", schema: "public", table: "super_admin_alert" },
        (payload) => {
          const a = payload.new as Alert;
          setToasts((prev) => [a, ...prev.filter((t) => t.id !== a.id)].slice(0, 4));
          dismissTimers.push(
            setTimeout(
              () => setToasts((prev) => prev.filter((t) => t.id !== a.id)),
              8000,
            ),
          );
        },
      )
      .subscribe();

    return () => {
      dismissTimers.forEach(clearTimeout);
      supabase.removeChannel(channel);
    };
  }, []);

  if (toasts.length === 0) return null;

  return (
    <div className="fixed bottom-4 left-4 z-[60] flex flex-col gap-2">
      {toasts.map((t) => (
        <div
          key={t.id}
          role="alert"
          className={`flex items-center gap-2 rounded-lg px-4 py-2 text-sm font-bold text-white shadow-lg ${
            t.severity === "critical" ? "bg-red-600" : "bg-amber-600"
          }`}
        >
          <span aria-hidden>{t.severity === "critical" ? "🚨" : "⚠️"}</span>
          <span>عملية حسّاسة: {actionLabel(t.action)}</span>
          <button
            type="button"
            aria-label="إغلاق"
            className="text-white/80 hover:text-white"
            onClick={() =>
              setToasts((prev) => prev.filter((x) => x.id !== t.id))
            }
          >
            ✕
          </button>
        </div>
      ))}
    </div>
  );
}
