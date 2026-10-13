// تنسيقات عربية موحّدة للوحة.
const DATE_FMT = new Intl.DateTimeFormat("ar-EG", {
  timeZone: "Africa/Cairo",
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

const DAY_FMT=new Intl.DateTimeFormat("ar-EG",{timeZone:"Africa/Cairo",year:"numeric",month:"short",day:"numeric"});
export function formatDate(iso:string|null|undefined){if(!iso)return "—";const date=new Date(iso);return Number.isNaN(date.getTime())?"—":DAY_FMT.format(date);}
export function currentCairoMonth() {
  const parts=new Intl.DateTimeFormat('en-CA',{timeZone:'Africa/Cairo',year:'numeric',month:'2-digit'}).formatToParts(new Date());
  return `${parts.find(p=>p.type==='year')!.value}-${parts.find(p=>p.type==='month')!.value}-01`;
}
