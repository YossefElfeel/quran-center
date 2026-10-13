import type { Metadata } from "next";
import localFont from "next/font/local";
import "./globals.css";

const cairo = localFont({ src: "./fonts/Cairo.ttf", variable: "--font-cairo", display: "swap" });

export const metadata: Metadata = {
  title: "لوحة تحكم مركز تحفيظ القرآن",
  description: "لوحة السوبر أدمن لإدارة منصة مركز تحفيظ القرآن",
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="ar" dir="rtl" className={`${cairo.variable} h-full antialiased`}>
      <body className="flex min-h-full flex-col font-sans">{children}</body>
    </html>
  );
}
