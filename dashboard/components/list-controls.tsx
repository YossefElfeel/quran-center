import Link from "next/link";

// نموذج بحث (GET) — بيحدّث ?q= ويصفّر الصفحة. بيحافظ على فلاتر تانية عبر hidden.
export function SearchForm({
  q,
  placeholder,
  hidden,
}: {
  q?: string;
  placeholder: string;
  hidden?: Record<string, string>;
}) {
  return (
    <form className="flex flex-1 gap-2">
      {Object.entries(hidden ?? {}).map(([k, v]) => (
        <input key={k} type="hidden" name={k} value={v} />
      ))}
      <input
        name="q"
        defaultValue={q ?? ""}
        placeholder={placeholder}
        className="flex-1 rounded-lg border border-border px-3 py-2 text-sm outline-none focus:border-primary"
      />
      <button className="rounded-lg bg-primary px-4 py-2 text-sm font-bold text-white hover:opacity-90">
        بحث
      </button>
    </form>
  );
}

// تنقّل بين الصفحات — بيحافظ على باقي البراميترات.
export function Pager({
  page,
  totalPages,
  params,
}: {
  page: number;
  totalPages: number;
  params: Record<string, string>;
}) {
  const href = (p: number) => {
    const sp = new URLSearchParams(params);
    sp.set("page", String(p));
    return `?${sp.toString()}`;
  };
  const btn =
    "rounded-lg border border-border px-3 py-1.5 text-sm hover:bg-border/40";
  const disabled = "rounded-lg border border-border px-3 py-1.5 text-sm text-foreground/30";
  return (
    <div className="flex items-center justify-between gap-3 text-sm text-foreground/60">
      <span>
        صفحة {page} من {totalPages || 1}
      </span>
      <div className="flex gap-2">
        {page > 1 ? (
          <Link href={href(page - 1)} className={btn}>
            السابق
          </Link>
        ) : (
          <span className={disabled}>السابق</span>
        )}
        {page < totalPages ? (
          <Link href={href(page + 1)} className={btn}>
            التالي
          </Link>
        ) : (
          <span className={disabled}>التالي</span>
        )}
      </div>
    </div>
  );
}
