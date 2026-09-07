import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/adaptive_scaffold.dart';

const _destinations = [
  AdaptiveDestination(
    label: 'Dashboard',
    icon: Icons.dashboard_outlined,
    selectedIcon: Icons.dashboard,
  ),
  AdaptiveDestination(
    label: 'Members',
    icon: Icons.people_outline,
    selectedIcon: Icons.people,
  ),
  AdaptiveDestination(
    label: 'Loans',
    icon: Icons.request_quote_outlined,
    selectedIcon: Icons.request_quote,
  ),
  AdaptiveDestination(
    label: 'Fund',
    icon: Icons.account_balance_outlined,
    selectedIcon: Icons.account_balance,
  ),
  AdaptiveDestination(
    label: 'More',
    icon: Icons.more_horiz,
    selectedIcon: Icons.more_horiz,
  ),
];

/// Admin app shell: Dashboard / Members / Loans / Fund / More
/// (`design_spec.md` §2's admin `.tb` tab list). "More" lands on Fund
/// rules & the audit trail (screen `3d`); Reports, Notifications,
/// Campaigns, Disputes, and Privacy settings are reached via
/// [AdminMoreMenu] in each screen's app bar.
class AdminShellScreen extends StatelessWidget {
  const AdminShellScreen({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return AdaptiveScaffold(
      destinations: _destinations,
      selectedIndex: navigationShell.currentIndex,
      onDestinationSelected: (index) => navigationShell.goBranch(
        index,
        initialLocation: index == navigationShell.currentIndex,
      ),
      body: navigationShell,
    );
  }
}
