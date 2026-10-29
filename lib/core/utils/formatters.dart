import 'package:intl/intl.dart';

/// Centralized number and date formatters.
class AppFormatters {
  AppFormatters._();

  static final _currencyFormat = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 2,
  );

  static final _compactCurrencyFormat = NumberFormat.compactCurrency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 1,
  );

  static final _dateFormat = DateFormat('dd MMM yyyy');
  static final _dateTimeFormat = DateFormat('dd MMM yyyy, hh:mm a');
  static final _timeFormat = DateFormat('hh:mm a');
  static final _monthYearFormat = DateFormat('MMM yyyy');

  /// Formats a double as an Indian currency string: ₹1,23,456.00
  static String currency(double amount) {
    return _currencyFormat.format(amount);
  }

  /// Compact currency for dashboard cards: ₹1.2L
  static String compactCurrency(double amount) {
    return _compactCurrencyFormat.format(amount);
  }

  /// Formats a [DateTime] as "12 Aug 2026".
  static String date(DateTime dt) => _dateFormat.format(dt);

  /// Formats a [DateTime] as "12 Aug 2026, 03:45 PM".
  static String dateTime(DateTime dt) => _dateTimeFormat.format(dt);

  /// Formats a [DateTime] as "03:45 PM".
  static String time(DateTime dt) => _timeFormat.format(dt);

  /// Formats a [DateTime] as "Aug 2026".
  static String monthYear(DateTime dt) => _monthYearFormat.format(dt);

  /// Formats a percentage: 18 → "18%"
  static String percent(double value) {
    return '${value.toStringAsFixed(value.truncateToDouble() == value ? 0 : 1)}%';
  }

  /// Formats a stock quantity with unit.
  static String stock(int qty) => qty == 1 ? '1 unit' : '$qty units';
}
