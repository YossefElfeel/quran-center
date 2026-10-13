import type { Metadata } from "next";
import localFont from "next/font/local";
import Link from "next/link";
import Image from "next/image";
import { supabaseAnon } from "../lib/supabase-server";
import "./globals.css";
const cairo = localFont({ src: "./fonts/Cairo.ttf", variable: "--font-cairo", display: "swap" });
export const metadata: Metadata = {
  metadataBase: new URL(process.env.NEXT_PUBLIC_SITE_URL ?? "https://quran-web-sage.vercel.app"),
  title: { default: "دار تحفيظ القرآن", template: "%s — دار تحفيظ القرآن" },
  description: "كورسات تحفيظ القرآن المجانية ومسابقات دار التحفيظ.",
  openGraph: { title: "دار تحفيظ القرآن", description: "الكورسات المجانية والمسابقات", locale: "ar_EG", type: "website", images: ["/logo.svg"] },
  icons: { icon: "/logo.svg" },
};
export default async function RootLayout({ children }: { children: React.ReactNode }) {
  let contact: Record<string, string> = {};
  if (process.env.NEXT_PUBLIC_SUPABASE_URL && process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY) {
    try { const { data } = await supabaseAnon().from("system_settings").select("key,value").in("key", ["center_name","center_phone","center_address"]); contact = Object.fromEntries((data ?? []).map(row => [row.key, String(row.value)])); } catch { /* Contact information is optional; page content remains available. */ }
  }
  const name = contact.center_name || "دار تحفيظ القرآن";
  const phone = contact.center_phone || process.env.NEXT_PUBLIC_CENTER_PHONE;
  return <html lang="ar" dir="rtl" className={`${cairo.variable} h-full antialiased`}><body className="flex min-h-full flex-col font-sans">
    <a href="#content" className="sr-only focus:not-sr-only focus:p-4">انتقل للمحتوى</a>
    <header className="border-b border-gray-200 bg-white"><div className="mx-auto flex max-w-5xl flex-wrap items-center justify-between gap-4 px-5 py-4"><Link href="/" className="flex items-center gap-3 font-bold text-[var(--brand)]"><Image src="/logo.svg" width={40} height={40} alt="" />{name}</Link><nav aria-label="التنقّل الرئيسي" className="flex flex-wrap gap-5"><Link href="/">الرئيسية</Link><Link href="/courses">الكورسات</Link><Link href="/competition">المسابقات</Link></nav></div></header>
    <div id="content" className="flex-1">{children}</div>
    <footer className="border-t border-gray-200 px-5 py-8"><div className="mx-auto flex max-w-5xl flex-wrap justify-between gap-5"><div><p className="font-semibold">{name}</p>{contact.center_address && <p>{contact.center_address}</p>}{phone && <div className="mt-2 flex gap-4"><a href={`tel:${phone}`} dir="ltr" className="underline">{phone}</a><a href={`https://wa.me/${phone.replace(/[^0-9]/g, '')}`} className="underline">واتساب الإدارة</a></div>}</div><div className="flex flex-wrap gap-4"><Link href="/auth/forgot" className="underline">استعادة كلمة السر</Link><Link href="/auth/confirm" className="underline">تفعيل حساب الدار</Link></div></div></footer>
  </body></html>;
}
