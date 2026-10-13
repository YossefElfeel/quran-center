import { createServerClient } from "@supabase/ssr";
import { NextResponse, type NextRequest } from "next/server";

// بوابة الدخول للوحة (Next 16 proxy convention): لازم جلسة صالحة.
// (Phase D1: نتأكد كمان إن الدور super_admin.) قبل ضبط Supabase بنسيب كله يعدّي.
export async function proxy(request: NextRequest) {
  const url = process.env.NEXT_PUBLIC_SUPABASE_URL;
  const anonKey = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY;

  if (!url || !anonKey) {
    return NextResponse.next({ request });
  }

  let response = NextResponse.next({ request });
  let clearImpersonation = false;
  const impersonation = request.cookies.get("imp_token")?.value;
  if (impersonation) {
    try {
      // Expiry metadata only decides whether to clear a cookie; it grants no access.
      const claims = JSON.parse(Buffer.from(impersonation.split(".")[1], "base64url").toString());
      clearImpersonation = typeof claims.exp !== "number" || claims.exp * 1000 <= Date.now();
    } catch { clearImpersonation = true; }
    if (clearImpersonation) request.cookies.delete("imp_token");
  }
  const finish = (result: NextResponse) => {
    if (result !== response) {
      for (const cookie of response.cookies.getAll()) result.cookies.set(cookie);
    }
    if (clearImpersonation) result.cookies.set("imp_token", "", { path: "/", maxAge: 0, httpOnly: true, sameSite: "lax", secure: process.env.NODE_ENV === "production" });
    return result;
  };

  const supabase = createServerClient(url, anonKey, {
    cookies: {
      getAll() {
        return request.cookies.getAll();
      },
      setAll(cookiesToSet) {
        for (const { name, value } of cookiesToSet) {
          request.cookies.set(name, value);
        }
        response = NextResponse.next({ request });
        for (const { name, value, options } of cookiesToSet) {
          response.cookies.set(name, value, options);
        }
      },
    },
  });

  const {
    data: { user },
  } = await supabase.auth.getUser();

  const isLoginRoute = request.nextUrl.pathname.startsWith("/login");

  // فحص الدور super_admin بيتعمل في layout الـ (dash) (Server Component عبر
  // getSuperAdmin) — هنا بس بنتأكد إن فيه جلسة صالحة.
  if (!user && !isLoginRoute) {
    const redirectUrl = request.nextUrl.clone();
    redirectUrl.pathname = "/login";
    return finish(NextResponse.redirect(redirectUrl));
  }
  if (user && isLoginRoute) {
    const redirectUrl = request.nextUrl.clone();
    redirectUrl.pathname = "/";
    return finish(NextResponse.redirect(redirectUrl));
  }

  return finish(response);
}

export const config = {
  matcher: [
    "/((?!_next/static|_next/image|favicon.ico|.*\\.(?:svg|png|jpg|jpeg|gif|webp)$).*)",
  ],
};
