import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/adaptive_scaffold.dart';

const _destinations = [
  AdaptiveDestination(label: 'Home', icon: Icons.home_outlined, selectedIcon: Icons.home),
  AdaptiveDestination(label: 'Fund', icon: Icons.account_balance_outlined, selectedIcon: Icons.account_balance),
  AdaptiveDestination(label: 'Loans', icon: Icons.request_quote_outlined, selectedIcon: Icons.request_quote),
  AdaptiveDestination(label: 'Members', icon: Icons.people_outline, selectedIcon: Icons.people),
  AdaptiveDestination(label: 'Profile', icon: Icons.person_outline, selectedIcon: Icons.person),
];

/// SRS §52 — Member app shell: Home / Fund / Loans / Members / Profile.
/// Contributions, Transactions, Reports, and Notifications are reached from
/// Home's quick actions and the Profile menu rather than crowding a sixth
/// or seventh bottom-nav tab (Material's own guidance caps a bar at ~5).
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
