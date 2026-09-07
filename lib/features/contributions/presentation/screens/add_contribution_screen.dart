import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/models/contribution_type.dart';
import '../../../../core/models/loan_status.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/proof_picker.dart';
import '../../../admin/providers/admin_providers.dart';
import '../../../auth/providers/auth_providers.dart';
import '../../data/campaign.dart';
import '../../data/contribution.dart';
import '../../providers/contributions_providers.dart';

/// SRS §7 — "Add contribution" with payment method, optional proof, and
/// (for monthly contributions) how many months a single payment covers —
/// the reference design's catch-up-payment receipt ("this covers Asar
/// through Mangsir") shown as one entry rather than one per month. Pass
/// [campaign] to contribute toward a specific named campaign (SRS §15) —
/// locks the category to Special and tags the submission with its id.
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
  late final _occasion = TextEditingController(text: widget.campaign?.name);
  late ContributionCategory _category = widget.campaign != null
      ? ContributionCategory.special
      : ContributionCategory.monthly;
  String _paymentMethod = 'Cash';
  int _monthsCovered = 1;
  String? _proofUrl;
  bool _submitting = false;

  @override
  void dispose() {
    _amount.dispose();
    _occasion.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
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
              paymentMethod: _paymentMethod,
              monthsCovered: _category == ContributionCategory.monthly
                  ? _monthsCovered
                  : 1,
              proofUrl: _proofUrl,
              campaignId: widget.campaign?.id,
            ),
          );
      if (mounted) {
        Navigator.of(context).pop();
        AppSnackbar.showSuccess(
          context,
          title: 'Contribution submitted',
          message: 'An admin will verify it shortly.',
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
    final perMonth = fundRules.value?.monthlyContributionAmount;
    final minimumAmount = (perMonth ?? 0) * _monthsCovered;
    final isCash = _paymentMethod == 'Cash';

    return Scaffold(
      appBar: AppBar(title: const Text('Add contribution')),
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
              prefixIcon: Icons.currency_rupee,
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
                'Minimum NPR ${perMonth.toStringAsFixed(0)}/month.',
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
            const SizedBox(height: AppSpacing.md),
            DropdownButtonFormField<String>(
              initialValue: _paymentMethod,
              decoration: const InputDecoration(labelText: 'Payment method'),
              items: const [
                DropdownMenuItem(value: 'Cash', child: Text('Cash')),
                DropdownMenuItem(
                  value: 'Bank transfer',
                  child: Text('Bank transfer'),
                ),
                DropdownMenuItem(
                  value: 'eSewa / Khalti',
                  child: Text('eSewa / Khalti'),
                ),
              ],
              onChanged: (value) => setState(() => _paymentMethod = value!),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              isCash ? 'Payment proof' : 'Payment proof (recommended)',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.xs),
            ProofPicker(
              currentUrl: _proofUrl,
              onChanged: (url) => setState(() => _proofUrl = url),
              folder: 'hamro_kosh/contribution_proofs',
              label: 'Attach a receipt or screenshot (optional)',
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              isCash
                  ? 'No proof needed for cash handed directly to an admin — it still '
                        "stays pending until they verify it, and isn't counted in the fund until then."
                  : "This isn't counted in the fund until an admin verifies it.",
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: AppSpacing.xl),
            AppButton(
              label: 'Submit',
              isLoading: _submitting,
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }
}
