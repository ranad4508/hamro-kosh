import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/bilingual_text.dart';
import '../../../../core/widgets/fade_slide_in.dart';
import '../terms_content.dart';

/// Renders the fund's actual 16 bylaws, grouped and bilingual
/// (`design_spec.md` §3, screen `4b`). With [requireAcceptance] set, this is
/// the onboarding gate shown once after registration is approved; otherwise
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
    var ruleIndex = 0;

    return Scaffold(
      appBar: AppBar(
        title: const BilingualText(
          'Terms and conditions',
          'नियम र सर्तहरू',
          layout: BilingualLayout.inline,
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [
                BilingualText(
                  'This is a non-profit fund.',
                  'यो नाफारहित कोष हो।',
                  style: TextStyle(
                    fontSize: 13,
                    color: context.colors.textTertiary,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                for (final group in termsGroups) ...[
                  BilingualText(
                    group.titleEn,
                    group.titleNe,
                    layout: BilingualLayout.inline,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: context.colors.accent,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  for (final rule in group.rules)
                    FadeSlideIn(
                      delay: Duration(milliseconds: 25 * ruleIndex++),
                      duration: const Duration(milliseconds: 220),
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.md),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: 26,
                              child: Text(
                                '${rule.number}.',
                                style: TextStyle(
                                  color: context.colors.textQuaternary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            Expanded(
                              child: BilingualText(
                                rule.textEn,
                                rule.textNe,
                                style: const TextStyle(fontSize: 13.5, height: 1.5),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: AppSpacing.sm),
                ],
              ],
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
                    title: const BilingualText(
                      'I have read and accept these terms',
                      'मैले यी सर्तहरू पढेको र स्वीकार गरेको छु',
                      layout: BilingualLayout.inline,
                    ),
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                  AppButton(
                    label: 'Accept · स्वीकार गर्नुहोस्',
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
