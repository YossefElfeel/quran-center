"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";

const NAV = [
  { href: "/", label: "نظرة عامة" },
  { href: "/users", label: "المستخدمون والأدوار" },
  { href: "/academics", label: "المناهج والحلقات" },
  { href: "/enrollment", label: "التسجيل" },
  { href: "/intake", label: "قائمة الانتظار" },
  { href: "/circles", label: "الحلقات والمتابعة" },
  { href: "/excuses", label: "أعذار الغياب" },
  { href: "/evaluations", label: "التقييمات والاعتمادات" },
  { href: "/certificates", label: "الشهادات" },
  { href: "/notifications", label: "الإشعارات والبثّ" },
  { href: "/media", label: "الوسائط والموافقات" },
  { href: "/settings", label: "إعدادات النظام" },
  { href: "/flags", label: "المفاتيح ووضع الصيانة" },
  { href: "/automation", label: "الأتمتة والمجدولات" },
  { href: "/subscriptions", label: "الاشتراكات" },
  { href: "/complaints", label: "الشكاوى" },
  { href: "/analytics", label: "تحليلات" },
  { href: "/content", label: "الكورسات والمسابقات" },
  { href: "/audit", label: "سجل التدقيق" },
  { href: "/pdpl", label: "الخصوصية" },
  { href: "/impersonation", label: "تقمّص الدور" },
  { href: "/data", label: "وحدة التحكّم بالبيانات" },
];

export function Sidebar() {
  const path = usePathname();
  return (
    <nav className="flex flex-col gap-1 p-3">
      {NAV.map((item) => {
        const active =
          item.href === "/" ? path === "/" : path.startsWith(item.href);
        return (
          <Link
            key={item.href}
            href={item.href}
            className={`rounded-lg px-3 py-2 text-sm transition-colors ${
              active
                ? "bg-primary font-bold text-white"
                : "text-foreground/80 hover:bg-border/50"
            }`}
          >
            {item.label}
          </Link>
        );
      })}
    </nav>
  );
}
