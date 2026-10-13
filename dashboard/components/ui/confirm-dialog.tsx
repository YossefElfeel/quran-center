"use client";
import { useState } from "react";
import { Dialog } from "./dialog";
import { Button } from "./button";

export function ConfirmDialog({ title, description, onConfirm, onClose, children }: { title: string; description?: string; onConfirm: () => void | Promise<void>; onClose: () => void; children?: React.ReactNode }) {
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState("");
  return <Dialog title={title} onClose={() => { if (!busy) onClose(); }}><div className="space-y-4">{description && <p>{description}</p>}{children}{error && <p role="alert" className="text-red-700">{error}</p>}<div className="flex gap-3"><Button disabled={busy} onClick={async () => { if (busy) return; setBusy(true); try { await onConfirm(); } catch { setError("تعذّر التنفيذ — جرّب تاني"); } finally { setBusy(false); } }}>{busy ? "جاري التنفيذ…" : "تأكيد"}</Button><Button variant="secondary" disabled={busy} onClick={onClose}>إلغاء</Button></div></div></Dialog>;
}
