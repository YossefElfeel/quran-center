import type { Metadata } from "next";
import { ForgotPasswordForm } from "../../../components/forgot-password-form";

export const metadata: Metadata = { title: "استعادة كلمة السر — دار التحفيظ", robots: { index: false } };

export default function ForgotPage() {
  return <main className="mx-auto w-full max-w-lg px-5 py-12"><ForgotPasswordForm /></main>;
}
