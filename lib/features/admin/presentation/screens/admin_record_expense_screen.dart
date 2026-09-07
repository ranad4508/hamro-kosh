import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/models/expense_category.dart';
import '../../../../core/services/cloud_functions_service.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_select_field.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/proof_picker.dart';

/// SRS §17 — admin records a community expense. There's no member claim to
/// verify first (the admin who spent the money is the one entering it), but
/// the write still goes through `recordExpense` (Cloud Function) rather
/// than a direct Firestore write, since the fund total has to move with it.
class AdminRecordExpenseScreen extends ConsumerStatefulWidget {
  const AdminRecordExpenseScreen({super.key});

  @override
  ConsumerState<AdminRecordExpenseScreen> createState() =>
      _AdminRecordExpenseScreenState();
}

class _AdminRecordExpenseScreenState
    extends ConsumerState<AdminRecordExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amount = TextEditingController();
  final _description = TextEditingController();
  final _recipient = TextEditingController();
  ExpenseCategory _category = ExpenseCategory.communityEvent;
  String _paymentMethod = 'Cash';
  String? _proofUrl;
  bool _submitting = false;

  @override
  void dispose() {
    _amount.dispose();
    _description.dispose();
    _recipient.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    try {
      await ref
          .read(cloudFunctionsServiceProvider)
          .recordExpense(
            amount: double.parse(_amount.text.trim()),
            category: _category.name,
            description: _description.text.trim(),
            recipient: _recipient.text.trim().isEmpty
                ? null
                : _recipient.text.trim(),
            paymentMethod: _paymentMethod,
            proofUrl: _proofUrl,
          );
      if (mounted) {
        Navigator.of(context).pop();
        AppSnackbar.showSuccess(
          context,
          title: 'Expense recorded',
          message: 'The fund balance has been updated.',
        );
      }
    } on CloudFunctionsApiException catch (e) {
      if (mounted) {
        AppSnackbar.showError(
          context,
          title: 'Could not record expense',
          message: e.message,
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Record expense')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            AppTextField(
              label: 'Amount (NPR)',
              controller: _amount,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              prefixText: 'Rs. ',
              validator: Validators.positiveAmount,
            ),
            const SizedBox(height: AppSpacing.md),
            AppSelectField<ExpenseCategory>(
              label: 'Category',
              value: _category,
              items: ExpenseCategory.values,
              itemLabel: (c) => c.label(context),
              onChanged: (value) => setState(() => _category = value),
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              label: 'Description',
              controller: _description,
              maxLines: 2,
              validator: (v) => Validators.required(v, field: 'Description'),
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              label: 'Recipient (optional)',
              controller: _recipient,
              prefixIcon: Icons.person_outline,
            ),
            const SizedBox(height: AppSpacing.md),
            AppSelectField<String>(
              label: 'Payment method',
              value: _paymentMethod,
              items: const ['Cash', 'Bank transfer', 'eSewa / Khalti'],
              itemLabel: (v) => v,
              onChanged: (value) => setState(() => _paymentMethod = value),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Receipt (recommended)',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.xs),
            ProofPicker(
              currentUrl: _proofUrl,
              onChanged: (url) => setState(() => _proofUrl = url),
              folder: 'hamro_kosh/expense_receipts',
              label: 'Attach a receipt (optional)',
            ),
            const SizedBox(height: AppSpacing.xl),
            AppButton(
              label: 'Record expense',
              isLoading: _submitting,
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }
}
