import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_paths.dart';

/// SRS §53 — Notifications / Settings / Audit sit off this overflow menu
/// rather than on the admin bottom bar, which is already at the
/// recommended 5-destination maximum (Dashboard, Members, Loans, Fund,
/// Reports).
class AdminMoreMenu extends StatelessWidget {
  const AdminMoreMenu({super.key});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert),
      onSelected: (path) => context.push(path),
      itemBuilder: (context) => const [
        PopupMenuItem(
          value: RoutePaths.adminNotifications,
          child: ListTile(
            leading: Icon(Icons.notifications_outlined),
            title: Text('Notifications'),
          ),
        ),
        PopupMenuItem(
          value: RoutePaths.adminCampaigns,
          child: ListTile(
            leading: Icon(Icons.campaign_outlined),
            title: Text('Campaigns'),
          ),
        ),
        PopupMenuItem(
          value: RoutePaths.adminDisputes,
          child: ListTile(
            leading: Icon(Icons.report_problem_outlined),
            title: Text('Disputes'),
          ),
        ),
        PopupMenuItem(
          value: RoutePaths.adminSettings,
          child: ListTile(
            leading: Icon(Icons.settings_outlined),
            title: Text('System settings'),
          ),
        ),
        PopupMenuItem(
          value: RoutePaths.adminPrivacySettings,
          child: ListTile(
            leading: Icon(Icons.privacy_tip_outlined),
            title: Text('Privacy settings'),
          ),
        ),
        PopupMenuItem(
          value: RoutePaths.adminAudit,
          child: ListTile(
            leading: Icon(Icons.history_outlined),
            title: Text('Audit trail'),
          ),
        ),
      ],
    );
  }
}
