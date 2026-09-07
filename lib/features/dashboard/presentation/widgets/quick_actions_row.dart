import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/router/route_paths.dart';

class _QuickAction {
  const _QuickAction(this.label, this.icon, this.path);
  final String label;
  final IconData icon;
  final String path;
}

const _actions = [
  _QuickAction(
    'Contributions',
    Icons.volunteer_activism_outlined,
    RoutePaths.contributions,
  ),
  _QuickAction(
    'Request loan',
    Icons.request_quote_outlined,
    RoutePaths.loanRequest,
  ),
  _QuickAction('Reports', Icons.bar_chart_outlined, RoutePaths.reports),
  _QuickAction('Ledger', Icons.receipt_long_outlined, RoutePaths.transactions),
];

/// Dashboard shortcut row surfacing the sections that don't have their own
/// bottom-nav tab (Contributions, Reports, full ledger) per SRS §52.
class QuickActionsRow extends StatelessWidget {
  const QuickActionsRow({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 84,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _actions.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, index) {
          final action = _actions[index];
          return SizedBox(
            width: 88,
            child: Card(
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => context.push(action.path),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      action.icon,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      action.label,
                      style: Theme.of(context).textTheme.labelSmall,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
