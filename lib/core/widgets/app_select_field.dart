import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// A tap-to-open bottom-sheet picker styled like [AppTextField] — used
/// instead of the stock [DropdownButtonFormField], whose native OS-styled
/// menu doesn't match the app's own sunken-field look used everywhere else
/// (amount fields, the payment-method picker on Give, etc.).
class AppSelectField<T> extends StatelessWidget {
  const AppSelectField({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.itemLabel,
    required this.onChanged,
  });

  final String label;
  final T value;
  final List<T> items;
  final String Function(T item) itemLabel;
  final ValueChanged<T> onChanged;

  Future<void> _open(BuildContext context) async {
    final selected = await showModalBottomSheet<T>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(bottom: 8),
          // A plain `mainAxisSize: MainAxisSize.min` Column has no fallback
          // once its content is taller than the sheet's available height —
          // it just overflows silently past the bottom instead of scrolling.
          // Bounding the sheet and letting only the item list scroll (the
          // label stays pinned) keeps this working for any list length or
          // screen size instead of just whatever happened to fit before.
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.75,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      label,
                      style: Theme.of(sheetContext).textTheme.titleSmall,
                    ),
                  ),
                ),
                Flexible(
                  child: SingleChildScrollView(
                    child: RadioGroup<T>(
                      groupValue: value,
                      onChanged: (v) => Navigator.of(sheetContext).pop(v),
                      child: Column(
                        children: [
                          for (final item in items)
                            RadioListTile<T>(
                              value: item,
                              title: Text(itemLabel(item)),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (selected != null) onChanged(selected);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return InkWell(
      onTap: () => _open(context),
      borderRadius: BorderRadius.circular(9),
      child: InputDecorator(
        decoration: InputDecoration(labelText: label),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(itemLabel(value), style: TextStyle(color: colors.textPrimary)),
            Icon(Icons.expand_more, color: colors.textQuaternary),
          ],
        ),
      ),
    );
  }
}
