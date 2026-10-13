"use client";
import { useEffect, useState } from "react";

export function toast(message: string, error = false) {
  window.dispatchEvent(new CustomEvent("quran-toast", { detail: { message, error } }));
}
export function useActionFeedback(state: {ok:boolean;error?:string}|null, message = "تم حفظ التغيير") {
  useEffect(() => {
    if (state?.ok) toast(message);
    else if (state?.error) toast(state.error, true);
  }, [state, message]);
}
export function ToastProvider() {
  const [notice, setNotice] = useState<{ message: string; error: boolean } | null>(null);
  useEffect(() => {
    let timer: ReturnType<typeof setTimeout>;
    const receive = (event: Event) => { setNotice((event as CustomEvent).detail); clearTimeout(timer); timer = setTimeout(() => setNotice(null), 5000); };
    window.addEventListener("quran-toast", receive);
    return () => { window.removeEventListener("quran-toast", receive); clearTimeout(timer); };
  }, []);
  return notice ? <div role={notice.error ? "alert" : "status"} className={`fixed bottom-5 start-5 z-50 max-w-[90vw] rounded-lg px-5 py-3 text-white shadow-lg ${notice.error ? "bg-red-700" : "bg-primary"}`}>{notice.message}</div> : null;
}
