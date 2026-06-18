/// حالة اشتراك الأسرة (مُشتقّة من آخر دفعة + فترة السماح).
enum SubscriptionStatus {
  active,
  grace,
  overdue,
  inactive;

  String get labelAr => switch (this) {
    SubscriptionStatus.active => 'نشط',
    SubscriptionStatus.grace => 'فترة سماح',
    SubscriptionStatus.overdue => 'متأخّر',
    SubscriptionStatus.inactive => 'غير مفعّل',
  };

  /// الوصول لميزات ولي الأمر متاح في النشط وفترة السماح بس.
  bool get grantsAccess =>
      this == SubscriptionStatus.active || this == SubscriptionStatus.grace;
}
