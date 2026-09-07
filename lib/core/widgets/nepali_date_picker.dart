import 'package:flutter/material.dart';
import 'package:nepali_utils/nepali_utils.dart';

import '../theme/app_colors.dart';
import '../utils/bs_date_formatter.dart';

/// A Bikram Sambat calendar picker — every date in the app is *displayed*
/// in BS (`BsDateFormatter`), but date fields were still using Flutter's
/// stock Gregorian `showDatePicker`, forcing a member/admin to pick a date
/// in a calendar system that doesn't match anything else they see. Returns
/// a plain Gregorian [DateTime] (the day's start, midnight) so it's a
/// drop-in replacement for `showDatePicker` at existing call sites.
Future<DateTime?> showNepaliDatePicker({
  required BuildContext context,
  required DateTime initialDate,
  DateTime? firstDate,
  DateTime? lastDate,
}) {
  return showDialog<DateTime>(
    context: context,
    builder: (context) => _NepaliDatePickerDialog(
      initial: initialDate.toNepaliDateTime(),
      firstDate: firstDate,
      lastDate: lastDate,
    ),
  );
}

class _NepaliDatePickerDialog extends StatefulWidget {
  const _NepaliDatePickerDialog({
    required this.initial,
    this.firstDate,
    this.lastDate,
  });

  final NepaliDateTime initial;
  final DateTime? firstDate;
  final DateTime? lastDate;

  @override
  State<_NepaliDatePickerDialog> createState() => _NepaliDatePickerDialogState();
}

class _NepaliDatePickerDialogState extends State<_NepaliDatePickerDialog> {
  late int _year = widget.initial.year;
  late int _month = widget.initial.month;

  void _changeMonth(int delta) {
    setState(() {
      _month += delta;
      if (_month > 12) {
        _month = 1;
        _year++;
      } else if (_month < 1) {
        _month = 12;
        _year--;
      }
    });
  }

  bool _inRange(DateTime date) {
    if (widget.firstDate != null && date.isBefore(widget.firstDate!)) return false;
    if (widget.lastDate != null && date.isAfter(widget.lastDate!)) return false;
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final first = NepaliDateTime(_year, _month, 1);
    final totalDays = first.totalDays;
    final leadingBlanks = first.weekday - 1;
    final todayGregorian = DateTime.now();
    final today = todayGregorian.toNepaliDateTime();

    return Dialog(
      backgroundColor: colors.surface,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () => _changeMonth(-1),
                ),
                Text(
                  '${BsDateFormatter.monthNames[_month - 1]} $_year',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: () => _changeMonth(1),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                for (final label in const ['Su', 'Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa'])
                  Expanded(
                    child: Center(
                      child: Text(
                        label,
                        style: TextStyle(fontSize: 11, color: colors.textQuaternary),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            GridView.count(
              crossAxisCount: 7,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                for (var i = 0; i < leadingBlanks; i++) const SizedBox.shrink(),
                for (var day = 1; day <= totalDays; day++)
                  Builder(
                    builder: (context) {
                      final gregorian = NepaliDateTime(_year, _month, day).toDateTime();
                      final enabled = _inRange(gregorian);
                      final isToday = _year == today.year && _month == today.month && day == today.day;
                      return Padding(
                        padding: const EdgeInsets.all(2),
                        child: Material(
                          color: Colors.transparent,
                          shape: const CircleBorder(),
                          child: InkWell(
                            customBorder: const CircleBorder(),
                            onTap: enabled ? () => Navigator.of(context).pop(gregorian) : null,
                            child: Container(
                              alignment: Alignment.center,
                              decoration: isToday
                                  ? BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(color: colors.accent),
                                    )
                                  : null,
                              child: Text(
                                '$day',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: enabled ? colors.textPrimary : colors.textQuaternary,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
              ],
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
