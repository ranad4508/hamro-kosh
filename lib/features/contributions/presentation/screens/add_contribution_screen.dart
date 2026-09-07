import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/models/contribution_type.dart';
import '../../../../core/models/loan_status.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/bilingual_text.dart';
import '../../../../core/widgets/initials_avatar.dart';
import '../../../../core/widgets/proof_picker.dart';
import '../../../admin/providers/admin_providers.dart';
import '../../../auth/providers/auth_providers.dart';
import '../../../fund/data/fund_account.dart';
import '../../../fund/providers/fund_providers.dart';
import '../../../members/data/member_directory_entry.dart';
import '../../../members/providers/members_providers.dart';
import '../../data/campaign.dart';
import '../../data/contribution.dart';
import '../../providers/contributions_providers.dart';

enum _PaymentMethod { esewa, khalti, bank, mobileBanking, cashToAdmin }

extension on _PaymentMethod {
  String get label => switch (this) {
    _PaymentMethod.esewa => 'eSewa',
    _PaymentMethod.khalti => 'Khalti',
    _PaymentMethod.bank => 'Bank transfer',
    _PaymentMethod.mobileBanking => 'Mobile banking',
    _PaymentMethod.cashToAdmin => 'Cash to admin',
  };

  /// Whether an admin has actually filled in this method's details — a
  /// member should only ever be offered a method that's really configured,
  /// never an empty one (`design_spec.md` §6, per the fund's own account
  /// model). Cash-to-admin doesn't depend on `FundAccount` at all — it's
  /// always a valid way to hand over money.
  bool isConfiguredIn(FundAccount account) => switch (this) {
    _PaymentMethod.esewa => account.hasEsewa,
    _PaymentMethod.khalti => account.hasKhalti,
    _PaymentMethod.bank => account.hasBank,
    _PaymentMethod.mobileBanking => account.hasMobileBanking,
    _PaymentMethod.cashToAdmin => true,
  };
}

/// SRS §7 — "Give to the fund": amount, months covered, and a payment
/// method whose required fields change with the method
/// (`design_spec.md` §5 — the core rule this screen encodes). Every digital
/// method (eSewa/Khalti/bank/mobile banking) needs a transaction reference
/// + screenshot, since nobody watched the transfer happen; cash handed
/// directly to a named admin needs neither — that admin's own confirmation
/// is the proof. The methods actually offered are whichever ones the admin
/// has filled in under Fund rules & accounts (§`AdminFundRulesScreen`) —
/// this screen never shows an unconfigured method. Pass [campaign] to
/// contribute toward a specific named campaign (SRS §15).
class AddContributionScreen extends ConsumerStatefulWidget {
  const AddContributionScreen({super.key, this.campaign});

  final Campaign? campaign;

  @override
  ConsumerState<AddContributionScreen> createState() =>
      _AddContributionScreenState();
}

class _AddContributionScreenState extends ConsumerState<AddContributionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amount = TextEditingController();
  final _reference = TextEditingController();
  late final _occasion = TextEditingController(text: widget.campaign?.name);
  late ContributionCategory _category = widget.campaign != null
      ? ContributionCategory.special
      : ContributionCategory.monthly;
  _PaymentMethod? _method;
  int _monthsCovered = 1;
  String? _proofUrl;
  MemberDirectoryEntry? _receivingAdmin;
  bool _submitting = false;

  @override
  void dispose() {
    _amount.dispose();
    _reference.dispose();
    _occasion.dispose();
    super.dispose();
  }

  Future<void> _submit(_PaymentMethod method) async {
    if (!_formKey.currentState!.validate()) return;
    if (method == _PaymentMethod.cashToAdmin && _receivingAdmin == null) {
      AppSnackbar.showError(
        context,
        title: 'Choose an admin',
        message: 'Select which admin you handed the cash to.',
      );
      return;
    }
    final uid = ref.read(authStateProvider).value?.uid;
    if (uid == null) return;
    final memberName = ref.read(userProfileProvider).value?.fullName;

    setState(() => _submitting = true);
    try {
      await ref
          .read(contributionsRepositoryProvider)
          .submit(
            uid,
            Contribution(
              id: '',
              category: _category,
              amount: double.parse(_amount.text.trim()),
              date: DateTime.now(),
              status: ContributionStatus.pending,
              memberUid: uid,
              memberName: memberName,
              occasionName: _category == ContributionCategory.special
                  ? _occasion.text.trim()
                  : null,
              paymentMethod: method.label,
              reference: method == _PaymentMethod.cashToAdmin
                  ? null
                  : _reference.text.trim(),
              monthsCovered: _category == ContributionCategory.monthly
                  ? _monthsCovered
                  : 1,
              proofUrl: method == _PaymentMethod.cashToAdmin ? null : _proofUrl,
              campaignId: widget.campaign?.id,
              receivingAdminId: _receivingAdmin?.uid,
              receivingAdminName: _receivingAdmin?.fullName,
            ),
          );
      if (mounted) {
        Navigator.of(context).pop();
        AppSnackbar.showSuccess(
          context,
          title: 'Submitted for approval',
          message: method == _PaymentMethod.cashToAdmin
              ? '${_receivingAdmin!.fullName} will confirm they received it.'
              : 'An admin will match it against the fund statement shortly.',
        );
      }
    } catch (_) {
      if (mounted) {
        AppSnackbar.showError(
          context,
          title: 'Could not submit',
          message:
              'Something went wrong recording your contribution. Please try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final fundRules = ref.watch(fundRulesProvider);
    final fundAccountAsync = ref.watch(fundAccountProvider);
    final fundAccount = fundAccountAsync.value;
    final perMonth = fundRules.value?.monthlyContributionAmount;
    final minimumAmount = (perMonth ?? 0) * _monthsCovered;

    final availableMethods = fundAccount == null
        ? const <_PaymentMethod>[]
        : _PaymentMethod.values
              .where((m) => m.isConfiguredIn(fundAccount))
              .toList();
    // No method has been explicitly tapped yet, or the previously-tapped
    // one is no longer configured (e.g. an admin just removed it) — default
    // to the first configured method rather than assuming eSewa exists.
    final method = (_method != null && availableMethods.contains(_method))
        ? _method
        : availableMethods.firstOrNull;
    final isDigital = method != null && method != _PaymentMethod.cashToAdmin;

    return Scaffold(
      appBar: AppBar(
        title: const BilingualText(
          'Give to the fund',
          'कोषमा योगदान',
          layout: BilingualLayout.inline,
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            SegmentedButton<ContributionCategory>(
              segments: const [
                ButtonSegment(
                  value: ContributionCategory.monthly,
                  label: Text('Monthly'),
                ),
                ButtonSegment(
                  value: ContributionCategory.special,
                  label: Text('Special'),
                ),
              ],
              selected: {_category},
              onSelectionChanged: widget.campaign != null
                  ? null
                  : (selection) => setState(() => _category = selection.first),
            ),
            const SizedBox(height: AppSpacing.md),
            if (_category == ContributionCategory.special) ...[
              AppTextField(
                label: 'Occasion (e.g. Dashain, Emergency)',
                controller: _occasion,
                enabled: widget.campaign == null,
                validator: (v) => Validators.required(v, field: 'Occasion'),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
            AppTextField(
              label: 'Amount (NPR)',
              controller: _amount,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              prefixText: 'Rs. ',
              validator: (v) {
                final base = Validators.positiveAmount(v);
                if (base != null) return base;
                if (_category == ContributionCategory.monthly &&
                    minimumAmount > 0 &&
                    double.parse(v!.trim()) < minimumAmount) {
                  return 'At least ${CurrencyFormatter.format(minimumAmount)} for '
                      '$_monthsCovered month${_monthsCovered == 1 ? '' : 's'}';
                }
                return null;
              },
            ),
            if (_category == ContributionCategory.monthly &&
                perMonth != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                'The floor is NPR ${perMonth.toStringAsFixed(0)} a month, set by '
                'the committee. Pay monthly or a whole quarter at once.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            if (_category == ContributionCategory.monthly) ...[
              const SizedBox(height: AppSpacing.md),
              Text(
                'Months covered',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.xs),
              Row(
                children: [
                  IconButton.outlined(
                    onPressed: _monthsCovered > 1
                        ? () => setState(() => _monthsCovered--)
                        : null,
                    icon: const Icon(Icons.remove),
                  ),
                  Expanded(
                    child: Text(
                      '$_monthsCovered month${_monthsCovered == 1 ? '' : 's'}',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  IconButton.outlined(
                    onPressed: _monthsCovered < 12
                        ? () => setState(() => _monthsCovered++)
                        : null,
                    icon: const Icon(Icons.add),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                _monthsCovered == 1
                    ? 'Covers ${DateFormatter.monthYear(DateTime.now())}'
                    : 'Covers ${DateFormatter.monthYear(DateTime.now())} – '
                          '${DateFormatter.monthYear(DateTime(DateTime.now().year, DateTime.now().month + _monthsCovered - 1))}'
                          ' (catching up or paying ahead)',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
            BilingualText(
              'How you paid',
              'भुक्तानी माध्यम',
              layout: BilingualLayout.inline,
              style: TextStyle(fontSize: 11, color: context.colors.textTertiary),
            ),
            const SizedBox(height: AppSpacing.sm),
            if (fundAccountAsync.isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (availableMethods.isEmpty)
              Container(
                padding: const EdgeInsets.all(13),
                decoration: BoxDecoration(
                  color: context.colors.surface,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'No payment method has been set up yet. Ask an admin to '
                  'add the fund\'s eSewa, Khalti, bank, or mobile banking '
                  'details in Fund rules & accounts.',
                  style: TextStyle(color: context.colors.textSecondary),
                ),
              )
            else ...[
              SegmentedButton<_PaymentMethod>(
                segments: [
                  for (final m in availableMethods)
                    ButtonSegment(value: m, label: Text(m.label)),
                ],
                selected: {method!},
                onSelectionChanged: (selection) =>
                    setState(() => _method = selection.first),
              ),
              const SizedBox(height: AppSpacing.md),
              if (isDigital) ...[
                _FundAccountCard(account: fundAccount!, method: method),
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  label: '${method.label} transaction reference',
                  controller: _reference,
                  validator: (v) => Validators.required(v, field: 'Reference'),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Screenshot of the payment',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: AppSpacing.xs),
                ProofPicker(
                  currentUrl: _proofUrl,
                  onChanged: (url) => setState(() => _proofUrl = url),
                  folder: 'hamro_kosh/contribution_proofs',
                  label: 'Attach a receipt or screenshot',
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  "This isn't counted in the fund until an admin matches it "
                  'against the account statement.',
                  style: TextStyle(fontSize: 12, color: context.colors.textTertiary),
                ),
              ] else ...[
                const _NoProofNotice(),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Which admin did you hand it to?',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: AppSpacing.xs),
                Consumer(
                  builder: (context, ref, _) {
                    final admins = ref.watch(activeAdminsProvider);
                    return admins.when(
                      loading: () => const Padding(
                        padding: EdgeInsets.all(12),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                      error: (e, _) => Text('$e'),
                      data: (items) => Column(
                        children: [
                          for (final admin in items)
                            RadioListTile<String>(
                              contentPadding: EdgeInsets.zero,
                              value: admin.uid,
                              groupValue: _receivingAdmin?.uid,
                              onChanged: (_) =>
                                  setState(() => _receivingAdmin = admin),
                              title: Row(
                                children: [
                                  InitialsAvatar.fromName(
                                    admin.fullName,
                                    imageUrl: admin.photoUrl,
                                    radius: 16,
                                  ),
                                  const SizedBox(width: 10),
                                  Text(admin.fullName),
                                ],
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ],
              const SizedBox(height: AppSpacing.xl),
              AppButton(
                label: isDigital || _receivingAdmin == null
                    ? 'Submit for approval'
                    : 'Send to ${_receivingAdmin!.fullName.split(' ').first} to confirm',
                isLoading: _submitting,
                onPressed: () => _submit(method),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

extension<T> on List<T> {
  T? get firstOrNull => isEmpty ? null : first;
}

class _FundAccountCard extends StatelessWidget {
  const _FundAccountCard({required this.account, required this.method});

  final FundAccount account;
  final _PaymentMethod method;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final (String? detail, String? qrUrl) = switch (method) {
      _PaymentMethod.esewa => ('eSewa ${account.esewaId}', account.esewaQrUrl),
      _PaymentMethod.khalti => ('Khalti ${account.khaltiId}', account.khaltiQrUrl),
      _PaymentMethod.bank => (
        '${account.bankName ?? 'Bank'} · ${account.bankAccountNumber}',
        null,
      ),
      _PaymentMethod.mobileBanking => (
        '${account.mobileBankingName ?? 'Mobile banking'} · ${account.mobileBankingNumber}',
        account.mobileBankingQrUrl,
      ),
      _PaymentMethod.cashToAdmin => (null, null),
    };

    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: colors.surfaceSunken,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: colors.accentDark1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            account.accountName,
            style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13.5),
          ),
          const SizedBox(height: 6),
          if (detail != null)
            Text(detail, style: TextStyle(color: colors.textSecondary, fontSize: 12.5)),
          if (qrUrl != null) ...[
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: CachedNetworkImage(
                imageUrl: qrUrl,
                height: 160,
                width: 160,
                fit: BoxFit.contain,
              ),
            ),
          ],
          const SizedBox(height: 7),
          Text(
            'The account belongs to the fund, not to any member.',
            style: TextStyle(fontSize: 11.5, color: colors.textTertiary),
          ),
        ],
      ),
    );
  }
}

class _NoProofNotice extends StatelessWidget {
  const _NoProofNotice();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.check_circle_outline, size: 19, color: colors.accentLight),
          const SizedBox(width: 11),
          Expanded(
            child: BilingualText(
              'No screenshot needed — you handed the notes to an admin, so '
              'there is nothing to screenshot. They deposit the cash and '
              'confirm it here.',
              'हातमा दिएको रकमको लागि स्क्रिनसट आवश्यक छैन।',
              style: TextStyle(fontSize: 12.5, color: colors.textSecondary, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}
