import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../reports/data/report_csv_export.dart';
import '../../../reports/presentation/screens/reports_screen.dart';
import '../widgets/admin_more_menu.dart';

/// Reuses [ReportsView] (member Reports screen's body) with the admin app
/// bar / overflow menu — the report content itself is identical, only the
/// chrome differs.
class AdminReportsScreen extends ConsumerWidget {
  const AdminReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports'),
        actions: [
          IconButton(
            tooltip: 'Export CSV',
            icon: const Icon(Icons.ios_share_outlined),
            onPressed: () => exportFundReportCsv(ref, context),
          ),
          const AdminMoreMenu(),
        ],
      ),
      body: const ReportsView(),
    );
  }
}
