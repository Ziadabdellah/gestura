import 'package:flutter_test/flutter_test.dart';
import 'package:gestura/features/app_policy/domain/app_policy.dart';
import 'package:gestura/features/learn/presentation/pages/learn_page.dart';
import 'package:gestura/features/settings/domain/app_settings.dart';

import '../../helpers/fake_policy_source.dart';
import '../../helpers/pump_app.dart';

void main() {
  testWidgets('asks an old build to update and opens the store', (
    tester,
  ) async {
    await tester.pumpApp(
      policy: FakePolicySource(const AppPolicy(minBuild: 999)),
    );

    expect(find.text('Time to update'), findsOneWidget);
    expect(find.byType(LearnPage), findsNothing);

    await tester.tap(find.text('Update'));
    await tester.pumpAndSettle();

    expect(fakeLinks.launched, isNotEmpty);
  });

  testWidgets('shows maintenance live and opens again when it ends', (
    tester,
  ) async {
    final policy = FakePolicySource();
    await tester.pumpApp(policy: policy);
    expect(find.byType(LearnPage), findsOneWidget);

    policy.publish(const AppPolicy(maintenance: true));
    await tester.pumpAndSettle();
    expect(find.text('Back soon'), findsOneWidget);

    await tester.tap(find.text('Try again'));
    expect(policy.refreshes, 1);

    policy.publish(AppPolicy.open);
    await tester.pumpAndSettle();
    expect(find.byType(LearnPage), findsOneWidget);
  });

  for (final settings in [
    englishLight,
    const AppSettings(
      language: AppLanguage.arabic,
      theme: AppThemePreference.dark,
      onboardingComplete: true,
    ),
  ]) {
    testWidgets('meets the accessibility guidelines in '
        '${settings.language.name}', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpApp(
        settings: settings,
        policy: FakePolicySource(const AppPolicy(maintenance: true)),
      );

      await tester.expectAccessible();
      handle.dispose();
    });
  }
}
