import 'package:intl/intl.dart';

/// Shared date/time formatting so every screen renders dates consistently.
abstract final class DateFormatter {
  static final _shortDate = DateFormat('MMM d, y');
  static final _monthYear = DateFormat('MMMM y');
  static final _monthAbbr = DateFormat('MMM');
  static final _dateTime = DateFormat('MMM d, y • h:mm a');

  static String shortDate(DateTime date) => _shortDate.format(date);
  static String monthYear(DateTime date) => _monthYear.format(date);
  static String monthAbbr(DateTime date) => _monthAbbr.format(date);
  static String dateTime(DateTime date) => _dateTime.format(date);

  /// "3 days ago" / "in 2 days" style relative label for reminders and
  /// notification lists.
  static String relative(DateTime date) {
    final now = DateTime.now();
    final diff = date.difference(now);
    final days = diff.inDays;
    if (days == 0) return 'Today';
    if (days == 1) return 'Tomorrow';
    if (days == -1) return 'Yesterday';
    if (days > 1) return 'In $days days';
    return '${days.abs()} days ago';
  }
}
