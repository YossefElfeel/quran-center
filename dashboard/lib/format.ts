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
// A billing month (YYYY-MM-01 date, no time): month + year only, never shifted by timezone.
const MONTH_FMT=new Intl.DateTimeFormat("ar-EG",{timeZone:"UTC",year:"numeric",month:"long"});
export function formatMonth(value:string|null|undefined){if(!value)return "—";const match=/^(\d{4})-(\d{2})/.exec(value);if(!match)return "—";return MONTH_FMT.format(new Date(Date.UTC(Number(match[1]),Number(match[2])-1,1)));}

// ── جمع عربي سليم (١ / ٢ / ٣–١٠ / ١١+) عبر Intl.PluralRules('ar').
// كل صيغة ممكن تحتوي {n} = العدد بأرقام عربية. "zero" و"other" (١٠٠–١٠٢…) بيرجعوا لـ many لو مش متحددين.
export type ArabicPluralForms = { zero?: string; one: string; two: string; few: string; many: string; other?: string };
const AR_PLURAL = new Intl.PluralRules("ar");
export function pluralAr(n: number | null | undefined, forms: ArabicPluralForms): string {
  const value = n ?? 0;
  const category = AR_PLURAL.select(value);
  const template =
    category === "zero" ? (forms.zero ?? forms.many)
    : category === "one" ? forms.one
    : category === "two" ? forms.two
    : category === "few" ? forms.few
    : category === "many" ? forms.many
    : (forms.other ?? forms.many);
  return template.replaceAll("{n}", formatNumber(value));
}

// ── معرّفات مختصرة لتمييز الأسماء المتكررة.
// نفس خوارزمية تطبيق الموبايل (complaintReferenceNumber): أول ٨ حروف hex من الـ UUID بدون شَرط، كابيتال.
export function referenceNumber(id: string): string {
  const compact = id.replaceAll("-", "").toUpperCase();
  return compact.length <= 8 ? compact : compact.slice(0, 8);
}
// "#XXXX" = آخر ٤ حروف من referenceNumber (زي complaintShortReference في الموبايل).
export function shortRef(id: string): string {
  const ref = referenceNumber(id);
  return `#${ref.length <= 4 ? ref : ref.slice(-4)}`;
}

// رقم موبايل للعرض: أرقام لاتيني بدون مسافات، و+20/0020 → 0 (الصيغة المحلية المعتادة).
const ARABIC_DIGITS = "٠١٢٣٤٥٦٧٨٩";
export function formatPhone(phone: string | null | undefined): string | null {
  if (!phone) return null;
  const latin = phone.replace(/[٠-٩]/g, (d) => String(ARABIC_DIGITS.indexOf(d)));
  let compact = latin.replace(/[\s\-().]/g, "");
  if (/^(\+|00)201\d{9}$/.test(compact)) compact = `0${compact.replace(/^(\+|00)20/, "")}`;
  return compact || null;
}

// مميّز ثانوي لشخص: الموبايل لو موجود، وإلا "#XXXX" من معرّفه.
export function personTag(person: { id: string; phone?: string | null }): string {
  return formatPhone(person.phone) ?? shortRef(person.id);
}
// نسخة نصية معزولة اتجاهيًا (LRI…PDI) للأماكن اللي مافيهاش عناصر HTML زي <option>.
export function isolateLtr(text: string): string {
  return `⁦${text}⁩`;
}
// "الاسم — 01xxxxxxxxx" أو "الاسم — #XXXX" (+ الدور لو اتبعت).
export function personOptionLabel(person: { id: string; full_name: string; phone?: string | null }, role?: string | null): string {
  return `${person.full_name} — ${isolateLtr(personTag(person))}${role ? ` (${role})` : ""}`;
}
