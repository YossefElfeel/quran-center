"use client";
import { useFormStatus } from "react-dom";

export function Button({ children, variant = "primary", size = "md", ...props }: React.ButtonHTMLAttributes<HTMLButtonElement> & { variant?: "primary" | "secondary" | "danger"; size?: "md" | "sm" }) {
  return <button {...props} className={`${size === "sm" ? "min-h-9 rounded-lg px-3 py-1 text-sm" : "min-h-11 rounded-lg px-4 py-2"} font-semibold disabled:opacity-50 ${variant === "primary" ? "bg-primary text-white" : variant === "danger" ? "bg-red-700 text-white" : "border border-border bg-white"} ${props.className ?? ""}`}>{children}</button>;
}
export function SubmitButton({ children = "حفظ", ...props }: React.ComponentProps<typeof Button>) {
  const { pending } = useFormStatus();
  return <Button {...props} type="submit" disabled={pending || props.disabled} aria-busy={pending}>{pending ? "جاري التنفيذ…" : children}</Button>;
}
