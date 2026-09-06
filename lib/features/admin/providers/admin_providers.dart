import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/audit_log_entry.dart';
import '../data/audit_repository.dart';
import '../data/fund_rules.dart';
import '../data/fund_rules_repository.dart';

final fundRulesRepositoryProvider = Provider<FundRulesRepository>((ref) {
  return FundRulesRepository(FirebaseFirestore.instance);
});

final fundRulesProvider = StreamProvider<FundRules>((ref) {
  return ref.watch(fundRulesRepositoryProvider).watch();
});

final auditRepositoryProvider = Provider<AuditRepository>((ref) {
  return AuditRepository(FirebaseFirestore.instance);
});

final auditLogProvider = StreamProvider<List<AuditLogEntry>>((ref) {
  return ref.watch(auditRepositoryProvider).watchLog();
});
