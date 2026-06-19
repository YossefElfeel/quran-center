// مفاتيح system_settings اللي بيقراها التطبيق (M1.2) — مع وصف عربي وحدود.
export const SETTINGS = [
  {
    key: "daily_pass_threshold",
    label: "حد نجاح التسميع (من ١٠)",
    min: 1,
    max: 10,
  },
  {
    key: "struggle_failed_attempts",
    label: "عدد مرات الرسوب قبل تنبيه التعثّر",
    min: 1,
    max: 10,
  },
  {
    key: "subscription_amount_egp",
    label: "قيمة اشتراك الأسرة الشهري (ج.م)",
    min: 0,
    max: 1000,
  },
  {
    key: "subscription_grace_days",
    label: "فترة سماح الاشتراك (أيام)",
    min: 0,
    max: 60,
  },
  {
    key: "circle_max_size",
    label: "الحد الأقصى لعدد طلاب الحلقة",
    min: 1,
    max: 100,
  },
] as const;
