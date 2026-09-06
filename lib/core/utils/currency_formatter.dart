import 'package:intl/intl.dart';

/// Formats amounts as Nepalese Rupees (NPR), the SRS's example currency.
/// Centralized so a future multi-currency setting only needs one edit.
abstract final class CurrencyFormatter {
  static final _formatter = NumberFormat.currency(
    locale: 'en_NP',
    symbol: 'Rs. ',
    decimalDigits: 2,
  );

  static final _compactFormatter = NumberFormat.compactCurrency(
    locale: 'en_NP',
    symbol: 'Rs. ',
  );

  static String format(num amount) => _formatter.format(amount);

  /// e.g. "Rs. 1.2K" for large dashboard summary tiles.
  static String formatCompact(num amount) => _compactFormatter.format(amount);
}
