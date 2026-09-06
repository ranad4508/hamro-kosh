import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/fade_slide_in.dart';
import '../terms_content.dart';

/// Renders the Terms & Conditions (SRS §48). With [requireAcceptance] set,
/// this is the onboarding gate shown once after registration; otherwise
/// it's the read-only viewer reached from Profile → Terms & Conditions.
class TermsScreen extends StatefulWidget {
  const TermsScreen({super.key, this.requireAcceptance = false});

  final bool requireAcceptance;

  @override
  State<TermsScreen> createState() => _TermsScreenState();
}

class _TermsScreenState extends State<TermsScreen> {
  bool _accepted = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Terms & Conditions')),
      body: Column(
        children: [
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.lg),
              itemCount: termsSections.length,
              separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.lg),
              itemBuilder: (context, index) {
                final section = termsSections[index];
                return FadeSlideIn(
                  delay: Duration(milliseconds: 30 * index),
                  duration: const Duration(milliseconds: 250),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${index + 1}. ${section.title}',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(section.body),
                    ],
                  ),
                );
              },
            ),
          ),
          if (widget.requireAcceptance)
            SafeArea(
              minimum: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    value: _accepted,
                    onChanged: (value) =>
                        setState(() => _accepted = value ?? false),
                    title: const Text(
                      'I have read and accept the Terms & Conditions',
                    ),
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                  AppButton(
                    label: 'Continue',
                    onPressed: _accepted ? () => context.go('/home') : null,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
