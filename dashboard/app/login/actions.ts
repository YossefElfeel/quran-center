"use server";

import { redirect } from "next/navigation";

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
  await supabase.auth.signOut();
  redirect("/login");
}
