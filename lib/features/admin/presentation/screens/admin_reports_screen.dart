import 'package:flutter/material.dart';

import '../../../reports/presentation/screens/reports_screen.dart';
import '../widgets/admin_more_menu.dart';

/// Reuses [ReportsView] (member Reports screen's body) with the admin app
/// bar / overflow menu — the report content itself is identical, only the
/// chrome differs.
class AdminReportsScreen extends StatelessWidget {
  const AdminReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports'),
        actions: const [AdminMoreMenu()],
      ),
      body: const ReportsView(),
    );
  }
}
