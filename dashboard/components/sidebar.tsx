"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";

const NAV = [
  { href: "/", label: "نظرة عامة" },
  { href: "/users", label: "المستخدمون والأدوار" },
  { href: "/settings", label: "إعدادات النظام" },
  { href: "/subscriptions", label: "الاشتراكات" },
  { href: "/complaints", label: "الشكاوى" },
  { href: "/analytics", label: "تحليلات" },
  { href: "/content", label: "الكورسات والمسابقات" },
  { href: "/audit", label: "سجل التدقيق" },
  { href: "/pdpl", label: "الخصوصية" },
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
