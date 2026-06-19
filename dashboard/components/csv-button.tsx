"use client";

type Column = { key: string; label: string };

// زر تصدير CSV من صفوف معطاة (UTF-8 BOM عشان Excel يقرا العربي صح).
export function CsvButton({
  rows,
  columns,
  filename,
}: {
  rows: Record<string, string | number | null>[];
  columns: Column[];
  filename: string;
}) {
  function download() {
    const esc = (v: string | number | null) => {
      const s = String(v ?? "");
      return /[",\n]/.test(s) ? `"${s.replace(/"/g, '""')}"` : s;
    };
    const header = columns.map((c) => esc(c.label)).join(",");
    const body = rows
      .map((r) => columns.map((c) => esc(r[c.key])).join(","))
      .join("\n");
    const csv = `﻿${header}\n${body}`;
    const url = URL.createObjectURL(
      new Blob([csv], { type: "text/csv;charset=utf-8;" }),
    );
    const a = document.createElement("a");
    a.href = url;
    a.download = filename;
    a.click();
    URL.revokeObjectURL(url);
  }

  return (
    <button
      onClick={download}
      disabled={rows.length === 0}
      className="rounded-lg border border-border px-3 py-1.5 text-sm hover:bg-border/40 disabled:opacity-50"
    >
      تصدير CSV
    </button>
  );
}
