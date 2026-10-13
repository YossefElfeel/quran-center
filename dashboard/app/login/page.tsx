import { SubmitButton } from "@/components/ui/button";
import { signIn } from "./actions";

export default async function LoginPage({
  searchParams,
}: {
  searchParams: Promise<{ error?: string }>;
}) {
  const { error } = await searchParams;

  return (
    <main className="mx-auto flex max-w-sm flex-1 flex-col justify-center gap-6 p-8">
      <div className="text-center">
        <h1 className="text-2xl font-bold text-primary">لوحة السوبر أدمن</h1>
        <p className="mt-1 text-sm text-foreground/60">
          مركز تحفيظ القرآن الكريم
        </p>
      </div>

      <form action={signIn} className="flex flex-col gap-4">
        <label className="flex flex-col gap-1 text-sm">
          الإيميل
          <input
            name="email"
            type="email"
            required
            autoComplete="email"
            className="rounded-lg border border-border bg-white px-3 py-2 outline-none focus:border-primary"
          />
        </label>
        <label className="flex flex-col gap-1 text-sm">
          كلمة السر
          <input
            name="password"
            type="password"
            required
            autoComplete="current-password"
            className="rounded-lg border border-border bg-white px-3 py-2 outline-none focus:border-primary"
          />
        </label>

        {error ? (
          <p className="text-sm text-red-600">
            {error === "network" ? "تعذّر الاتصال — جرّب تاني." : error === "suspended" ? "الحساب موقوف — تواصل مع الإدارة." : "الإيميل أو كلمة السر مش صحيحين."}
          </p>
        ) : null}

        <SubmitButton>دخول</SubmitButton>
      </form>

      <a href={`${process.env.NEXT_PUBLIC_WEB_URL ?? "https://quran-web-sage.vercel.app"}/auth/forgot`} className="text-center text-primary underline">نسيت كلمة السر؟</a>
      <p className="text-center text-xs text-foreground/50">
        الدخول للسوبر أدمن بس.
      </p>
    </main>
  );
}
