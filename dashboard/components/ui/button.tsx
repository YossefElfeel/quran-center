"use client";
import { useFormStatus } from "react-dom";

export function Button({ children, variant = "primary", ...props }: React.ButtonHTMLAttributes<HTMLButtonElement> & { variant?: "primary" | "secondary" | "danger" }) {
  return <button {...props} className={`min-h-11 rounded-lg px-4 py-2 font-semibold disabled:opacity-50 ${variant === "primary" ? "bg-primary text-white" : variant === "danger" ? "bg-red-700 text-white" : "border border-border bg-white"} ${props.className ?? ""}`}>{children}</button>;
}
export function SubmitButton({ children = "حفظ", ...props }: React.ButtonHTMLAttributes<HTMLButtonElement>) {
  const { pending } = useFormStatus();
  return <Button {...props} type="submit" disabled={pending || props.disabled} aria-busy={pending}>{pending ? "جاري التنفيذ…" : children}</Button>;
}
