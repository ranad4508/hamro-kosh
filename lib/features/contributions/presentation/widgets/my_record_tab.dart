import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nepali_utils/nepali_utils.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/models/loan_status.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/bs_date_formatter.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/full_screen_image_viewer.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../../core/models/contribution_type.dart';
import '../../../auth/providers/auth_providers.dart';
import '../../providers/contributions_providers.dart';

/// `design_spec.md` §2f — "My record": the member's own 2-year month-grid
/// coverage (with the actual amount paid per month, not just a coverage
/// state) plus every payment, verified or not.
class MyRecordTab extends ConsumerWidget {
  const MyRecordTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contributions = ref.watch(myContributionsProvider);

    return contributions.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => AppErrorState(message: '$error'),
      data: (items) {
        if (items.isEmpty) {
          return const EmptyState(
            icon: Icons.calendar_month_outlined,
            title: 'No payments recorded yet',
          );
        }

        final verified = items
            .where((c) => c.status == ContributionStatus.verified)
            .toList();
        final givenTotal = verified.fold<double>(0, (s, c) => s + c.amount);

        // Distribute each monthly payment's amount evenly across the months
        // it covers, so a 5-month catch-up payment doesn't read as one huge
        // number sitting in a single cell.
        final amountByMonth = <(int, int), double>{};
        for (final c in verified.where(
          (c) => c.category == ContributionCategory.monthly,
        )) {
          final start = c.date.toNepaliDateTime();
          final perMonth = c.amount / c.monthsCovered;
          var y = start.year;
          var m = start.month;
          for (var i = 0; i < c.monthsCovered; i++) {
            amountByMonth[(y, m)] = (amountByMonth[(y, m)] ?? 0) + perMonth;
            m++;
            if (m > 12) {
              m = 1;
              y++;
            }
          }
        }

        final now = NepaliDateTime.now();
        final years = [now.year, now.year - 1];
        final monthsSinceJoin = ref.watch(userProfileProvider).value?.memberSince;
        var totalMonths = 12;
        if (monthsSinceJoin != null) {
          final since = monthsSinceJoin.toNepaliDateTime();
          totalMonths =
              ((now.year - since.year) * 12 + (now.month - since.month) + 1)
                  .clamp(1, 999);
        }
        final coveredMonths = amountByMonth.keys.length;

        return ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            Row(
              children: [
                _StatCell('Given', CurrencyFormatter.format(givenTotal)),
                _StatCell('Payments', '${verified.length}'),
                _StatCell('Months', '$coveredMonths/$totalMonths'),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            for (final year in years) ...[
              Text('$year', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: AppSpacing.sm),
              _YearGrid(
                year: year,
                isCurrentYear: year == now.year,
                currentMonth: now.month,
                amountByMonth: amountByMonth,
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
            Text('Every payment', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: AppSpacing.sm),
            Material(
              color: context.colors.surface,
              borderRadius: BorderRadius.circular(12),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  for (var i = 0; i < items.length; i++) ...[
                    if (i > 0) Divider(height: 1, color: context.colors.divider),
                    ListTile(
                      onTap: items[i].proofUrl == null
                          ? null
                          : () => showFullScreenImage(context, items[i].proofUrl!),
                      title: Text(
                        '${CurrencyFormatter.format(items[i].amount)} · '
                        '${items[i].occasionName ?? BsDateFormatter.monthYear(items[i].date)}',
                      ),
                      subtitle: Text(
                        [
                          items[i].paymentMethod,
                          items[i].reference,
                        ].whereType<String>().join(' · '),
                        style: TextStyle(fontSize: 11.5, color: context.colors.textTertiary),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (items[i].proofUrl != null) ...[
                            Icon(Icons.attachment, size: 16, color: context.colors.textTertiary),
                            const SizedBox(width: 6),
                          ],
                          items[i].category == ContributionCategory.special
                              ? const StatusBadge(label: 'Special', tone: StatusTone.neutral)
                              : StatusBadge(
                                  label: items[i].status.label(context),
                                  tone: items[i].status.tone,
                                ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _StatCell extends StatelessWidget {
  const _StatCell(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Expanded(
      child: Container(
        margin: const EdgeInsets.only(right: AppSpacing.sm),
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(fontSize: 10.5, color: colors.textQuaternary)),
            const SizedBox(height: 2),
            Text(value, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
          ],
        ),
      ),
    );
  }
}

class _YearGrid extends StatelessWidget {
  const _YearGrid({
    required this.year,
    required this.isCurrentYear,
    required this.currentMonth,
    required this.amountByMonth,
  });

  final int year;
  final bool isCurrentYear;
  final int currentMonth;
  final Map<(int, int), double> amountByMonth;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 12,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 6,
        mainAxisSpacing: 6,
        crossAxisSpacing: 6,
        childAspectRatio: 0.95,
      ),
      itemBuilder: (context, index) {
        final monthNum = index + 1;
        final amount = amountByMonth[(year, monthNum)];
        final isPast = !isCurrentYear || monthNum <= currentMonth;
        final colors = context.colors;

        final Color bg;
        final Color fg;
        String? sub;
        if (amount != null) {
          bg = colors.accentDark3;
          fg = colors.textPrimary;
          sub = amount.toStringAsFixed(0);
        } else if (isPast) {
          bg = colors.surfaceSunken;
          fg = colors.textTertiary;
          sub = 'gap';
        } else {
          bg = colors.bg;
          fg = colors.textQuaternary;
          sub = '—';
        }

        return Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(6),
            border: amount == null && isPast
                ? Border.all(color: colors.accentDark1)
                : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                BsDateFormatter.monthAbbreviations[index],
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: fg),
              ),
              Text(sub, style: TextStyle(fontSize: 9, color: fg)),
            ],
          ),
        );
      },
    );
  }
}
