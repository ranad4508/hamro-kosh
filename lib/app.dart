import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/localization/locale_controller.dart';
import 'core/router/app_router.dart';
import 'core/security/app_lock_screen.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_mode_controller.dart';
import 'l10n/generated/app_localizations.dart';

/// The app root: wires theme mode, locale, routing, and the app-lock gate
/// together. Kept intentionally thin — each concern lives in its own
/// controller/provider under `core/`.
class HamroKoshApp extends ConsumerWidget {
  const HamroKoshApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeControllerProvider);
    final locale = ref.watch(localeControllerProvider);
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'Hamro Kosh',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      locale: locale,
      supportedLocales: supportedAppLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      routerConfig: router,
      builder: (context, child) => AppLockGate(child: child ?? const SizedBox.shrink()),
    );
  }
}
