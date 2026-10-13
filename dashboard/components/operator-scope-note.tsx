import { isDataImpersonated } from "@/lib/supabase/data-client";

// System / god-mode tools always run as the signed-in super admin, even while impersonating.
export async function OperatorScopeNote() {
  if (!(await isDataImpersonated())) return null;
  return (
    <p role="note" className="rounded-lg border border-amber-300 bg-amber-50 px-3 py-2 text-sm text-amber-900">
      بتشتغل بصلاحياتك أنت مش المتقمَّص
    </p>
  );
}
