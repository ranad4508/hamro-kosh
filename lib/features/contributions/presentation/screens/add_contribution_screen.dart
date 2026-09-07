import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nepali_utils/nepali_utils.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/models/contribution_type.dart';
import '../../../../core/models/loan_status.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/bs_date_formatter.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/bilingual_text.dart';
import '../../../../core/widgets/full_screen_image_viewer.dart';
import '../../../../core/widgets/initials_avatar.dart';
import '../../../../core/widgets/month_grid_heatmap.dart';
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

import '../../../../l10n/generated/app_localizations.dart';

/// Where this payment starts, in BS (year, month) — [override] wins when
/// the member has tapped a specific gap cell; otherwise it's the month
/// right after the latest one already covered, or the current month if
/// nothing has been covered yet. Shared between the preview grid and
/// [_AddContributionScreenState._submit] so what's shown is exactly what
/// gets saved.
(int, int) _computeStart(MemberCoverage coverage, (int, int)? override) {
  if (override != null) return override;
  if (coverage.coveredMonths.isEmpty) {
    final now = NepaliDateTime.now();
    return (now.year, now.month);
  }
  final latest = coverage.coveredMonths.reduce(
    (a, b) => (a.$1 > b.$1 || (a.$1 == b.$1 && a.$2 > b.$2)) ? a : b,
  );
  var year = latest.$1;
  var month = latest.$2 + 1;
  if (month > 12) {
    month = 1;
    year++;
  }
  return (year, month);
}

enum _PaymentMethod { esewa, khalti, bank, mobileBanking, cashToAdmin }

extension on _PaymentMethod {
  String label(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return switch (this) {
      _PaymentMethod.esewa => l10n.paymentMethodEsewa,
      _PaymentMethod.khalti => l10n.paymentMethodKhalti,
      _PaymentMethod.bank => l10n.paymentMethodBank,
      _PaymentMethod.mobileBanking => l10n.paymentMethodMobileBanking,
      _PaymentMethod.cashToAdmin => l10n.paymentMethodCash,
    };
  }

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

  /// Which BS (year, month) this payment starts from — null means "figure
  /// it out automatically" (right after the latest covered month, or the
  /// current month if nothing's covered yet). Set when the member taps a
  /// specific gap cell in the grid to catch up on an *earlier* arrear
  /// (e.g. Jestha) instead of always continuing from today.
  (int, int)? _startOverride;

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

    // For a monthly contribution, save it starting from whichever BS month
    // the preview grid actually settled on (auto-computed, or the gap month
    // the member tapped) — never just "today," or a deliberate catch-up
    // payment for an earlier arrear would get mis-recorded as covering the
    // current month instead.
    var startDate = DateTime.now();
    if (_category == ContributionCategory.monthly) {
      final coverage = ref.read(
        memberCoverageProvider((uid: uid, memberSince: ref.read(userProfileProvider).value?.memberSince)),
      ).value;
      if (coverage != null) {
        final (year, month) = _computeStart(coverage, _startOverride);
        startDate = NepaliDateTime(year, month, 1).toDateTime();
      }
    }

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
              date: startDate,
              status: ContributionStatus.pending,
              memberUid: uid,
              memberName: memberName,
              occasionName: _category == ContributionCategory.special
                  ? _occasion.text.trim()
                  : null,
              paymentMethod: method.label(context),
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

  void _applyPreset(double? perMonth, int months) {
    if (perMonth == null) return;
    setState(() {
      _monthsCovered = months;
      _amount.text = (perMonth * months).toStringAsFixed(0);
    });
  }

  @override
  Widget build(BuildContext context) {
    final fundRules = ref.watch(fundRulesProvider);
    final fundAccountAsync = ref.watch(fundAccountProvider);
    final fundAccount = fundAccountAsync.value;
    final perMonth = fundRules.value?.monthlyContributionAmount;
    final minimumAmount = (perMonth ?? 0) * _monthsCovered;
    final profile = ref.watch(userProfileProvider).value;
    final coverageAsync = profile == null
        ? null
        : ref.watch(
            memberCoverageProvider((
              uid: profile.uid,
              memberSince: profile.memberSince,
            )),
          );

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
          padding: EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.lg,
            MediaQuery.of(context).padding.bottom + AppSpacing.xl * 2,
          ),
          children: [
            SegmentedButton<ContributionCategory>(
              segments: [
                ButtonSegment(
                  value: ContributionCategory.monthly,
                  label: Text(ContributionCategory.monthly.label(context)),
                ),
                ButtonSegment(
                  value: ContributionCategory.special,
                  label: Text(ContributionCategory.special.label(context)),
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
            // The design's big underlined-numeral amount entry
            // (`design_spec.md` §2e) rather than a boxed text field —
            // quick-pick chips set both the amount and (for a monthly
            // contribution) how many months it buys at the committee's
            // current per-month floor, matching the design's
            // amount-implies-months preset pattern.
            BilingualText(
              'Amount',
              'रकम',
              layout: BilingualLayout.inline,
              style: TextStyle(fontSize: 11, color: context.colors.accent),
            ),
            const SizedBox(height: AppSpacing.xs),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('Rs. ', style: Theme.of(context).textTheme.titleMedium),
                Expanded(
                  child: TextFormField(
                    controller: _amount,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    style: Theme.of(context).textTheme.headlineMedium,
                    decoration: const InputDecoration(
                      border: UnderlineInputBorder(),
                      isDense: true,
                    ),
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
                ),
              ],
            ),
            if (_category == ContributionCategory.monthly &&
                perMonth != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  _PresetChip(
                    label: perMonth.toStringAsFixed(0),
                    selected: _monthsCovered == 1,
                    onTap: () => _applyPreset(perMonth, 1),
                  ),
                  _PresetChip(
                    label: '${(perMonth * 3).toStringAsFixed(0)} · quarter',
                    selected: _monthsCovered == 3,
                    onTap: () => _applyPreset(perMonth, 3),
                  ),
                  _PresetChip(
                    label: '${(perMonth * 12).toStringAsFixed(0)} · year',
                    selected: _monthsCovered == 12,
                    onTap: () => _applyPreset(perMonth, 12),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'The floor is NPR ${perMonth.toStringAsFixed(0)} a month, set by '
                'the committee. Anything above it is welcome, and you may pay '
                'monthly or a whole quarter at once — ahead or in arrears.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: AppSpacing.lg),
              BilingualText(
                'Which months does this cover?',
                'यसले कुन महिना समेट्छ?',
                layout: BilingualLayout.inline,
                style: TextStyle(fontSize: 11, color: context.colors.accent),
              ),
              const SizedBox(height: AppSpacing.sm),
              switch (coverageAsync) {
                AsyncData(:final value) => _CoveragePreview(
                  coverage: value,
                  monthsCovered: _monthsCovered,
                  onMonthsChanged: (months) =>
                      setState(() => _monthsCovered = months),
                  startOverride: _startOverride,
                  onStartTapped: (start) =>
                      setState(() => _startOverride = start),
                ),
                _ => const SizedBox.shrink(),
              },
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
              Material(
                color: context.colors.surface,
                borderRadius: BorderRadius.circular(12),
                clipBehavior: Clip.antiAlias,
                child: RadioGroup<_PaymentMethod>(
                  groupValue: method,
                  onChanged: (m) => setState(() => _method = m),
                  child: Column(
                    children: [
                      for (var i = 0; i < availableMethods.length; i++) ...[
                        if (i > 0)
                          Divider(height: 1, color: context.colors.divider),
                        RadioListTile<_PaymentMethod>(
                          value: availableMethods[i],
                          title: Text(availableMethods[i].label(context)),
                          subtitle: Text(
                            _accountSubtitle(availableMethods[i], fundAccount),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              if (isDigital) ...[
                _FundAccountCard(account: fundAccount!, method: method),
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  label: '${method.label(context)} transaction reference',
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
                      data: (items) => RadioGroup<String>(
                        groupValue: _receivingAdmin?.uid,
                        onChanged: (uid) => setState(
                          () => _receivingAdmin =
                              items.where((a) => a.uid == uid).firstOrNull,
                        ),
                        child: Column(
                          children: [
                            for (final admin in items)
                              RadioListTile<String>(
                                contentPadding: EdgeInsets.zero,
                                value: admin.uid,
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
                onPressed: () => _submit(method!),
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

/// The account snippet shown beneath each payment method row
/// (`design_spec.md` §2e — "eSewa — Hamro Kosh 9841••••21").
String _accountSubtitle(_PaymentMethod method, FundAccount? account) {
  if (account == null) return '';
  return switch (method) {
    _PaymentMethod.esewa => '${account.accountName} — ${account.esewaId}',
    _PaymentMethod.khalti => '${account.accountName} — ${account.khaltiId}',
    _PaymentMethod.bank =>
      '${account.accountName}, ${account.bankName ?? 'Bank'} — '
          '${account.bankAccountNumber}',
    _PaymentMethod.mobileBanking =>
      '${account.mobileBankingName ?? 'Mobile banking'} — '
          '${account.mobileBankingNumber}',
    _PaymentMethod.cashToAdmin => 'Hand it to an admin — they bank it and confirm',
  };
}

class _PresetChip extends StatelessWidget {
  const _PresetChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? colors.accent : colors.surfaceSunken,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w500,
            color: selected ? colors.bg : colors.textSecondary,
          ),
        ),
      ),
    );
  }
}

/// "Which months does this cover?" (`design_spec.md` §2e) — the month-grid
/// heatmap plus a plain-language result sentence, computed from where the
/// member's real coverage currently ends rather than a fixed example. Any
/// still-open gap month can be tapped directly to start the payment there
/// instead — e.g. it's Bhadra, but Jestha/Asar/Shrawan are still unpaid, so
/// the member taps Jestha to catch those up rather than only ever being
/// offered "continue from today forward."
class _CoveragePreview extends StatelessWidget {
  const _CoveragePreview({
    required this.coverage,
    required this.monthsCovered,
    required this.onMonthsChanged,
    required this.startOverride,
    required this.onStartTapped,
  });

  final MemberCoverage coverage;
  final int monthsCovered;
  final ValueChanged<int> onMonthsChanged;
  final (int, int)? startOverride;
  final void Function((int, int)? start) onStartTapped;

  @override
  Widget build(BuildContext context) {
    final now = NepaliDateTime.now();
    final (startYear, startMonth) = _computeStart(coverage, startOverride);

    final thisPayment = <(int, int)>{};
    var y = startYear;
    var m = startMonth;
    for (var i = 0; i < monthsCovered; i++) {
      thisPayment.add((y, m));
      m++;
      if (m > 12) {
        m = 1;
        y++;
      }
    }

    final cells = List.generate(12, (i) {
      final monthNum = i + 1;
      final key = (now.year, monthNum);
      final state = coverage.coveredMonths.contains(key)
          ? MonthCellState.covered
          : thisPayment.contains(key)
          ? MonthCellState.coveringNow
          : monthNum <= now.month
          ? MonthCellState.gap
          : MonthCellState.future;
      return (label: BsDateFormatter.monthAbbreviations[i], state: state);
    });

    final ordered = thisPayment.toList()
      ..sort(
        (a, b) => a.$1 != b.$1 ? a.$1.compareTo(b.$1) : a.$2.compareTo(b.$2),
      );
    final resultText = ordered.isEmpty
        ? 'Pick an amount to see which months this covers.'
        : ordered.length == 1
        ? 'This covers ${BsDateFormatter.monthNames[ordered.first.$2 - 1]}.'
        : 'This covers ${BsDateFormatter.monthNames[ordered.first.$2 - 1]} '
              'through ${BsDateFormatter.monthNames[ordered.last.$2 - 1]}.';

    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MonthGridHeatmap(
            cells: cells,
            columns: 4,
            onCellTap: (index) {
              final monthNum = index + 1;
              final state = cells[index].state;
              if (state == MonthCellState.gap) {
                onStartTapped((now.year, monthNum));
              } else if (state == MonthCellState.coveringNow) {
                onStartTapped(null);
              }
            },
          ),
          const SizedBox(height: 6),
          Text(
            'Tap an open month above to catch up on it specifically.',
            style: TextStyle(fontSize: 10.5, color: context.colors.textQuaternary),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: Text(
                  resultText,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                onPressed: monthsCovered > 1
                    ? () => onMonthsChanged(monthsCovered - 1)
                    : null,
                icon: const Icon(Icons.remove_circle_outline, size: 20),
              ),
              Text('$monthsCovered mo'),
              IconButton(
                visualDensity: VisualDensity.compact,
                onPressed: monthsCovered < 12
                    ? () => onMonthsChanged(monthsCovered + 1)
                    : null,
                icon: const Icon(Icons.add_circle_outline, size: 20),
              ),
            ],
          ),
        ],
      ),
    );
  }
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
            GestureDetector(
              onTap: () => showFullScreenImage(context, qrUrl),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(
                  imageUrl: qrUrl,
                  height: 160,
                  width: 160,
                  fit: BoxFit.contain,
                ),
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
