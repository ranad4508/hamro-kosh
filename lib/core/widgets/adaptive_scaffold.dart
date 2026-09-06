import 'package:flutter/material.dart';

import '../constants/app_sizes.dart';

/// A navigation destination shared between the bottom bar and rail
/// renderings of [AdaptiveScaffold].
class AdaptiveDestination {
  const AdaptiveDestination({
    required this.label,
    required this.icon,
    required this.selectedIcon,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
}

/// Switches between a phone-style [NavigationBar] and a tablet/desktop
/// [NavigationRail] based on available width, per Material adaptive-layout
/// guidance. Used for both the Member shell and the Admin shell so the two
/// don't each reimplement responsive navigation.
class AdaptiveScaffold extends StatelessWidget {
  const AdaptiveScaffold({
    super.key,
    required this.destinations,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.body,
    this.floatingActionButton,
    this.trailing,
  });

  final List<AdaptiveDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final Widget body;
  final Widget? floatingActionButton;

  /// Extra content pinned below the rail destinations (e.g. an admin
  /// "More" menu button) — only shown in the rail layout.
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.sizeOf(context).width >= AppBreakpoints.compact;

    if (!isWide) {
      return Scaffold(
        body: body,
        floatingActionButton: floatingActionButton,
        bottomNavigationBar: NavigationBar(
          selectedIndex: selectedIndex,
          onDestinationSelected: onDestinationSelected,
          destinations: [
            for (final destination in destinations)
              NavigationDestination(
                icon: Icon(destination.icon),
                selectedIcon: Icon(destination.selectedIcon),
                label: destination.label,
              ),
          ],
        ),
      );
    }

    return Scaffold(
      body: Row(
        children: [
          SafeArea(
            child: NavigationRail(
              selectedIndex: selectedIndex,
              onDestinationSelected: onDestinationSelected,
              labelType: NavigationRailLabelType.all,
              leading: floatingActionButton == null
                  ? null
                  : Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: floatingActionButton,
                    ),
              trailing: trailing == null
                  ? null
                  : Expanded(
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.md),
                          child: trailing,
                        ),
                      ),
                    ),
              destinations: [
                for (final destination in destinations)
                  NavigationRailDestination(
                    icon: Icon(destination.icon),
                    selectedIcon: Icon(destination.selectedIcon),
                    label: Text(destination.label),
                  ),
              ],
            ),
          ),
          const VerticalDivider(width: 1),
          Expanded(child: body),
        ],
      ),
    );
  }
}
