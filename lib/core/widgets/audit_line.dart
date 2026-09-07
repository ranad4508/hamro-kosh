import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../utils/bs_date_formatter.dart';
import '../../features/admin/data/audit_log_entry.dart';

/// The design's "what changed" audit-line caption (`design_spec.md` §2,
/// pattern 9): "Actor · date · reason", shown beneath any admin-editable
/// value so a rule change is never silent (SRS §39/§40).
class AuditLine extends StatelessWidget {
  const AuditLine({super.key, required this.entry, this.actorName});

  final AuditLogEntry entry;

  /// `entry.performedBy` is a uid, not a display name (see
  /// `AuditLogEntry`'s doc comment) — pass the resolved member name here
  /// (e.g. via the members directory) when available; falls back to the
  /// raw id otherwise so this widget never crashes on a missing lookup.
  final String? actorName;

  @override
  Widget build(BuildContext context) {
    final reasonMatch = RegExp(r'["“](.+?)["”]').firstMatch(entry.action);
    final reason = reasonMatch?.group(1);
    final colors = context.colors;

    return RichText(
      text: TextSpan(
        style: TextStyle(fontSize: 11, color: colors.textQuaternary),
        children: [
          TextSpan(
            text: actorName ?? entry.performedBy,
            style: TextStyle(color: colors.textTertiary),
          ),
          TextSpan(text: ' · ${BsDateFormatter.full(entry.timestamp)}'),
          if (reason != null) TextSpan(text: ' · "$reason"'),
        ],
      ),
    );
  }
}
