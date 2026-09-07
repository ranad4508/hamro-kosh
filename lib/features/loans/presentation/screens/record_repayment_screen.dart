import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/proof_picker.dart';
import '../../../auth/providers/auth_providers.dart';
import '../../providers/loans_providers.dart';

/// SRS §21 — a member records a repayment against their own loan. Mirrors
/// AddContributionScreen's shape: this only ever submits a *claim*
/// ("I paid NPR X") in `pending` status — splitting it into principal/
/// interest/penalty and actually updating the loan happens server-side,
/// in `verifyRepayment`, once an admin confirms it.
class RecordRepaymentScreen extends ConsumerStatefulWidget {
  const RecordRepaymentScreen({super.key, required this.loanId});

  final String loanId;

  @override
  ConsumerState<RecordRepaymentScreen> createState() =>
      _RecordRepaymentScreenState();
}

class _RecordRepaymentScreenState extends ConsumerState<RecordRepaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amount = TextEditingController();
  String _paymentMethod = 'Cash';
  String? _proofUrl;
  bool _submitting = false;

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  Future<void> _submit(double outstanding) async {
    if (!_formKey.currentState!.validate()) return;
    final uid = ref.read(authStateProvider).value?.uid;
    final memberName = ref.read(userProfileProvider).value?.fullName;
    if (uid == null) return;

    setState(() => _submitting = true);
    try {
      await ref
          .read(loansRepositoryProvider)
          .submitRepayment(
            loanId: widget.loanId,
            uid: uid,
            borrowerName: memberName ?? 'Member',
            amount: double.parse(_amount.text.trim()),
            paymentMethod: _paymentMethod,
            proofUrl: _proofUrl,
          );
      if (mounted) {
        Navigator.of(context).pop();
        AppSnackbar.showSuccess(
          context,
          title: 'Repayment submitted',
          message: 'An admin will verify it shortly.',
        );
      }
    } catch (_) {
      if (mounted) {
        AppSnackbar.showError(
          context,
          title: 'Could not submit',
          message:
              'Something went wrong recording your repayment. Please try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loan = ref.watch(loanDetailProvider(widget.loanId));
    final outstanding = loan.value?.outstanding ?? 0;
    final isCash = _paymentMethod == 'Cash';

    return Scaffold(
      appBar: AppBar(title: const Text('Record a repayment')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Outstanding balance',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    Text(
                      CurrencyFormatter.format(outstanding),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
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
                if (outstanding > 0 &&
                    double.parse(v!.trim()) > outstanding + 0.01) {
                  return 'Exceeds the outstanding balance of ${CurrencyFormatter.format(outstanding)}';
                }
                return null;
              },
            ),
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
              folder: 'hamro_kosh/repayment_proofs',
              label: 'Attach a receipt or screenshot (optional)',
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              "This isn't applied to your loan until an admin verifies it — payments are "
              'allocated to any overdue penalty first, then interest, then principal.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: AppSpacing.xl),
            AppButton(
              label: 'Submit',
              isLoading: _submitting,
              onPressed: () => _submit(outstanding),
            ),
          ],
        ),
      ),
    );
  }
}
