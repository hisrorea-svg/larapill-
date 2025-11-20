class NumberFormatter {
  // تحويل الأرقام الفارسية والعربية إلى إنجليزية
  static String toEnglishNumbers(String input) {
    const farsiNumbers = ['۰', '۱', '۲', '۳', '۴', '۵', '۶', '۷', '۸', '۹'];
    const arabicNumbers = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    const englishNumbers = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];

    String result = input;

    // تحويل الأرقام الفارسية
    for (int i = 0; i < farsiNumbers.length; i++) {
      result = result.replaceAll(farsiNumbers[i], englishNumbers[i]);
    }

    // تحويل الأرقام العربية
    for (int i = 0; i < arabicNumbers.length; i++) {
      result = result.replaceAll(arabicNumbers[i], englishNumbers[i]);
    }

    return result;
  }

  // تنسيق الأرقام مع فواصل
  static String formatNumber(int number) {
    return number.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match match) => '${match[1]},',
        );
  }

  // تنسيق المبلغ مع العملة
  static String formatCurrency(int amount, {String currency = 'د.ع'}) {
    return '${formatNumber(amount)} $currency';
  }
}
