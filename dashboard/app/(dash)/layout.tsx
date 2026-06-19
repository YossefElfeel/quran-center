import { stopImpersonation } from "@/app/(dash)/impersonation/actions";
import { signOut } from "@/app/login/actions";
import { Sidebar } from "@/components/sidebar";
import { getSuperAdmin } from "@/lib/auth";
import { getActiveImpersonation } from "@/lib/impersonation";

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

  return (
    <div className="flex min-h-full flex-1 flex-col">
      {showBanner ? (
        <div className="flex items-center justify-between gap-3 bg-accent px-6 py-2 text-sm font-bold text-white">
          <span>👁️ بتعاين كـ «{impersonation.subjectName}» (قراءة فقط، مدقّق)</span>
          <form action={stopImpersonation}>
            <button className="rounded bg-white/20 px-3 py-1 hover:bg-white/30">
              إيقاف
            </button>
          </form>
        </div>
      ) : null}
      <div className="flex min-h-0 flex-1">
        <aside className="w-56 shrink-0 border-l border-border bg-white/50">
        <div className="border-b border-border p-4">
          <p className="font-bold text-primary">لوحة السوبر أدمن</p>
          <p className="truncate text-xs text-foreground/50">{admin.email}</p>
        </div>
        <Sidebar />
      </aside>

      <div className="flex min-w-0 flex-1 flex-col">
        <header className="flex items-center justify-between border-b border-border px-6 py-3">
          <span className="text-sm text-foreground/60">
            مركز تحفيظ القرآن الكريم
          </span>
          <form action={signOut}>
            <button className="rounded-lg border border-border px-3 py-1.5 text-sm hover:bg-border/40">
              خروج
            </button>
          </form>
        </header>
          <main className="min-w-0 flex-1 p-6">{children}</main>
        </div>
      </div>
    </div>
  );
}
