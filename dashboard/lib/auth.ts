import { createSupabaseServerClient } from "@/lib/supabase/server";

export type SuperAdmin = {
  userId: string;
  email: string | null;
  personId: string;
};

// يرجّع بيانات السوبر أدمن الحالي، أو null لو مش مسجّل/مش super_admin.
// نفس منطق التطبيق: auth user → app_user.person_id → role_assignment (نفلتر
// صراحةً على person_id بتاعه). الـ middleware بيضمن إنه مسجّل أصلاً.
export async function getSuperAdmin(): Promise<SuperAdmin | null> {
  const supabase = await createSupabaseServerClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) return null;

  const { data: appUser } = await supabase
    .from("app_user")
    .select("person_id")
    .eq("auth_user_id", user.id)
    .maybeSingle();
  const personId = appUser?.person_id as string | undefined;
  if (!personId) return null;

  const { data: roles } = await supabase
    .from("role_assignment")
    .select("role")
    .eq("person_id", personId);
  const isSuper = (roles ?? []).some((r) => r.role === "super_admin");
  if (!isSuper) return null;

  return { userId: user.id, email: user.email ?? null, personId };
}
