import { createBrowserClient } from "@supabase/ssr";

// عميل المتصفح بالـ anon key (publishable). القراءات العامة محكومة بالـ RLS،
// والكتابة الحسّاسة بتتعمل عبر Edge Functions (مفيش service-role في الكلاينت).
export function createClient() {
  return createBrowserClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
  );
}
