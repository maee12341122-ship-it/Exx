class AppConstants {
  // رابط الخادم المحلي للـ Backend
  static const String baseUrl = 'http://localhost:3000/api';

  // أوقات الدوام الرسمي
  static const int openingHour = 11; // 11 صباحاً
  static const int closingHour = 22; // 10 مساءً

  // مفاتيح التخزين المحلي (SharedPreferences)
  static const String acceptedTermsKey = 'ACCEPTED_TERMS';
  static const String hoursStartKey = 'HOURS_START';
}

// تصنيفات الأقسام والمنتجات لتجنب خطأ Undefined name
enum ProductCategories {
  restaurants,
  groceries,
  produce, // الخضار والفواكه
  pharmacy,
  others,
}