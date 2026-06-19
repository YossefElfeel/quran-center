// تنسيقات عربية موحّدة للوحة.
const DATE_FMT = new Intl.DateTimeFormat("ar-EG", {
  year: "numeric",
  month: "short",
  day: "numeric",
  hour: "2-digit",
  minute: "2-digit",
});

const NUM_FMT = new Intl.NumberFormat("ar-EG");

export function formatDateTime(iso: string | null | undefined): string {
  if (!iso) return "—";
  const d = new Date(iso);
  return Number.isNaN(d.getTime()) ? "—" : DATE_FMT.format(d);
}

export function formatNumber(n: number | null | undefined): string {
  return NUM_FMT.format(n ?? 0);
}
