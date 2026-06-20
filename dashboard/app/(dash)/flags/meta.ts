// بيانات وصفية لكل مفتاح: العنوان العربي + هل تفعيله إجراء خطر (يدخل منطقة الخطر).
export type FlagMeta = {
  key: string;
  label: string;
  danger: boolean;
};

export const FLAG_META: Record<string, FlagMeta> = {
  maintenance_mode: {
    key: "maintenance_mode",
    label: "وضع الصيانة",
    danger: true,
  },
  freeze_sessions: {
    key: "freeze_sessions",
    label: "تجميد الجلسات",
    danger: true,
  },
  freeze_payments: {
    key: "freeze_payments",
    label: "تجميد المدفوعات",
    danger: true,
  },
  write_impersonation: {
    key: "write_impersonation",
    label: "التقمّص بصلاحية الكتابة",
    danger: true,
  },
  public_registration: {
    key: "public_registration",
    label: "التسجيل العام",
    danger: false,
  },
};

export function flagLabel(key: string): string {
  return FLAG_META[key]?.label ?? key;
}

export function flagIsDanger(key: string): boolean {
  return FLAG_META[key]?.danger ?? true; // افتراض: غير معروف = خطر.
}
