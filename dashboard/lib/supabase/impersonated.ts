import { createClient } from "@supabase/supabase-js";
import { cookies } from "next/headers";

import { createSupabaseServerClient } from "./server";

export const IMP_COOKIE = "imp_token";

// عميل بيتصرّف "كـ" الموضوع لو فيه توكن تقمّص (cookie imp_token) — الـ RLS بتشوفه
// كالموضوع والكتابة بتتنسب له. لو مفيش توكن بيرجع العميل العادي (هوية السوبر أدمن).
// مهم: getSuperAdmin وصفحة التقمّص لازم تفضل على العميل العادي (createSupabaseServerClient)
// — العميل ده للأسطح اللي المفروض تتصرّف كالموضوع بس.
export async function createImpersonatedClient() {
  const cookieStore = await cookies();
  const token = cookieStore.get(IMP_COOKIE)?.value;
  if (!token) return createSupabaseServerClient();

  return createClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
    {
      global: { headers: { Authorization: `Bearer ${token}` } },
      auth: { persistSession: false, autoRefreshToken: false },
    },
  );
}

// هل فيه تقمّص فعّال (توكن موجود)؟
export async function isImpersonating(): Promise<boolean> {
  const cookieStore = await cookies();
  return Boolean(cookieStore.get(IMP_COOKIE)?.value);
}
