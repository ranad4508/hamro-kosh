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
    label: 'Profile',
    icon: Icons.person_outline,
    selectedIcon: Icons.person,
  ),
];

/// Member app shell: Home / Ledger / Give / Loans / Profile. The 5th tab
/// used to be a read-only Members directory (`design_spec.md` §2's member
/// `.tb` tab list draws it that way) — per explicit product feedback this
/// was swapped for a Profile/More tab instead, matching the admin shell's
/// own "More" tab pattern: an account hub with every other member action
/// (edit profile, settings, terms, the members directory, disputes,
/// walkthrough) as menu rows, rather than a tab of its own. Fund's summary
/// content lives on Home, and Contributions/Transactions/Reports/
/// Notifications are reached from Home's quick actions and each screen's
/// header rather than crowding a sixth or seventh bottom-nav tab.
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
