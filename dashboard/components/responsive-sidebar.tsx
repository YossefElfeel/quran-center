"use client";
import { useState } from "react";
import { Menu, PanelRightClose, PanelRightOpen } from "lucide-react";
import { Sidebar } from "./sidebar";
import { Dialog } from "./ui/dialog";
export function ResponsiveSidebar({ email }: { email: string }) {
  const [open, setOpen] = useState(false);
  const [collapsed, setCollapsed] = useState(false);
  return <>
    <button className="fixed start-3 top-3 z-30 rounded-lg border border-border bg-white p-3 lg:hidden" onClick={() => setOpen(true)} aria-label="فتح قائمة التنقّل"><Menu size={20} /></button>
    {open && <Dialog variant="drawer" title="التنقّل" onClose={() => setOpen(false)}><Sidebar onNavigate={() => setOpen(false)} /></Dialog>}
    <aside className={`sticky top-0 hidden h-dvh shrink-0 overflow-y-auto border-e border-border bg-white/50 lg:block ${collapsed ? "w-20" : "w-64"}`}>
      <div className="flex items-start justify-between gap-2 border-b border-border p-4"><div className={collapsed ? "sr-only" : "min-w-0"}><p className="font-bold text-primary">لوحة السوبر أدمن</p><p className="truncate text-sm">{email}</p></div><button className="min-h-11 min-w-11" onClick={() => setCollapsed(!collapsed)} aria-label={collapsed ? "توسيع قائمة التنقّل" : "طي قائمة التنقّل"}>{collapsed ? <PanelRightOpen /> : <PanelRightClose />}</button></div>
      <Sidebar collapsed={collapsed} />
    </aside>
  </>;
}
