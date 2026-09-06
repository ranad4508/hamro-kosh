import 'package:flutter/material.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/asset_paths.dart';

/// Shared chrome (logo, title, subtitle, scrollable body) for the
/// login/register/forgot-password screens so only the form fields differ.
class AuthScaffold extends StatelessWidget {
  const AuthScaffold({
    super.key,
    required this.title,
    required this.subtitle,
    required this.children,
    this.showLogo = true,
  });

  final String title;
  final String subtitle;
  final List<Widget> children;
  final bool showLogo;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final canPop = Navigator.canPop(context);

    return Scaffold(
      // Register and Forgot-password are pushed on top of Login, but this
      // shared scaffold has no AppBar (an AppBar would auto-add a back
      // button) — add one explicitly whenever there's somewhere to go back
      // to, so it's never a dead end back to the OS.
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
                      Text(title, style: theme.textTheme.headlineSmall),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        subtitle,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
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
