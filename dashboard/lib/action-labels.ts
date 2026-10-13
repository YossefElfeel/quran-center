// أسماء عربية مختصرة لعمليات سجل التدقيق + تصنيف الخطورة. مشترك بين سجل النشاط
// والتنبيهات الفورية (client-safe — مفيهوش أي استيراد server).
export const ACTION_LABEL: Record<string, string> = {
  role_granted: "منح دور",
  // Written by an earlier app version (still present in production history).
  guardian_created: "إضافة ولي أمر",
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

// أسماء عربية للجداول اللي بتظهر في target_table بسجل التدقيق (من المايجريشنز، أكشنز اللوحة،
// الـ Edge functions، وكونسول البيانات). أي جدول مش معروف بيرجع باسمه الخام.
export const TABLE_LABEL: Record<string, string> = {
  person: "الأشخاص",
  app_user: "حسابات الدخول",
  role_assignment: "الأدوار",
  guardian_link: "روابط أولياء الأمور",
  system_settings: "إعدادات النظام",
  feature_flag: "المفاتيح",
  impersonation_session: "جلسات التقمّص",
  curriculum: "المناهج",
  level: "المستويات",
  circle: "الحلقات",
  enrollment: "تسجيلات الطلاب",
  waiting_list: "قائمة الانتظار",
  public_registration: "طلبات التسجيل العام",
  placement_test: "اختبارات تحديد المستوى",
  portion: "المقاطع",
  circle_session: "جلسات الحلقات",
  session_plan: "خطط الجلسات",
  session_outcome: "نتائج الجلسات",
  group_portion_cycle: "دورات المقاطع الجماعية",
  daily_tasmee: "التسميع اليومي",
  portion_ledger_entry: "سجل المقاطع",
  student_journey_segment: "مراحل رحلة الطالب",
  monthly_study_plan: "الخطط الشهرية",
  attendance: "الحضور",
  excuse_request: "أعذار الغياب",
  behavioral_note: "الملاحظات السلوكية",
  parent_comment: "تعليقات أولياء الأمور",
  household: "الأسر",
  household_member: "أفراد الأسر",
  subscription_payment: "مدفوعات الاشتراكات",
  subscription_overdue_notice: "إنذارات تأخير الاشتراك",
  media: "الوسائط",
  consent_record: "الموافقات",
  audit_log: "سجل التدقيق",
  notification: "الإشعارات",
  super_admin_alert: "تنبيهات السوبر أدمن",
  certificate: "الشهادات",
  certificate_nomination: "ترشيحات الشهادات",
  competition: "المسابقات",
  competition_category: "فئات المسابقات",
  competition_application: "طلبات المسابقات",
  competition_judge: "محكّمو المسابقات",
  competition_score: "درجات المسابقات",
  supervisor_evaluation: "تقييمات المشرفين",
  eval_score: "درجات التقييم",
  teacher_development: "تطوير المعلّمين",
  teacher_profile: "ملفات المعلّمين",
  teacher_document: "مستندات المعلّمين",
  teacher_rating: "تقييمات المعلّمين",
  monthly_student_evaluation: "التقييمات الشهرية",
  monthly_top_student: "أوائل الشهر",
  complaint: "الشكاوى",
  course: "الكورسات",
  surah: "السور",
  mushaf_page: "صفحات المصحف",
  mushaf_juz: "أجزاء المصحف",
  mushaf_hizb: "أحزاب المصحف",
  "cron.job": "المهام المجدولة",
};

export function tableLabel(table: string | null | undefined): string {
  if (!table) return "—";
  return TABLE_LABEL[table] ?? table;
}

// أسماء الأدوار (role_assignment.role) بالعربي.
export const ROLE_LABEL: Record<string, string> = {
  super_admin: "سوبر أدمن",
  admin: "أدمن",
  supervisor: "مشرف",
  teacher: "معلّم",
  parent: "ولي أمر",
};

export function roleLabel(role: string): string {
  return ROLE_LABEL[role] ?? role;
}
