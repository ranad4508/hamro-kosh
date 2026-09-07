// Smoke tests for pieces that don't require a live Firebase project.
//
// Testing `HamroKoshApp` itself needs a mocked Firebase (firebase_auth
// depends on platform channels that aren't available under `flutter test`)
// — that's a natural follow-up once `flutterfire configure` has been run
// with a real project. See README.md → "Testing".

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hamro_kosh/core/theme/app_theme.dart';
import 'package:hamro_kosh/core/theme/finance_colors.dart';
import 'package:hamro_kosh/core/utils/currency_formatter.dart';
import 'package:hamro_kosh/core/widgets/app_button.dart';

void main() {
  test('AppTheme builds valid light and dark ThemeData', () {
    final light = AppTheme.dark();
    final dark = AppTheme.dark();

    expect(light.brightness, Brightness.light);
    expect(dark.brightness, Brightness.dark);
    expect(light.extension<FinanceColors>(), isNotNull);
    expect(dark.extension<FinanceColors>(), isNotNull);
  });

  test('CurrencyFormatter formats NPR amounts', () {
    expect(CurrencyFormatter.format(1500), contains('1,500'));
    expect(CurrencyFormatter.format(1500), startsWith('Rs.'));
  });

  testWidgets('AppButton shows a spinner while loading', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppButton(label: 'Submit', isLoading: true, onPressed: () {}),
        ),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Submit'), findsNothing);
  });
}
