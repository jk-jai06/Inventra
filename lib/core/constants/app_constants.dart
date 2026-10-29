/// Application-wide constants.
class AppConstants {
  AppConstants._();

  // App info
  static const String appName = 'INVENTRA';
  static const String appTagline = 'Smart Inventory & GST Billing';
  static const String appVersion = '1.0.0';

  // Firestore collection paths (always under users/{uid}/)
  static const String productsCollection = 'products';
  static const String customersCollection = 'customers';
  static const String invoicesCollection = 'invoices';
  static const String analyticsCollection = 'analytics';
  static const String settingsCollection = 'settings';
  static const String inventoryHistoryCollection = 'inventory_history';

  // GST
  static const List<double> gstRates = [0, 5, 12, 18, 28];
  static const String intraStateGst = 'INTRA'; // CGST + SGST

  // Analytics document IDs
  static const String dailyAnalyticsDoc = 'daily';
  static const String monthlyAnalyticsDoc = 'monthly';

  // Low-stock thresholds
  static const int defaultMinimumStockLevel = 5;

  // Pagination
  static const int pageSize = 20;

  // Invoice number prefix
  static const String invoicePrefix = 'INV';
}
