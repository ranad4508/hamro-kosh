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
    'Request loan',
    Icons.request_quote_outlined,
    RoutePaths.loanRequest,
  ),
  _QuickAction('Reports', Icons.bar_chart_outlined, RoutePaths.reports),
  _QuickAction(
    'Notifications',
    Icons.notifications_outlined,
    RoutePaths.notifications,
  ),
];

/// Dashboard shortcut row surfacing sections that don't have their own
/// bottom-nav tab (per SRS §52) — Give and Ledger moved to tabs of their
/// own (`design_spec.md` §2), so this row no longer duplicates them.
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
