import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nepali_utils/nepali_utils.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/models/loan_status.dart';
import '../../../../core/models/user_role.dart';
import '../../../../core/router/route_paths.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/month_grid_heatmap.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../admin/data/privacy_settings.dart';
import '../../../admin/providers/admin_providers.dart';
import '../../../contributions/providers/contributions_providers.dart';
import '../../../loans/providers/loans_providers.dart';
import '../../data/member_directory_entry.dart';
import '../../providers/members_providers.dart';

enum _MemberFilter { all, current, behind, borrowing }

/// SRS §31 — searchable, filterable community member directory
/// (`design_spec.md` §2a): every row shows what's given and where coverage
/// stands, with an Ahead/Current/Behind status tag, rather than just a name
/// and join date.
class MembersScreen extends ConsumerStatefulWidget {
  const MembersScreen({super.key});

  @override
  ConsumerState<MembersScreen> createState() => _MembersScreenState();
}

class _MembersScreenState extends ConsumerState<MembersScreen> {
  String _query = '';
  _MemberFilter _filter = _MemberFilter.all;

  @override
  Widget build(BuildContext context) {
    final members = ref.watch(membersProvider);
    final borrowerIds =
        ref.watch(outstandingBorrowerIdsProvider).value ?? const <String>{};
    final privacy =
        ref.watch(privacySettingsProvider).value ?? PrivacySettings.defaults;
    final colors = context.colors;

    return Scaffold(
      body: SafeArea(
        child: members.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => AppErrorState(message: '$error'),
          data: (allItems) {
            final searched = _query.isEmpty
                ? allItems
                : allItems
                      .where((m) => m.fullName.toLowerCase().contains(_query))
                      .toList();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.sm,
                    AppSpacing.sm,
                    AppSpacing.lg,
                    0,
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back),
                        onPressed: () => Navigator.of(context).canPop()
                            ? Navigator.of(context).pop()
                            : context.go(RoutePaths.profile),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Members',
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          Text(
                            '${allItems.length} members',
                            style: TextStyle(fontSize: 12.5, color: colors.textTertiary),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.md,
                    AppSpacing.lg,
                    AppSpacing.sm,
                  ),
                  child: Container(
                    height: 46,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: colors.surfaceSunken,
                      borderRadius: BorderRadius.circular(23),
                      border: Border.all(color: colors.neutralRing),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.search, size: 20, color: colors.textTertiary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            style: TextStyle(fontSize: 14, color: colors.textPrimary),
                            decoration: InputDecoration(
                              hintText: 'Search by name',
                              hintStyle: TextStyle(color: colors.textTertiary),
                              filled: false,
                              contentPadding: EdgeInsets.zero,
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              errorBorder: InputBorder.none,
                              disabledBorder: InputBorder.none,
                              isDense: true,
                            ),
                            onChanged: (value) =>
                                setState(() => _query = value.toLowerCase()),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(
                  height: 40,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                    children: [
                      for (final f in _MemberFilter.values)
                        Padding(
                          padding: const EdgeInsets.only(right: AppSpacing.sm),
                          child: ChoiceChip(
                            label: Text(switch (f) {
                              _MemberFilter.all => 'All ${allItems.length}',
                              _MemberFilter.current => 'Current',
                              _MemberFilter.behind => 'Behind',
                              _MemberFilter.borrowing => 'Borrowing',
                            }),
                            selected: _filter == f,
                            onSelected: (_) => setState(() => _filter = f),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Expanded(
                  child: _MemberList(
                    members: searched,
                    filter: _filter,
                    borrowerIds: borrowerIds,
                    showLoanTag: privacy.showActiveLoanStatus,
                  ),
                ),
                if (!privacy.showPhoneNumber)
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Text(
                      'Phone numbers and email addresses are hidden — each '
                      'member chooses whether to share them.',
                      style: TextStyle(fontSize: 11.5, color: colors.textQuaternary),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _MemberList extends ConsumerWidget {
  const _MemberList({
    required this.members,
    required this.filter,
    required this.borrowerIds,
    required this.showLoanTag,
  });

  final List<MemberDirectoryEntry> members;
  final _MemberFilter filter;
  final Set<String> borrowerIds;
  final bool showLoanTag;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (members.isEmpty) {
      return const EmptyState(icon: Icons.people_outline, title: 'No members found');
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.lg,
      ),
      itemCount: members.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.xs),
      itemBuilder: (context, index) {
        final member = members[index];
        return Consumer(
          builder: (context, ref, _) {
            final coverage = ref.watch(
              memberCoverageProvider((
                uid: member.uid,
                memberSince: member.memberSince,
              )),
            );
            final total = ref.watch(
              memberVerifiedContributionsTotalProvider(member.uid),
            );
            final isBorrowing = showLoanTag && borrowerIds.contains(member.uid);

            return coverage.when(
              loading: () => const SizedBox.shrink(),
              error: (_, _) => const SizedBox.shrink(),
              data: (value) {
                final cells = value.currentYearCells;
                final gapMonths = cells
                    .where((c) => c.state == MonthCellState.gap)
                    .length;
                final coveredAheadOfNow = cells.indexed.any(
                  (e) =>
                      e.$2.state == MonthCellState.covered &&
                      e.$1 + 1 > _currentBsMonth(),
                );
                final status = gapMonths > 0
                    ? _CoverageStatus.behind
                    : coveredAheadOfNow
                    ? _CoverageStatus.ahead
                    : _CoverageStatus.current;

                if (filter == _MemberFilter.behind &&
                    status != _CoverageStatus.behind) {
                  return const SizedBox.shrink();
                }
                if (filter == _MemberFilter.current &&
                    status == _CoverageStatus.behind) {
                  return const SizedBox.shrink();
                }
                if (filter == _MemberFilter.borrowing && !isBorrowing) {
                  return const SizedBox.shrink();
                }

                return _MemberRow(
                  member: member,
                  totalGiven: total.value ?? 0,
                  coveredToLabel: value.coveredToLabel,
                  gapMonths: gapMonths,
                  isBorrowing: isBorrowing,
                  status: status,
                );
              },
            );
          },
        );
      },
    );
  }
}

int _currentBsMonth() => NepaliDateTime.now().month;

enum _CoverageStatus { ahead, current, behind }

class _MemberRow extends StatelessWidget {
  const _MemberRow({
    required this.member,
    required this.totalGiven,
    required this.coveredToLabel,
    required this.gapMonths,
    required this.isBorrowing,
    required this.status,
  });

  final MemberDirectoryEntry member;
  final double totalGiven;
  final String? coveredToLabel;
  final int gapMonths;
  final bool isBorrowing;
  final _CoverageStatus status;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final subtitle = [
      'Given ${CurrencyFormatter.format(totalGiven)}',
      if (status == _CoverageStatus.behind)
        '$gapMonths month${gapMonths == 1 ? '' : 's'} behind'
      else if (coveredToLabel != null)
        'covered to $coveredToLabel',
      if (isBorrowing) 'borrowing',
    ].join(' · ');

    final (label, tone) = switch (status) {
      _CoverageStatus.ahead => ('Ahead', StatusTone.positive),
      _CoverageStatus.current => ('Current', StatusTone.neutral),
      _CoverageStatus.behind => ('Behind', StatusTone.negative),
    };

    return Material(
      color: colors.surface,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        leading: CircleAvatar(
          radius: 22,
          backgroundImage: member.photoUrl == null
              ? null
              : NetworkImage(member.photoUrl!),
          child: member.photoUrl == null
              ? Text(member.fullName.isEmpty ? '?' : member.fullName[0])
              : null,
        ),
        title: Row(
          children: [
            Flexible(child: Text(member.fullName, overflow: TextOverflow.ellipsis)),
            if (member.role != UserRole.member) ...[
              const SizedBox(width: 6),
              Text(
                member.role == UserRole.superAdmin ? 'super admin' : 'admin',
                style: TextStyle(fontSize: 11, color: colors.accentLight),
              ),
            ],
          ],
        ),
        subtitle: Text(subtitle, style: TextStyle(fontSize: 12, color: colors.textTertiary)),
        trailing: StatusBadge(label: label, tone: tone),
        onTap: () => context.push(RoutePaths.memberDetail(member.uid)),
      ),
    );
  }
}
