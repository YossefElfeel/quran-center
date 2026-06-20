"use client";

import { useEffect, useState } from "react";

import { actionIsDanger, actionLabel } from "@/lib/action-labels";
import { createSupabaseBrowserClient } from "@/lib/supabase/client";

export type ActivityEntry = {
  id: string;
  action: string;
  target_table: string | null;
  at: string;
};

function relativeTime(iso: string, nowMs: number): string {
  const diff = Math.max(0, nowMs - new Date(iso).getTime());
  const s = Math.floor(diff / 1000);
  if (s < 60) return "الآن";
  const m = Math.floor(s / 60);
  if (m < 60) return `منذ ${m} د`;
  const h = Math.floor(m / 60);
  if (h < 24) return `منذ ${h} س`;
  return `منذ ${Math.floor(h / 24)} ي`;
}

export function ActivityFeed({ initial }: { initial: ActivityEntry[] }) {
  const [items, setItems] = useState<ActivityEntry[]>(initial);
  // mounted-time clock so relative times don't desync server/client on first paint.
  const [nowMs, setNowMs] = useState<number | null>(null);

  useEffect(() => {
    const initialClock = setTimeout(() => setNowMs(Date.now()), 0);
    const clock = setInterval(() => setNowMs(Date.now()), 30000);

    const supabase = createSupabaseBrowserClient();
    const channel = supabase
      .channel("audit-feed")
      .on(
        "postgres_changes",
        { event: "INSERT", schema: "public", table: "audit_log" },
        (payload) => {
          const row = payload.new as ActivityEntry;
          setItems((prev) => [row, ...prev.filter((p) => p.id !== row.id)].slice(0, 30));
        },
      )
      .subscribe();

    return () => {
      clearTimeout(initialClock);
      clearInterval(clock);
      supabase.removeChannel(channel);
    };
  }, []);

  if (items.length === 0) {
    return (
      <p className="text-sm text-foreground/50">مفيش نشاط مسجّل بعد.</p>
    );
  }

  return (
    <ul className="flex flex-col gap-2">
      {items.map((e) => (
        <li
          key={e.id}
          className="flex items-center justify-between gap-3 rounded-lg border border-border bg-white px-3 py-2 text-sm"
        >
          <span className="flex min-w-0 items-center gap-2">
            <span
              className={`inline-block h-2 w-2 shrink-0 rounded-full ${
                actionIsDanger(e.action) ? "bg-red-500" : "bg-primary/60"
              }`}
              aria-hidden
            />
            <span className="truncate">
              {actionLabel(e.action)}
              {e.target_table ? (
                <span className="text-foreground/40"> · {e.target_table}</span>
              ) : null}
            </span>
          </span>
          <span className="shrink-0 text-xs text-foreground/40">
            {nowMs ? relativeTime(e.at, nowMs) : ""}
          </span>
        </li>
      ))}
    </ul>
  );
}
