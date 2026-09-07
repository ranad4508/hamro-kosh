import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/models/contribution_type.dart';
import '../../../../core/services/cloud_functions_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../members/data/member_directory_entry.dart';
import '../../../members/providers/members_providers.dart';

/// `design_spec.md` §5e — "Record a payment": cash handed directly to an
/// admin, or an older cash-book entry being brought into the app. The
/// receiving admin's own identity is the proof, so there's no screenshot —
/// instead a note for the audit trail is mandatory, and the entry lands
/// straight in the ledger as verified (`recordContributionManually` in
/// functions/index.js), the same way an ordinary verification would.
class AdminRecordContributionScreen extends ConsumerStatefulWidget {
  const AdminRecordContributionScreen({super.key});

  @override
  ConsumerState<AdminRecordContributionScreen> createState() =>
      _AdminRecordContributionScreenState();
}

class _AdminRecordContributionScreenState
    extends ConsumerState<AdminRecordContributionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amount = TextEditingController(text: '1');
  final _monthsCovered = TextEditingController(text: '1');
  final _note = TextEditingController();
  MemberDirectoryEntry? _member;
  ContributionCategory _category = ContributionCategory.monthly;
  DateTime _date = DateTime.now();
  bool _submitting = false;

  @override
  void dispose() {
    _amount.dispose();
    _monthsCovered.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _pickMember() async {
    final members = ref.read(allMembersProvider).value ?? const [];
    final selected = await showModalBottomSheet<MemberDirectoryEntry>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => _MemberPickerSheet(members: members),
    );
    if (selected != null) setState(() => _member = selected);
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_member == null) {
      AppSnackbar.showError(
        context,
        title: 'Choose a member',
        message: 'Pick which member this payment belongs to.',
      );
      return;
    }
    setState(() => _submitting = true);
    try {
      await ref
          .read(cloudFunctionsServiceProvider)
          .recordContributionManually(
            memberUid: _member!.uid,
            amount: double.parse(_amount.text.trim()),
            monthsCovered: _category == ContributionCategory.special
                ? 1
                : int.tryParse(_monthsCovered.text.trim()) ?? 1,
            date: _date,
            note: _note.text.trim(),
            category: _category.name,
          );
      if (mounted) {
        Navigator.of(context).pop();
        AppSnackbar.showSuccess(
          context,
          title: 'Recorded',
          message:
              'This appears in the public ledger straight away, marked no '
              'proof — recorded by you.',
        );
      }
    } on CloudFunctionsApiException catch (e) {
      if (mounted) {
        AppSnackbar.showError(
          context,
          title: 'Could not record this',
          message: e.message,
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      appBar: AppBar(title: const Text('Record a payment')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: colors.surfaceSunken,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: colors.accentDark1),
              ),
              child: Text(
                'You are the proof here. Notes taken in your hand, or a '
                'payment already in the cash book, need no screenshot. The '
                'entry goes straight into the ledger with your name on it — '
                "you then bank the cash into the fund's own account.",
                style: TextStyle(fontSize: 12.5, color: colors.textSecondary, height: 1.5),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text('Which member', style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: AppSpacing.xs),
            InkWell(
              onTap: _pickMember,
              borderRadius: BorderRadius.circular(9),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
                decoration: BoxDecoration(
                  color: colors.surfaceSunken,
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(color: colors.neutralRing),
                ),
                child: Row(
                  children: [
                    Icon(Icons.person_outline, color: colors.textSecondary, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _member?.fullName ?? 'Select a member',
                        style: TextStyle(
                          color: _member == null ? colors.textTertiary : colors.textPrimary,
                        ),
                      ),
                    ),
                    Icon(Icons.expand_more, color: colors.textQuaternary),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text('Category', style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: AppSpacing.xs),
            SegmentedButton<ContributionCategory>(
              segments: ContributionCategory.values
                  .map((c) => ButtonSegment(value: c, label: Text(c.label)))
                  .toList(),
              selected: {_category},
              onSelectionChanged: (s) => setState(() => _category = s.first),
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              label: 'Amount (NPR)',
              controller: _amount,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              prefixText: 'Rs. ',
              validator: Validators.positiveAmount,
            ),
            if (_category == ContributionCategory.monthly) ...[
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                label: 'Months this settles',
                controller: _monthsCovered,
                keyboardType: TextInputType.number,
                validator: (v) {
                  final n = int.tryParse((v ?? '').trim());
                  if (n == null || n < 1) return 'Enter at least 1 month';
                  return null;
                },
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            Text('Date received', style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: AppSpacing.xs),
            InkWell(
              onTap: _pickDate,
              borderRadius: BorderRadius.circular(9),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
                decoration: BoxDecoration(
                  color: colors.surfaceSunken,
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(color: colors.neutralRing),
                ),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today_outlined, color: colors.textSecondary, size: 18),
                    const SizedBox(width: 10),
                    Text(DateFormatter.shortDate(_date)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              label: 'Note for the audit trail (required)',
              controller: _note,
              maxLines: 2,
              validator: (v) => (v == null || v.trim().length < 3)
                  ? 'Say where this payment came from'
                  : null,
            ),
            const SizedBox(height: AppSpacing.xl),
            AppButton(
              label: 'Record in the ledger',
              isLoading: _submitting,
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }
}

class _MemberPickerSheet extends StatefulWidget {
  const _MemberPickerSheet({required this.members});
  final List<MemberDirectoryEntry> members;

  @override
  State<_MemberPickerSheet> createState() => _MemberPickerSheetState();
}

class _MemberPickerSheetState extends State<_MemberPickerSheet> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final filtered = _query.isEmpty
        ? widget.members
        : widget.members
              .where((m) => m.fullName.toLowerCase().contains(_query))
              .toList();

    return SafeArea(
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.7,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.sm,
              ),
              child: SearchBar(
                hintText: 'Search members',
                leading: const Icon(Icons.search),
                onChanged: (v) => setState(() => _query = v.toLowerCase()),
              ),
            ),
            Expanded(
              child: filtered.isEmpty
                  ? const EmptyState(icon: Icons.search_off, title: 'No matching members')
                  : ListView.builder(
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final member = filtered[index];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundImage: member.photoUrl == null
                                ? null
                                : NetworkImage(member.photoUrl!),
                            child: member.photoUrl == null
                                ? Text(member.fullName.isEmpty ? '?' : member.fullName[0])
                                : null,
                          ),
                          title: Text(member.fullName),
                          onTap: () => Navigator.of(context).pop(member),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
