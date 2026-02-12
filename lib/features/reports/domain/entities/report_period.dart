/// فترة التقرير الزمنية
enum ReportPeriodType {
  today,
  yesterday,
  week,
  month,
  year,
  custom,
}

/// كيان الفترة الزمنية للتقارير
class ReportPeriod {
  final ReportPeriodType type;
  final DateTime startDate;
  final DateTime endDate;

  const ReportPeriod({
    required this.type,
    required this.startDate,
    required this.endDate,
  });

  /// فترة اليوم
  factory ReportPeriod.today() {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final end = DateTime(now.year, now.month, now.day, 23, 59, 59);
    return ReportPeriod(
        type: ReportPeriodType.today, startDate: start, endDate: end);
  }

  /// فترة أمس
  factory ReportPeriod.yesterday() {
    final now = DateTime.now();
    final yesterday = now.subtract(const Duration(days: 1));
    final start = DateTime(yesterday.year, yesterday.month, yesterday.day);
    final end =
        DateTime(yesterday.year, yesterday.month, yesterday.day, 23, 59, 59);
    return ReportPeriod(
        type: ReportPeriodType.yesterday, startDate: start, endDate: end);
  }

  /// فترة الأسبوع الحالي
  factory ReportPeriod.week() {
    final now = DateTime.now();
    final start = now.subtract(Duration(days: now.weekday - 1));
    final startOfWeek = DateTime(start.year, start.month, start.day);
    final end = DateTime(now.year, now.month, now.day, 23, 59, 59);
    return ReportPeriod(
        type: ReportPeriodType.week, startDate: startOfWeek, endDate: end);
  }

  /// فترة الشهر الحالي
  factory ReportPeriod.month() {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, 1);
    final end = DateTime(now.year, now.month, now.day, 23, 59, 59);
    return ReportPeriod(
        type: ReportPeriodType.month, startDate: start, endDate: end);
  }

  /// فترة السنة الحالية
  factory ReportPeriod.year() {
    final now = DateTime.now();
    final start = DateTime(now.year, 1, 1);
    final end = DateTime(now.year, now.month, now.day, 23, 59, 59);
    return ReportPeriod(
        type: ReportPeriodType.year, startDate: start, endDate: end);
  }

  /// فترة مخصصة
  factory ReportPeriod.custom(DateTime startDate, DateTime endDate) {
    return ReportPeriod(
      type: ReportPeriodType.custom,
      startDate: DateTime(startDate.year, startDate.month, startDate.day),
      endDate: DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59),
    );
  }

  /// اسم الفترة بالعربية
  String get arabicName {
    switch (type) {
      case ReportPeriodType.today:
        return 'اليوم';
      case ReportPeriodType.yesterday:
        return 'أمس';
      case ReportPeriodType.week:
        return 'الأسبوع';
      case ReportPeriodType.month:
        return 'الشهر';
      case ReportPeriodType.year:
        return 'السنة';
      case ReportPeriodType.custom:
        return 'مخصص';
    }
  }

  /// التحقق من أن التاريخ ضمن الفترة
  bool contains(DateTime date) {
    return date.isAfter(startDate.subtract(const Duration(seconds: 1))) &&
        date.isBefore(endDate.add(const Duration(seconds: 1)));
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ReportPeriod &&
        other.type == type &&
        other.startDate == startDate &&
        other.endDate == endDate;
  }

  @override
  int get hashCode => type.hashCode ^ startDate.hashCode ^ endDate.hashCode;
}
