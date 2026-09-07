import 'package:flutter/material.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/asset_paths.dart';
import '../../../../core/widgets/bilingual_text.dart';

/// Shared chrome (logo, title, subtitle, scrollable body) for the
/// register/sign-in/forgot-password/set-password screens so only the form
/// fields differ. Titles are bilingual (`design_spec.md` §4a/§5) since the
/// join screen is the one place a member chooses which language leads.
class AuthScaffold extends StatelessWidget {
  const AuthScaffold({
    super.key,
    required this.titleEn,
    required this.titleNe,
    required this.subtitleEn,
    required this.subtitleNe,
    required this.children,
    this.showLogo = true,
  });

  final String titleEn;
  final String titleNe;
  final String subtitleEn;
  final String subtitleNe;
  final List<Widget> children;
  final bool showLogo;

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.canPop(context);

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    canPop ? AppSpacing.xxl : AppSpacing.lg,
                    AppSpacing.lg,
                    AppSpacing.lg,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (showLogo) ...[
                        Center(
                          child: Image.asset(AssetPaths.logoMark, height: 64),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                      ],
                      BilingualText(
                        titleEn,
                        titleNe,
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      BilingualText(
                        subtitleEn,
                        subtitleNe,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      ...children,
                    ],
                  ),
                ),
              ),
            ),
            if (canPop)
              Positioned(
                top: AppSpacing.sm,
                left: AppSpacing.sm,
                child: IconButton.filledTonal(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.arrow_back),
                  tooltip: 'Back',
                ),
              ),
          ],
        ),
      ),
    );
  }
}
