export default function HomePage() {
  return (
    <main className="mx-auto flex max-w-3xl flex-1 flex-col items-center justify-center gap-6 p-8 text-center">
      <h1 className="text-3xl font-bold text-primary">
        لوحة تحكم مركز تحفيظ القرآن
      </h1>
      <p className="text-lg text-foreground/70">
        لوحة السوبر أدمن — Phase D0 (الهيكل الأساسي). الإدارة الكاملة
        (المستخدمين/الإعدادات/التدقيق/التقارير) هتتبني في المراحل الجاية.
      </p>
      <span className="rounded-full border border-border px-4 py-2 text-sm">
        Next.js · Supabase · RTL عربي
      </span>
    </main>
  );
}
