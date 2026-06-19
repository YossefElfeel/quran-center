import Link from "next/link";

const CARDS = [
  {
    href: "/users",
    title: "المستخدمون والأدوار",
    desc: "دعوة وإدارة الأدمن / المشرفين / المعلّمين.",
  },
  {
    href: "/settings",
    title: "إعدادات النظام",
    desc: "العتبات والاشتراك وسياسة الاحتفاظ — بيقراها التطبيق.",
  },
  {
    href: "/audit",
    title: "سجل التدقيق",
    desc: "مين شاف / عدّل / حمّل إيه عبر المنصة.",
  },
];

export default function DashHome() {
  return (
    <div className="flex flex-col gap-6">
      <h1 className="text-2xl font-bold">نظرة عامة</h1>
      <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
        {CARDS.map((c) => (
          <Link
            key={c.href}
            href={c.href}
            className="rounded-xl border border-border bg-white p-5 transition-shadow hover:shadow-md"
          >
            <h2 className="font-bold text-primary">{c.title}</h2>
            <p className="mt-1 text-sm text-foreground/60">{c.desc}</p>
          </Link>
        ))}
      </div>
    </div>
  );
}
