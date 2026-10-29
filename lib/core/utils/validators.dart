/// Centralized form validators.
/// Return null on valid input, a non-null error string on failure.
class AppValidators {
  AppValidators._();

  static String? required(String? value, {String fieldName = 'This field'}) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) return 'Email is required';
    final emailRegex = RegExp(r'^[\w.+-]+@[\w-]+\.[a-zA-Z]{2,}$');
    if (!emailRegex.hasMatch(value.trim())) return 'Enter a valid email address';
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) return 'Password is required';
    if (value.length < 6) return 'Password must be at least 6 characters';
    return null;
  }

  static String? confirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) return 'Please confirm your password';
    if (value != password) return 'Passwords do not match';
    return null;
  }

  static String? productName(String? value) {
    if (value == null || value.trim().isEmpty) return 'Product name is required';
    if (value.trim().length < 2) return 'Product name must be at least 2 characters';
    return null;
  }

  static String? positiveNumber(String? value, {String fieldName = 'Value'}) {
    if (value == null || value.trim().isEmpty) return '$fieldName is required';
    final n = double.tryParse(value.trim());
    if (n == null) return '$fieldName must be a valid number';
    if (n < 0) return '$fieldName must be 0 or greater';
    return null;
  }

  static String? sellingPrice(String? value) {
    if (value == null || value.trim().isEmpty) return 'Selling price is required';
    final n = double.tryParse(value.trim());
    if (n == null) return 'Enter a valid price';
    if (n <= 0) return 'Selling price must be greater than 0';
    return null;
  }

  static String? gstPercent(String? value) {
    if (value == null || value.trim().isEmpty) return null; // allow 0% / empty
    final n = double.tryParse(value.trim());
    if (n == null) return 'Enter a valid GST percentage';
    if (n < 0 || n > 100) return 'GST must be between 0 and 100';
    return null;
  }

  static String? stockQuantity(String? value) {
    if (value == null || value.trim().isEmpty) return 'Quantity is required';
    final n = int.tryParse(value.trim());
    if (n == null) return 'Enter a whole number';
    if (n < 0) return 'Quantity cannot be negative';
    return null;
  }

  static String? phone(String? value) {
    if (value == null || value.trim().isEmpty) return null; // optional
    final phoneRegex = RegExp(r'^\+?[0-9]{7,15}$');
    if (!phoneRegex.hasMatch(value.trim())) return 'Enter a valid phone number';
    return null;
  }

  static String? gstin(String? value) {
    if (value == null || value.trim().isEmpty) return null; // GSTIN optional
    final gstinRegex = RegExp(
      r'^[0-9]{2}[A-Z]{5}[0-9]{4}[A-Z]{1}[1-9A-Z]{1}Z[0-9A-Z]{1}$',
    );
    if (!gstinRegex.hasMatch(value.trim().toUpperCase())) {
      return 'Enter a valid 15-character GSTIN';
    }
    return null;
  }
}
