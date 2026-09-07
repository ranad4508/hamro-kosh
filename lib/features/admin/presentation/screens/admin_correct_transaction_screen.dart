import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/services/cloud_functions_service.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../fund/data/fund_transaction.dart';

enum _CorrectionDirection { credit, debit }

/// SRS §44 — Data Corrections. Never edits or deletes [original]: submitting
/// appends a new, linked `adjustment` ledger entry via the `correctTransaction`
/// Cloud Function, which keeps the original record, the correction amount,
/// the reason, the responsible admin, and the timestamp — exactly what §44
/// requires — rather than silently overwriting financial history.
class AdminCorrectTransactionScreen extends ConsumerStatefulWidget {
  const AdminCorrectTransactionScreen({super.key, required this.original});

  final FundTransaction original;

  @override
  ConsumerState<AdminCorrectTransactionScreen> createState() =>
      _AdminCorrectTransactionScreenState();
}

class _AdminCorrectTransactionScreenState
    extends ConsumerState<AdminCorrectTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amount = TextEditingController();
  final _reason = TextEditingController();
  late _CorrectionDirection _direction = widget.original.isInflow
      ? _CorrectionDirection.debit
      : _CorrectionDirection.credit;
  bool _submitting = false;

  @override
  void dispose() {
    _amount.dispose();
    _reason.dispose();
    super.dispose();
  }

  /// Pre-fills the form to fully reverse the original entry: same amount,
  /// direction opposite the original's effect on the fund balance.
  void _fillVoidInFull() {
    setState(() {
      _amount.text = widget.original.amount.toStringAsFixed(2);
      _direction = widget.original.isInflow
          ? _CorrectionDirection.debit
          : _CorrectionDirection.credit;
      _reason.text = 'Voided in full — recorded in error';
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    final magnitude = double.parse(_amount.text.trim());
    final signedAmount = _direction == _CorrectionDirection.credit
        ? magnitude
        : -magnitude;
    try {
      await ref
          .read(cloudFunctionsServiceProvider)
          .correctTransaction(
            originalTransactionId: widget.original.id,
            amount: signedAmount,
            reason: _reason.text.trim(),
          );
      if (mounted) {
        Navigator.of(context).pop();
        AppSnackbar.showSuccess(
          context,
          title: 'Correction recorded',
          message: 'The fund balance and audit trail have been updated.',
        );
      }
    } on CloudFunctionsApiException catch (e) {
      if (mounted) {
        AppSnackbar.showError(
          context,
          title: 'Could not record correction',
          message: e.message,
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final original = widget.original;

    return Scaffold(
      appBar: AppBar(title: const Text('Correct entry')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Original entry',
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      original.description,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      '${CurrencyFormatter.format(original.amount)} • '
                      '${DateFormatter.shortDate(original.date)}'
                      '${original.memberName != null ? ' • ${original.memberName}' : ''}',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            OutlinedButton.icon(
              onPressed: _fillVoidInFull,
              icon: const Icon(Icons.replay_outlined),
              label: const Text('Void this entry in full'),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Correction direction',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: AppSpacing.sm),
            SegmentedButton<_CorrectionDirection>(
              segments: const [
                ButtonSegment(
                  value: _CorrectionDirection.credit,
                  label: Text('Add back to fund'),
                  icon: Icon(Icons.add),
                ),
                ButtonSegment(
                  value: _CorrectionDirection.debit,
                  label: Text('Deduct from fund'),
                  icon: Icon(Icons.remove),
                ),
              ],
              selected: {_direction},
              onSelectionChanged: (selection) =>
                  setState(() => _direction = selection.first),
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              label: 'Correction amount (NPR)',
              controller: _amount,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              prefixText: 'Rs. ',
              validator: Validators.positiveAmount,
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              label: 'Reason for this correction',
              controller: _reason,
              maxLines: 3,
              validator: (v) => (v == null || v.trim().length < 3)
                  ? 'Explain the mistake being corrected'
                  : null,
            ),
            const SizedBox(height: AppSpacing.xl),
            AppButton(
              label: 'Record correction',
              isLoading: _submitting,
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }
}
