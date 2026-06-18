import Link from "next/link";

export default function HomePage() {
  return (
    <main className="mx-auto flex w-full max-w-3xl flex-col gap-10 px-6 py-16">
      <header className="text-center">
        <h1 className="text-4xl font-bold text-[var(--brand)]">
          دار تحفيظ القرآن
        </h1>
        <p className="mt-3 text-lg text-gray-600">
          كورسات مجانية لتحفيظ القرآن، وتقديم لمسابقة الدار — تسجيل بسيط بالاسم
          والموبايل.
        </p>
      </header>

      <nav className="grid gap-4 sm:grid-cols-2">
        <Link
          href="/courses"
          className="rounded-2xl border border-gray-200 bg-white p-8 text-center text-xl font-semibold shadow-sm transition hover:border-[var(--brand)] hover:shadow"
        >
          📚 الكورسات المجانية
        </Link>
        <Link
          href="/competition"
          className="rounded-2xl border border-gray-200 bg-white p-8 text-center text-xl font-semibold shadow-sm transition hover:border-[var(--brand)] hover:shadow"
        >
          🏆 المسابقة — قدّم دلوقتي
        </Link>
      </nav>

      <footer className="text-center text-sm text-gray-400">
        دار تحفيظ القرآن
      </footer>
    </main>
  );
}
