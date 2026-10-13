import type { Metadata } from "next";
import { PasswordForm } from "../../../components/password-form";

export const metadata: Metadata = { title: "تعيين كلمة السر — دار التحفيظ", robots: { index: false } };

export default function ConfirmPage() {
  return <main className="mx-auto w-full max-w-lg px-5 py-12"><PasswordForm /></main>;
}
