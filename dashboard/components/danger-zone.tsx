// قسم «منطقة الخطر» — يجمع العمليات المدمّرة/الخطرة (حذف نهائي، تقمّص بالكتابة،
// وضع الصيانة، تجميد المدفوعات) في إطار أحمر واضح بصريًا.
export function DangerZone({
  title = "منطقة الخطر",
  description,
  children,
}: {
  title?: string;
  description?: string;
  children: React.ReactNode;
}) {
  return (
    <section className="flex flex-col gap-3 rounded-xl border-2 border-red-200 bg-red-50/40 p-5">
      <div className="flex flex-col gap-1">
        <h2 className="flex items-center gap-2 text-lg font-bold text-red-700">
          <span aria-hidden>⚠️</span>
          {title}
        </h2>
        {description ? (
          <p className="text-xs text-red-700/80">{description}</p>
        ) : null}
      </div>
      <div className="flex flex-col gap-3">{children}</div>
    </section>
  );
}
