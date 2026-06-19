import { createClient } from "@supabase/supabase-js";

// عميل anon للقراءة العامة من Server Components (مفيش جلسة، مفيش service-role).
export function supabaseAnon() {
  return createClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
    { auth: { persistSession: false } },
  );
}
