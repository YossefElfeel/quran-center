/// حالة اشتراك الأسرة (مُشتقّة من آخر دفعة + فترة السماح).
enum SubscriptionStatus {
  active,
  grace,
  overdue,
  inactive;

  /// الوصول لميزات ولي الأمر متاح في النشط وفترة السماح بس.
  bool get grantsAccess =>
      this == SubscriptionStatus.active || this == SubscriptionStatus.grace;
}
