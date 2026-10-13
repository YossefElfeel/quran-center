"use server";

import { cookies } from "next/headers";
import { redirect } from "next/navigation";

import { getSuperAdmin } from "@/lib/auth";
import { IMP_COOKIE } from "@/lib/supabase/impersonated";

import { createSupabaseServerClient } from "@/lib/supabase/server";
import { z } from "zod";

export async function signIn(formData: FormData) {
  if (!z.object({email:z.email(),password:z.string().min(1)}).safeParse(Object.fromEntries(formData)).success) redirect("/login?error=credentials");
  const email = String(formData.get("email") ?? "");
  const password = String(formData.get("password") ?? "");

  const supabase = await createSupabaseServerClient();
  const { error } = await supabase.auth.signInWithPassword({ email, password });
  if (error) {
    redirect(`/login?error=${error.code === "user_banned" ? "suspended" : error.code === "invalid_credentials" ? "credentials" : "network"}`);
  }
  redirect("/");
}

export async function signOut() {
  const supabase = await createSupabaseServerClient();
  const cookieStore = await cookies();
  // End any open impersonation and drop its cookie, so the next sign-in starts clean.
  if (cookieStore.get(IMP_COOKIE)) {
    const admin = await getSuperAdmin();
    if (admin) {
      await supabase
        .from("impersonation_session")
        .update({ ended_at: new Date().toISOString() })
        .eq("super_admin_person_id", admin.personId)
        .is("ended_at", null);
    }
    cookieStore.delete(IMP_COOKIE);
  }
  await supabase.auth.signOut();
  redirect("/login");
}
