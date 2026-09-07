import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../utils/currency_formatter.dart';

/// The design's correction pattern (`design_spec.md` §2, pattern 10; screen
/// `2d`): a corrected ledger entry keeps its original line visible
/// (struck-through, dimmed) with the correction nested beneath it — SRS
/// business rule 3/4: financial transactions are never deleted, and a
/// correction always leaves an audit trail rather than overwriting history.
class CorrectedEntryTile extends StatelessWidget {
  const CorrectedEntryTile({
    super.key,
    required this.originalDescription,
    required this.originalAmount,
    required this.correctedAmount,
    required this.reason,
    required this.correctedBy,
    required this.correctedOnLabel,
  });

  final String originalDescription;
  final double originalAmount;
  final double correctedAmount;
  final String reason;
  final String correctedBy;
  final String correctedOnLabel;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                originalDescription,
                style: TextStyle(
                  decoration: TextDecoration.lineThrough,
                  color: colors.textQuaternary,
                  fontSize: 13.5,
                ),
              ),
            ),
            Text(
              CurrencyFormatter.format(originalAmount),
              style: TextStyle(
                decoration: TextDecoration.lineThrough,
                color: colors.textQuaternary,
                fontSize: 13.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 4, right: 10),
                child: Container(width: 2, color: colors.accentDark3),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Corrected to ${CurrencyFormatter.format(correctedAmount)}',
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w500,
                            color: colors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '$reason — $correctedBy, $correctedOnLabel.',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: colors.textTertiary,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
