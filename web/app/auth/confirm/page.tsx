import type { Metadata } from "next";
import { PasswordForm } from "../../../components/password-form";
import { supabaseAnon } from "../../../lib/supabase-server";

export const metadata: Metadata = { title: "تعيين كلمة السر — دار التحفيظ", robots: { index: false } };

// Anon can read the center_* contact keys; used only to help when a link fails.
async function centerPhone(): Promise<string | undefined> {
  if (process.env.NEXT_PUBLIC_SUPABASE_URL && process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY) {
    try {
      const { data } = await supabaseAnon().from("system_settings").select("value").eq("key", "center_phone").maybeSingle();
      const phone = data ? String(data.value ?? "").trim() : "";
      if (phone) return phone;
    } catch { /* Contact help is optional. */ }
  }
  return process.env.NEXT_PUBLIC_CENTER_PHONE || undefined;
}

export default async function ConfirmPage() {
  return <main className="mx-auto w-full max-w-lg px-5 py-12"><PasswordForm centerPhone={await centerPhone()} /></main>;
}
