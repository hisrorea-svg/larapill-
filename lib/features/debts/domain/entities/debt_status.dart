/// حالة الدين بناءً على عمره
enum DebtStatus {
  /// دين عادي (أقل من 15 يوم)
  normal,

  /// دين قريب من التأخير (15-30 يوم)
  warning,

  /// دين متأخر (أكثر من 30 يوم)
  overdue,
}

/// ثوابت حدود عمر الدين
class DebtThresholds {
  DebtThresholds._();

  /// عدد أيام الدين قبل اعتباره قريب من التأخير
  static const int warningDays = 15;

  /// عدد أيام الدين قبل اعتباره متأخر
  static const int overdueDays = 30;
}
