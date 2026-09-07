import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/models/user_role.dart';
import '../../../../core/router/route_paths.dart';
import '../../../../core/services/csv_export_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../../core/models/loan_status.dart';
import '../../../auth/providers/auth_providers.dart';
import '../../../members/data/member_directory_entry.dart';
import '../../../members/providers/members_providers.dart';
import '../widgets/admin_more_menu.dart';

/// SRS §35 — manage members, handle approvals, edit details, and soft-delete.
class AdminMembersScreen extends ConsumerStatefulWidget {
  const AdminMembersScreen({super.key});

  @override
  ConsumerState<AdminMembersScreen> createState() => _AdminMembersScreenState();
}

class _AdminMembersScreenState extends ConsumerState<AdminMembersScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final members = ref.watch(allMembersProvider);
    final viewerIsSuperAdmin =
        ref.watch(userProfileProvider).value?.role == UserRole.superAdmin;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Manage Members'),
          actions: [
            IconButton(
              tooltip: 'Export CSV',
              icon: const Icon(Icons.ios_share_outlined),
              onPressed: () async {
                final items = members.value;
                if (items == null || items.isEmpty) return;
                await _exportMembersCsv(context, items);
              },
            ),
            const AdminMoreMenu(),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(100),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  child: Builder(
                    builder: (context) {
                      final colors = context.colors;
                      return Container(
                        height: 40,
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          color: colors.surfaceSunken,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: colors.neutralRing),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.search, size: 18, color: colors.textTertiary),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                style: TextStyle(fontSize: 14, color: colors.textPrimary),
                                decoration: InputDecoration(
                                  hintText: 'Search members',
                                  hintStyle: TextStyle(color: colors.textTertiary),
                                  filled: false,
                                  contentPadding: EdgeInsets.zero,
                                  border: InputBorder.none,
                                  isDense: true,
                                ),
                                onChanged: (value) =>
                                    setState(() => _query = value.toLowerCase()),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                const TabBar(
                  tabs: [
                    Tab(text: 'Members'),
                    Tab(text: 'Pending'),
                  ],
                ),
              ],
            ),
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          heroTag: 'admin_members_fab',
          onPressed: () => context.push(RoutePaths.adminCreateUser),
          icon: const Icon(Icons.person_add_alt_1_outlined),
          label: const Text('Create account'),
        ),
        body: TabBarView(
          children: [
            _MembersTab(
              query: _query,
              members: members,
              viewerIsSuperAdmin: viewerIsSuperAdmin,
            ),
            _PendingApprovalsTab(viewerIsSuperAdmin: viewerIsSuperAdmin),
          ],
        ),
      ),
    );
  }
}

class _MembersTab extends ConsumerWidget {
  const _MembersTab({
    required this.query,
    required this.members,
    required this.viewerIsSuperAdmin,
  });

  final String query;
  final AsyncValue<List<MemberDirectoryEntry>> members;
  final bool viewerIsSuperAdmin;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return members.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => AppErrorState(message: '$error'),
      data: (allItems) {
        final visibleItems = viewerIsSuperAdmin
            ? allItems
            : allItems.where((m) => m.role == UserRole.member).toList();

        if (visibleItems.isEmpty) {
          return const EmptyState(
            icon: Icons.people_outline,
            title: 'No members yet',
          );
        }
        final items = query.isEmpty
            ? visibleItems
            : visibleItems
                .where((m) => m.fullName.toLowerCase().contains(query))
                .toList();
        
        if (items.isEmpty) {
          return const EmptyState(
            icon: Icons.search_off,
            title: 'No matching members',
          );
        }
        
        final admins = items.where((m) => m.role == UserRole.admin).toList();
        final regularMembers = items.where((m) => m.role == UserRole.member).toList();

        return ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            if (admins.isNotEmpty) ...[
              Text('Admins', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: AppSpacing.sm),
              for (final member in admins)
                _MemberTile(
                  member: member,
                  viewerIsSuperAdmin: viewerIsSuperAdmin,
                ),
              const SizedBox(height: AppSpacing.lg),
            ],
            Text('Members', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: AppSpacing.sm),
            for (final member in regularMembers)
              _MemberTile(
                member: member,
                viewerIsSuperAdmin: viewerIsSuperAdmin,
              ),
          ],
        );
      },
    );
  }
}

class _PendingApprovalsTab extends ConsumerWidget {
  const _PendingApprovalsTab({required this.viewerIsSuperAdmin});
  final bool viewerIsSuperAdmin;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pending = ref.watch(pendingMembersProvider);
    final repo = ref.read(membersRepositoryProvider);
    final currentUid = ref.read(authStateProvider).value?.uid ?? '';

    return pending.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => AppErrorState(message: '$error'),
      data: (items) {
        if (items.isEmpty) {
          return const EmptyState(
            icon: Icons.person_search_outlined,
            title: 'No pending approvals',
            message: 'New registrations needing review will appear here.',
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(AppSpacing.lg),
          itemCount: items.length,
          separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
          itemBuilder: (context, index) {
            final member = items[index];
            return Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  children: [
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        backgroundImage: member.photoUrl == null
                            ? null
                            : NetworkImage(member.photoUrl!),
                        child: member.photoUrl == null
                            ? Text(member.fullName[0])
                            : null,
                      ),
                      title: Text(member.fullName),
                      subtitle: Text('Registered ${DateFormatter.relative(member.memberSince)}'),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => repo.setApprovedWithAudit(
                              uid: member.uid,
                              approved: false,
                              memberName: member.fullName,
                              performedBy: currentUid,
                            ),
                            child: const Text('Reject'),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: FilledButton(
                            onPressed: () => repo.setApprovedWithAudit(
                              uid: member.uid,
                              approved: true,
                              memberName: member.fullName,
                              performedBy: currentUid,
                            ),
                            child: const Text('Approve'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _MemberTile extends ConsumerWidget {
  const _MemberTile({required this.member, required this.viewerIsSuperAdmin});

  final MemberDirectoryEntry member;
  final bool viewerIsSuperAdmin;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.read(membersRepositoryProvider);
    final currentUid = ref.read(authStateProvider).value?.uid ?? '';

    Future<void> run(
      Future<void> Function() action, {
      required String successMessage,
    }) async {
      try {
        await action();
        if (context.mounted) {
          AppSnackbar.showSuccess(
            context,
            title: 'Updated',
            message: successMessage,
          );
        }
      } catch (_) {
        if (context.mounted) {
          AppSnackbar.showError(
            context,
            title: 'Could not update member',
            message: 'Something went wrong. Please try again.',
          );
        }
      }
    }

    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage: member.photoUrl == null
              ? null
              : NetworkImage(member.photoUrl!),
          child: member.photoUrl == null
              ? Text(member.fullName.isEmpty ? '?' : member.fullName[0])
              : null,
        ),
        title: Text(member.fullName),
        subtitle: Text(
          member.role == UserRole.admin
              ? 'Admin • since ${DateFormatter.monthYear(member.memberSince)}'
              : 'Member since ${DateFormatter.monthYear(member.memberSince)}',
        ),
        onTap: () => context.push(RoutePaths.memberDetail(member.uid)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            StatusBadge(
              label: member.isActive ? 'Active' : 'Disabled',
              tone: member.isActive ? StatusTone.positive : StatusTone.negative,
            ),
            PopupMenuButton<String>(
              onSelected: (value) async {
                if (value == 'activate' || value == 'deactivate') {
                  final active = value == 'activate';
                  run(
                    () => repo.setActiveWithAudit(
                      uid: member.uid,
                      active: active,
                      memberName: member.fullName,
                      performedBy: currentUid,
                    ),
                    successMessage:
                        '${member.fullName} ${active ? 'activated' : 'deactivated'}.',
                  );
                } else if (value == 'make_admin' || value == 'make_member') {
                  final role = value == 'make_admin' ? UserRole.admin : UserRole.member;
                  run(
                    () => repo.setRoleWithAudit(
                      uid: member.uid,
                      role: role,
                      memberName: member.fullName,
                      performedBy: currentUid,
                    ),
                    successMessage: '${member.fullName} is now a ${role.name}.',
                  );
                } else if (value == 'edit') {
                  context.push(RoutePaths.adminEditUser, extra: member);
                } else if (value == 'delete') {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Delete Member?'),
                      content: Text(
                        'Are you sure you want to delete ${member.fullName}? '
                        'Their account will be deactivated and hidden, but '
                        'their financial records will be preserved for the audit trail.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          style: TextButton.styleFrom(
                            foregroundColor: Theme.of(context).colorScheme.error,
                          ),
                          child: const Text('Delete'),
                        ),
                      ],
                    ),
                  );
                  if (confirm == true) {
                    run(
                      () => repo.deleteMemberWithAudit(
                        uid: member.uid,
                        memberName: member.fullName,
                        performedBy: currentUid,
                      ),
                      successMessage: '${member.fullName} has been deleted.',
                    );
                  }
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'edit', child: Text('Edit Profile')),
                if (member.isActive)
                  const PopupMenuItem(value: 'deactivate', child: Text('Deactivate'))
                else
                  const PopupMenuItem(value: 'activate', child: Text('Activate')),
                
                if (viewerIsSuperAdmin && member.uid != currentUid) ...[
                  const PopupMenuDivider(),
                  if (member.role == UserRole.member)
                    const PopupMenuItem(value: 'make_admin', child: Text('Make Admin'))
                  else
                    const PopupMenuItem(value: 'make_member', child: Text('Make Member')),
                ],
                const PopupMenuDivider(),
                const PopupMenuItem(
                  value: 'delete',
                  child: Text('Delete', style: TextStyle(color: Colors.red)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// SRS §43 — exports the member list as CSV.
Future<void> _exportMembersCsv(
  BuildContext context,
  List<MemberDirectoryEntry> items,
) async {
  final rows = <List<dynamic>>[
    ['Full name', 'Role', 'Phone', 'Member since', 'Active'],
    for (final m in items)
      [
        m.fullName,
        m.role.name,
        m.phone ?? '',
        DateFormatter.shortDate(m.memberSince),
        m.isActive ? 'Yes' : 'No',
      ],
  ];
  await CsvExportService.exportAndShare(
    fileName:
        'hamro_kosh_members_${DateTime.now().toIso8601String().split('T').first}.csv',
    rows: rows,
    shareText: 'Hamro Kosh member list export',
  );
  if (context.mounted) {
    AppSnackbar.showSuccess(
      context,
      title: 'Export ready',
      message: '${items.length} members exported.',
    );
  }
}
