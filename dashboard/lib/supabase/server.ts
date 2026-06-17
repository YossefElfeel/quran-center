import { createServerClient } from "@supabase/ssr";
import { cookies } from "next/headers";

// عميل Supabase للسيرفر (Server Components / Server Actions / Route Handlers).
// بيستخدم anon key + RLS — مش service-role. الـ service-role يتعمله helper
// منفصل server-only لمّا نحتاجه (دعوة مستخدمين / impersonation) في D1/D4.
export async function createSupabaseServerClient() {
  const cookieStore = await cookies();

  return createServerClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
    {
      cookies: {
        getAll() {
          return cookieStore.getAll();
        },
        setAll(cookiesToSet) {
          try {
            for (const { name, value, options } of cookiesToSet) {
              cookieStore.set(name, value, options);
            }
          } catch {
            // مُستدعى من Server Component — الكتابة بتتم في الـ middleware.
          }
        },
      },
    },
  );
}
