// أسماء عربية مختصرة لعمليات سجل التدقيق + تصنيف الخطورة. مشترك بين سجل النشاط
// والتنبيهات الفورية (client-safe — مفيهوش أي استيراد server).
const ACTION_LABEL: Record<string, string> = {
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
  cron_set_active: "تبديل مهمّة",
  media_access: "وصول وسائط",
  impersonation_started: "بدء تقمّص",
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
