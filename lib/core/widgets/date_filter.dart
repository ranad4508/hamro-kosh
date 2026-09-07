import 'package:flutter/material.dart';

import '../utils/date_formatter.dart';

/// Reusable date-range filter control (SRS §45, §55) — a chip that opens a
/// date-range picker and shows the selected range, with a quick way back to
/// "all time".
class DateFilter extends StatelessWidget {
  const DateFilter({super.key, required this.value, required this.onChanged});

  final DateTimeRange? value;
  final ValueChanged<DateTimeRange?> onChanged;

  Future<void> _pick(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 5),
      lastDate: now,
      initialDateRange: value,
    );
    if (picked != null) onChanged(picked);
  }

  @override
  Widget build(BuildContext context) {
    final label = value == null
        ? 'Date range'
        : '${DateFormatter.shortDate(value!.start)} – ${DateFormatter.shortDate(value!.end)}';

    return InputChip(
      avatar: const Icon(Icons.date_range_outlined, size: 18),
      label: Text(label),
      onPressed: () => _pick(context),
      onDeleted: value == null ? null : () => onChanged(null),
    );
  }
}
