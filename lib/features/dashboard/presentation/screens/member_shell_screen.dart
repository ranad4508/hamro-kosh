import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/adaptive_scaffold.dart';

const _destinations = [
  AdaptiveDestination(
    label: 'Home',
    icon: Icons.home_outlined,
    selectedIcon: Icons.home,
  ),
  AdaptiveDestination(
    label: 'Ledger',
    icon: Icons.receipt_long_outlined,
    selectedIcon: Icons.receipt_long,
  ),
  AdaptiveDestination(
    label: 'Give',
    icon: Icons.volunteer_activism_outlined,
    selectedIcon: Icons.volunteer_activism,
  ),
  AdaptiveDestination(
    label: 'Loans',
    icon: Icons.request_quote_outlined,
    selectedIcon: Icons.request_quote,
  ),
  AdaptiveDestination(
    label: 'Members',
    icon: Icons.people_outline,
    selectedIcon: Icons.people,
  ),
];

/// Member app shell: Home / Ledger / Give / Loans / Members
/// (`design_spec.md` §2's member `.tb` tab list — matches the design's
/// 5-tab bottom bar rather than the underlying SRS §52's nine top-level
/// sections; Fund's summary content lives on Home, and Contributions/
/// Transactions/Reports/Notifications/Profile are reached from Home's
/// quick actions and each screen's header rather than crowding a sixth or
/// seventh bottom-nav tab.
class MemberShellScreen extends StatelessWidget {
  const MemberShellScreen({super.key, required this.navigationShell});

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
