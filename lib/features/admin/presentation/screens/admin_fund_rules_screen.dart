import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/models/loan_category.dart';
import '../../../../core/router/route_paths.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/audit_line.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/proof_picker.dart';
import '../../../auth/providers/auth_providers.dart';
import '../../../fund/data/fund_account.dart';
import '../../../fund/providers/fund_providers.dart';
import '../../../members/providers/members_providers.dart';
import '../../data/audit_log_entry.dart';
import '../../data/fund_rules.dart';
import '../../providers/admin_providers.dart';

/// Reached from the admin "More" screen's "Fund rules & account" menu item
/// — the fund's configurable contribution rule, its own payment accounts
/// (`design_spec.md` §6 — eSewa/Khalti/bank/mobile banking, each optional,
/// each with an optional QR code), and the fixed lending policy shown
/// read-only for reference. Laid out to match `design_spec.md`'s `3d`
/// screen: grouped read-first cards (Contributions/Lending), a link out to
/// the visibility toggles, and a "changing a rule" note pointing at the
/// full audit trail — the editable fields (contribution amount, the fund's
/// own accounts) follow below as their own section.
class AdminFundRulesScreen extends ConsumerWidget {
  const AdminFundRulesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rules = ref.watch(fundRulesProvider);
    final account = ref.watch(fundAccountProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Fund rules')),
      body: rules.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => AppErrorState(message: '$error'),
        data: (data) => _FundRulesForm(
          initial: data,
          initialAccount: account.value ?? FundAccount.defaults,
        ),
      ),
    );
  }
}

class _FundRulesForm extends ConsumerStatefulWidget {
  const _FundRulesForm({required this.initial, required this.initialAccount});

  final FundRules initial;
  final FundAccount initialAccount;

  @override
  ConsumerState<_FundRulesForm> createState() => _FundRulesFormState();
}

class _FundRulesFormState extends ConsumerState<_FundRulesForm> {
  late final _monthly = TextEditingController(
    text: widget.initial.monthlyContributionAmount.toStringAsFixed(0),
  );
  late final _personalRate = TextEditingController(
    text: '${widget.initial.personalInterestRate}',
  );
  late final _emergencyRate = TextEditingController(
    text: '${widget.initial.emergencyInterestRate}',
  );
  late final _latePenalty = TextEditingController(
    text: '${widget.initial.latePenaltyRate}',
  );
  late final _maxLoans = TextEditingController(
    text: '${widget.initial.maxConcurrentLoans}',
  );
  late final _arrearsLimit = TextEditingController(
    text: '${widget.initial.arrearsLimitMonths}',
  );
  late final _reason = TextEditingController();
  late final _accountName = TextEditingController(
    text: widget.initialAccount.accountName,
  );
  late final _esewaId = TextEditingController(
    text: widget.initialAccount.esewaId,
  );
  late final _khaltiId = TextEditingController(
    text: widget.initialAccount.khaltiId,
  );
  late final _bankName = TextEditingController(
    text: widget.initialAccount.bankName,
  );
  late final _bankAccountNumber = TextEditingController(
    text: widget.initialAccount.bankAccountNumber,
  );
  late final _mobileBankingName = TextEditingController(
    text: widget.initialAccount.mobileBankingName,
  );
  late final _mobileBankingNumber = TextEditingController(
    text: widget.initialAccount.mobileBankingNumber,
  );
  late String? _esewaQrUrl = widget.initialAccount.esewaQrUrl;
  late String? _khaltiQrUrl = widget.initialAccount.khaltiQrUrl;
  late String? _mobileBankingQrUrl = widget.initialAccount.mobileBankingQrUrl;
  bool _saving = false;
  bool _savingAccount = false;

  Future<void> _save() async {
    final newAmount = double.tryParse(_monthly.text) ?? widget.initial.monthlyContributionAmount;
    final newPersonal = double.tryParse(_personalRate.text) ?? widget.initial.personalInterestRate;
    final newEmergency = double.tryParse(_emergencyRate.text) ?? widget.initial.emergencyInterestRate;
    final newPenalty = double.tryParse(_latePenalty.text) ?? widget.initial.latePenaltyRate;
    final newMaxLoans = int.tryParse(_maxLoans.text) ?? widget.initial.maxConcurrentLoans;
    final newArrears = int.tryParse(_arrearsLimit.text) ?? widget.initial.arrearsLimitMonths;

    final changed = newAmount != widget.initial.monthlyContributionAmount ||
        newPersonal != widget.initial.personalInterestRate ||
        newEmergency != widget.initial.emergencyInterestRate ||
        newPenalty != widget.initial.latePenaltyRate ||
        newMaxLoans != widget.initial.maxConcurrentLoans ||
        newArrears != widget.initial.arrearsLimitMonths;

    if (changed && _reason.text.trim().length < 3) {
      AppSnackbar.showError(
        context,
        title: 'A reason is required',
        message: 'Say why you are changing the fund rules.',
      );
      return;
    }
    setState(() => _saving = true);
    try {
      final uid = ref.read(authStateProvider).value?.uid;
      final repo = ref.read(fundRulesRepositoryProvider);
      
      final newRules = FundRules(
        monthlyContributionAmount: newAmount,
        personalInterestRate: newPersonal,
        emergencyInterestRate: newEmergency,
        latePenaltyRate: newPenalty,
        maxConcurrentLoans: newMaxLoans,
        arrearsLimitMonths: newArrears,
      );

      if (changed && uid != null) {
        await repo.updateWithAudit(
          rules: newRules,
          action: 'Updated global fund rules',
          performedBy: uid,
          previousValue: 'Multiple settings changed',
          newValue: 'Custom rules applied',
          reason: _reason.text.trim(),
        );
      } else {
        await repo.update(newRules);
      }
      if (mounted) {
        AppSnackbar.showSuccess(
          context,
          title: 'Settings saved',
          message: 'Fund rules have been updated.',
        );
      }
    } catch (_) {
      if (mounted) {
        AppSnackbar.showError(
          context,
          title: 'Could not save',
          message:
              'Something went wrong updating fund rules. Please try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _saveAccount() async {
    setState(() => _savingAccount = true);
    try {
      await ref
          .read(fundAccountRepositoryProvider)
          .update(
            FundAccount(
              accountName: _accountName.text.trim().isEmpty
                  ? FundAccount.defaults.accountName
                  : _accountName.text.trim(),
              esewaId: _esewaId.text.trim().isEmpty ? null : _esewaId.text.trim(),
              esewaQrUrl: _esewaQrUrl,
              khaltiId: _khaltiId.text.trim().isEmpty ? null : _khaltiId.text.trim(),
              khaltiQrUrl: _khaltiQrUrl,
              bankName: _bankName.text.trim().isEmpty ? null : _bankName.text.trim(),
              bankAccountNumber: _bankAccountNumber.text.trim().isEmpty
                  ? null
                  : _bankAccountNumber.text.trim(),
              mobileBankingName: _mobileBankingName.text.trim().isEmpty
                  ? null
                  : _mobileBankingName.text.trim(),
              mobileBankingNumber: _mobileBankingNumber.text.trim().isEmpty
                  ? null
                  : _mobileBankingNumber.text.trim(),
              mobileBankingQrUrl: _mobileBankingQrUrl,
            ),
          );
      if (mounted) {
        AppSnackbar.showSuccess(
          context,
          title: 'Account details saved',
          message:
              'Members only see the methods you fill in — leave a field '
              'blank to hide it.',
        );
      }
    } catch (_) {
      if (mounted) {
        AppSnackbar.showError(
          context,
          title: 'Could not save',
          message: 'Something went wrong. Please try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _savingAccount = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final auditLog = ref.watch(auditLogProvider).value ?? const [];
    final members = ref.watch(allMembersProvider).value ?? const [];
    final namesByUid = {for (final m in members) m.uid: m.fullName};
    AuditLogEntry? latestFor(String needle) {
      for (final entry in auditLog) {
        if (entry.action.toLowerCase().contains(needle)) return entry;
      }
      return null;
    }

    final contributionAudit = latestFor('minimum monthly contribution');

    return ListView(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        MediaQuery.of(context).padding.bottom + AppSpacing.xl * 2,
      ),
      children: [
        Text(
          'Every change is kept with its reason.',
          style: TextStyle(fontSize: 12.5, color: colors.textTertiary),
        ),
        const SizedBox(height: AppSpacing.lg),
        const _GroupLabel('Contributions'),
        _RuleGroup(
          rows: [
            _RuleRow(
              label: 'Minimum a month',
              value: 'NPR ${widget.initial.monthlyContributionAmount.toStringAsFixed(0)}',
              caption: contributionAudit == null
                  ? 'Unchanged since the fund began'
                  : null,
              captionWidget: contributionAudit == null
                  ? null
                  : AuditLine(
                      entry: contributionAudit,
                      actorName: namesByUid[contributionAudit.performedBy],
                    ),
            ),
            const _RuleRow(
              label: 'Paying ahead',
              value: 'Unlimited',
              caption: 'No cap on paying multiple months in advance',
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        const _GroupLabel('Lending'),
        _RuleGroup(
          rows: [
            for (final category in LoanCategory.values)
              _RuleRow(
                label: '${category.label(context)} loan',
                value: 'up to ${(category.maxFundShare * 100).toStringAsFixed(0)}%',
                caption:
                    '${category.monthlyInterestRatePercent}% monthly, '
                    '${(category.monthlyInterestRatePercent * 12).toStringAsFixed(0)}% a year',
              ),
            _RuleRow(
              label: 'Loans running at once',
              value: '$maxConcurrentLoans maximum',
              caption: 'No disbursement while $maxConcurrentLoans are outstanding',
            ),
            _RuleRow(
              label: 'Late interest penalty',
              value: '+$loanLatePenaltyMonthlyRatePercent%/mo',
              caption: 'On the principal, from disbursement, compounding each missed date',
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        const _GroupLabel('What members can see'),
        Material(
          color: colors.surface,
          borderRadius: BorderRadius.circular(12),
          clipBehavior: Clip.antiAlias,
          child: ListTile(
            leading: Icon(Icons.visibility_outlined, color: colors.textSecondary),
            title: const Text('Visibility settings'),
            subtitle: const Text(
              "What members can see about each other's contributions and loans",
            ),
            trailing: Icon(Icons.chevron_right, color: colors.textQuaternary),
            onTap: () => context.push(RoutePaths.adminPrivacySettings),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: colors.surfaceSunken,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colors.accentDark1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Changing a rule', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'A reason is required, and the old value stays in the audit '
                'trail. Members are told when a rule about their money '
                'changes.',
                style: TextStyle(fontSize: 12.5, color: colors.textTertiary),
              ),
              const SizedBox(height: AppSpacing.sm),
              OutlinedButton(
                onPressed: () => context.push(RoutePaths.adminAudit),
                child: const Text('Open the full audit trail'),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        Text('Edit rules', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: AppSpacing.sm),
        AppTextField(
          label: 'Monthly contribution amount (NPR)',
          controller: _monthly,
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: AppTextField(
                label: 'Personal interest (%)',
                controller: _personalRate,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: AppTextField(
                label: 'Emergency interest (%)',
                controller: _emergencyRate,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: AppTextField(
                label: 'Late penalty (%/mo)',
                controller: _latePenalty,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: AppTextField(
                label: 'Max concurrent loans',
                controller: _maxLoans,
                keyboardType: TextInputType.number,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        AppTextField(
          label: 'Arrears allowed (months)',
          controller: _arrearsLimit,
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: AppSpacing.md),
        AppTextField(
          label: 'Reason for change (required if changed)',
          controller: _reason,
        ),
        const SizedBox(height: AppSpacing.md),
        AppButton(label: 'Save changes', isLoading: _saving, onPressed: _save),
        const SizedBox(height: AppSpacing.xl),
        Text(
          "The fund's own accounts",
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Every contribution and loan repayment is paid into these '
          "accounts, never a member's own. Fill in only the methods you "
          'actually use — a member only ever sees the ones you fill in; an '
          "empty method is hidden entirely, never shown blank.",
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: AppSpacing.md),
        AppTextField(label: 'Account name', controller: _accountName),
        const SizedBox(height: AppSpacing.lg),
        _PaymentMethodSection(
          title: 'eSewa',
          idLabel: 'eSewa ID (phone number)',
          idController: _esewaId,
          qrUrl: _esewaQrUrl,
          onQrChanged: (url) => setState(() => _esewaQrUrl = url),
          qrFolder: 'hamro_kosh/fund_account/esewa_qr',
        ),
        const SizedBox(height: AppSpacing.lg),
        _PaymentMethodSection(
          title: 'Khalti',
          idLabel: 'Khalti ID (phone number)',
          idController: _khaltiId,
          qrUrl: _khaltiQrUrl,
          onQrChanged: (url) => setState(() => _khaltiQrUrl = url),
          qrFolder: 'hamro_kosh/fund_account/khalti_qr',
        ),
        const SizedBox(height: AppSpacing.lg),
        Text('Bank transfer', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: AppSpacing.sm),
        AppTextField(label: 'Bank name', controller: _bankName),
        const SizedBox(height: AppSpacing.sm),
        AppTextField(
          label: 'Bank account number',
          controller: _bankAccountNumber,
        ),
        const SizedBox(height: AppSpacing.lg),
        Text('Mobile banking', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: AppSpacing.sm),
        AppTextField(
          label: 'App/bank name (e.g. NIC Asia Mobile Banking)',
          controller: _mobileBankingName,
        ),
        const SizedBox(height: AppSpacing.sm),
        AppTextField(
          label: 'Mobile banking number',
          controller: _mobileBankingNumber,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'QR code (optional)',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: AppSpacing.xs),
        ProofPicker(
          currentUrl: _mobileBankingQrUrl,
          onChanged: (url) => setState(() => _mobileBankingQrUrl = url),
          folder: 'hamro_kosh/fund_account/mobile_banking_qr',
          label: 'Upload QR code',
        ),
        const SizedBox(height: AppSpacing.md),
        AppButton(
          label: 'Save account details',
          isLoading: _savingAccount,
          onPressed: _saveAccount,
        ),
      ],
    );
  }
}

class _GroupLabel extends StatelessWidget {
  const _GroupLabel(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm, left: 4),
      child: Text(
        label,
        style: Theme.of(
          context,
        ).textTheme.titleSmall?.copyWith(color: context.colors.textSecondary),
      ),
    );
  }
}

/// A read-only "current value + why it's this way" row (`design_spec.md`
/// §3d's Contributions/Lending groups) — the design's snapshot-of-the-rule
/// presentation, distinct from the editable fields further down the screen.
class _RuleRow {
  const _RuleRow({
    required this.label,
    required this.value,
    this.caption,
    this.captionWidget,
  });

  final String label;
  final String value;
  final String? caption;
  final Widget? captionWidget;
}

class _RuleGroup extends StatelessWidget {
  const _RuleGroup({required this.rows});
  final List<_RuleRow> rows;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Material(
      color: colors.surface,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0) Divider(height: 1, color: colors.divider),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          rows[i].label,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        if (rows[i].captionWidget != null) ...[
                          const SizedBox(height: 3),
                          rows[i].captionWidget!,
                        ] else if (rows[i].caption != null) ...[
                          const SizedBox(height: 3),
                          Text(
                            rows[i].caption!,
                            style: TextStyle(fontSize: 11, color: colors.textQuaternary),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    rows[i].value,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PaymentMethodSection extends StatelessWidget {
  const _PaymentMethodSection({
    required this.title,
    required this.idLabel,
    required this.idController,
    required this.qrUrl,
    required this.onQrChanged,
    required this.qrFolder,
  });

  final String title;
  final String idLabel;
  final TextEditingController idController;
  final String? qrUrl;
  final ValueChanged<String?> onQrChanged;
  final String qrFolder;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: AppSpacing.sm),
        AppTextField(label: idLabel, controller: idController),
        const SizedBox(height: AppSpacing.sm),
        Text('QR code (optional)', style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: AppSpacing.xs),
        ProofPicker(
          currentUrl: qrUrl,
          onChanged: onQrChanged,
          folder: qrFolder,
          label: 'Upload QR code',
        ),
      ],
    );
  }
}
