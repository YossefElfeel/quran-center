"use client";

import { useRouter } from "next/navigation";
import { useEffect } from "react";

// تحديث خفيف للصفحة (Server Component) كل فترة + عند الرجوع للتبويب. أرخص وأأمن من
// اشتراك Realtime على مقاييس مجمّعة، وبيحترم RLS تلقائيًا.
export function LiveRefresh({ intervalMs = 25000 }: { intervalMs?: number }) {
  const router = useRouter();
  useEffect(() => {
    const refreshIfVisible = () => {
      if (document.visibilityState === "visible") router.refresh();
    };
    const id = setInterval(refreshIfVisible, intervalMs);
    document.addEventListener("visibilitychange", refreshIfVisible);
    return () => {
      clearInterval(id);
      document.removeEventListener("visibilitychange", refreshIfVisible);
    };
  }, [router, intervalMs]);
  return null;
}
