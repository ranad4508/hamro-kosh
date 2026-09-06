import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/adaptive_scaffold.dart';

const _destinations = [
  AdaptiveDestination(label: 'Dashboard', icon: Icons.dashboard_outlined, selectedIcon: Icons.dashboard),
  AdaptiveDestination(label: 'Members', icon: Icons.people_outline, selectedIcon: Icons.people),
  AdaptiveDestination(label: 'Loans', icon: Icons.request_quote_outlined, selectedIcon: Icons.request_quote),
  AdaptiveDestination(label: 'Fund', icon: Icons.account_balance_outlined, selectedIcon: Icons.account_balance),
  AdaptiveDestination(label: 'Reports', icon: Icons.bar_chart_outlined, selectedIcon: Icons.bar_chart),
];

/// SRS §53 — Admin app shell: Dashboard / Members / Loans / Fund / Reports.
/// Contributions management lives inside the Fund tab; Notifications,
/// Settings, and Audit are reached via [AdminMoreMenu] in each screen's
/// app bar.
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
