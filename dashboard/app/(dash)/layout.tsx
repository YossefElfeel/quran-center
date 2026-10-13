import { stopImpersonation } from "@/app/(dash)/impersonation/actions";
import { signOut } from "@/app/login/actions";
import { AlertToaster } from "@/components/alert-toaster";
import { ToastProvider } from "@/components/ui/feedback";
import { SubmitButton } from "@/components/ui/button";
import { ImpersonationCountdown } from "@/components/impersonation-countdown";
import { ResponsiveSidebar } from "@/components/responsive-sidebar";
import { getSuperAdmin } from "@/lib/auth";
import { getActiveImpersonation } from "@/lib/impersonation";
import { createSupabaseServerClient } from "@/lib/supabase/server";

export default async function DashLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  const admin = await getSuperAdmin();

  // مسجّل بس مش super_admin → 403 (الـ middleware ضمن إنه مسجّل أصلاً).
  if (!admin) {
    return (
      <main className="mx-auto flex max-w-md flex-1 flex-col items-center justify-center gap-4 p-8 text-center">
        <h1 className="text-2xl font-bold text-red-600">ممنوع الوصول</h1>
        <p className="text-foreground/70">
          الصفحة دي للسوبر أدمن بس. لو دخلت بالغلط، سجّل خروج وادخل بحساب
          سوبر أدمن.
        </p>
        <form action={signOut}>
          <button className="rounded-lg border border-border px-4 py-2 text-sm hover:bg-border/40">
            تسجيل خروج
          </button>
        </form>
      </main>
    );
  }

  const impersonation = await getActiveImpersonation(admin.personId);
  const showBanner = impersonation && !impersonation.expired;

  const supabase = await createSupabaseServerClient();
  const { data: maintRow } = await supabase
    .from("feature_flag")
    .select("enabled")
    .eq("key", "maintenance_mode")
    .maybeSingle();
  const maintenance = maintRow?.enabled === true;

  return (
    <div className="flex min-h-full flex-1 flex-col">
      <AlertToaster />
      <ToastProvider />
      {maintenance ? (
        <div className="bg-amber-500 px-6 py-2 text-center text-sm font-bold text-white">
          🛠️ وضع الصيانة مفعّل — كتابة الجلسات والمدفوعات متجمّدة لكل المستخدمين
          (عدا السوبر أدمن)
        </div>
      ) : null}
      {showBanner ? (
        <div className="flex items-center justify-between gap-3 bg-red-600 px-6 py-2 text-sm font-bold text-white">
          <span>
            🔴 بتتصرّف كـ «{impersonation.subjectName}» — كل تغيير بيتنسب لك (مدقّق،
            ٣٠ دقيقة) <ImpersonationCountdown expiresAt={new Date(impersonation.startedAt).getTime() + 1800000} />
          </span>
          <form action={stopImpersonation}>
            <SubmitButton className="bg-white/20">إيقاف</SubmitButton>
          </form>
        </div>
      ) : null}
      <div className="flex min-h-0 flex-1">
        <ResponsiveSidebar email={admin.email ?? ""} />

      <div className="flex min-w-0 flex-1 flex-col">
        <header className="flex items-center justify-between border-b border-border pe-6 ps-16 py-3 lg:ps-6">
          <span className="text-sm text-foreground/60">
            مركز تحفيظ القرآن الكريم
          </span>
          <form action={signOut}>
            <button className="rounded-lg border border-border px-3 py-1.5 text-sm hover:bg-border/40">
              خروج
            </button>
          </form>
        </header>
          <main className="min-w-0 flex-1 p-4 sm:p-6">{children}</main>
        </div>
      </div>
    </div>
  );
}
