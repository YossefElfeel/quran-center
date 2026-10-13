// أسماء عربية مختصرة لعمليات سجل التدقيق + تصنيف الخطورة. مشترك بين سجل النشاط
// والتنبيهات الفورية (client-safe — مفيهوش أي استيراد server).
export const ACTION_LABEL: Record<string, string> = {
  role_granted: "منح دور",
  role_revoked: "سحب دور",
  user_blocked: "حظر مستخدم",
  user_unblocked: "فك حظر",
  user_soft_deleted: "إيقاف مستخدم",
  user_restored: "استرجاع مستخدم",
  user_hard_deleted: "حذف نهائي",
  force_logout: "تسجيل خروج إجباري",
  password_reset_link: "رابط إعادة كلمة سر",
  password_force_set: "تعيين كلمة سر",
  flag_toggle: "تبديل مفتاح",
  broadcast_sent: "بثّ إشعار",
  notification_retracted: "سحب إشعار",
  data_console_insert: "إضافة بيانات",
  data_console_update: "تعديل بيانات",
  data_console_delete: "حذف بيانات",
  cron_run_now: "تشغيل مهمّة",
  complaint_responded: "رد على شكوى",
  competition_updated: "تعديل مسابقة",
  cron_set_active: "تبديل مهمّة",
  cron_purge_public_registrations: "تنظيف التسجيلات القديمة",
  cron_nominate_certificate_candidates: "ترشيح المستحقين للشهادات",
  cron_media_retention: "تنظيف الوسائط القديمة",
  cron_monthly_close: "إقفال الشهر",
  cron_overdue_subscriptions: "مراجعة الاشتراكات المتأخرة",
  cron_escalate_overdue_complaints: "تصعيد الشكاوى المتأخرة",
  media_access: "وصول وسائط",
  impersonation_started: "بدء تقمّص",
  impersonation_stopped: "إيقاف التقمّص",
  settings_updated: "تحديث الإعدادات",
  certificate_issued: "إصدار شهادة",
  certificate_revoked: "سحب شهادة",
  payment_recorded: "تسجيل دفعة",
  payment_voided: "إلغاء دفعة",
  household_member_added: "إضافة فرد للأسرة",
  household_member_removed: "إزالة فرد من الأسرة",
  monthly_eval_returned: "إرجاع تقييم",
  teacher_development_returned: "إرجاع تطوير المعلّم",
};

export function actionLabel(action: string): string {
  return ACTION_LABEL[action] ?? action;
}

export function actionIsDanger(action: string): boolean {
  return (
    action.includes("delete") ||
    action.includes("hard") ||
    action === "password_force_set" ||
    action === "force_logout"
  );
}
