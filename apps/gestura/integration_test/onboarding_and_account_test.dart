import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gestura/app/gestura_app.dart';
import 'package:gestura/config/app_config.dart';
import 'package:gestura/di/injection.dart';
import 'package:gestura/features/auth/presentation/pages/welcome_page.dart';
import 'package:gestura/features/settings/domain/app_settings.dart';
import 'package:gestura/features/settings/domain/settings_repository.dart';
import 'package:gestura/features/today/presentation/pages/today_page.dart';
import 'package:gestura_ui/gestura_ui.dart';
import 'package:integration_test/integration_test.dart';

import 'support/emulated_auth.dart';

const AppConfig _dev = AppConfig(flavor: Flavor.dev);
const String _password = 'signing-is-fun';

Future<void> _open(
  WidgetTester tester, {
  required AppSettings settings,
  String initialLocation = '/',
}) async {
  await emulatedAuth();
  await configureDependencies(_dev);
  await getIt<SettingsRepository>().save(settings);
  await tester.pumpWidget(
    ProviderScope(
      child: GesturaApp(config: _dev, initialLocation: initialLocation),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _tapButton(WidgetTester tester, String label) async {
  final button = find.widgetWithText(GButton, label);
  await tester.ensureVisible(button);
  await tester.pumpAndSettle();
  await tester.tap(button);
  await tester.pumpAndSettle();
}

Future<void> _fill(WidgetTester tester, String email) async {
  await tester.enterText(find.byType(TextFormField).first, email);
  await tester.enterText(find.byType(TextFormField).last, _password);
  await tester.testTextInput.receiveAction(TextInputAction.done);
  await tester.pumpAndSettle();
}

User? get _user => FirebaseAuth.instance.currentUser;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() async {
    await getIt<SettingsRepository>().save(AppSettings.defaults);
    await getIt.reset();
    await signOutEverywhere();
  });

  testWidgets('a new learner goes through onboarding and starts as a guest', (
    tester,
  ) async {
    await _open(
      tester,
      settings: const AppSettings(language: AppLanguage.english),
    );

    await _tapButton(tester, 'Get started');
    await _tapButton(tester, 'Continue');
    await tester.tap(find.text('5 minutes a day'));
    await _tapButton(tester, 'Continue');
    await tester.tap(find.text('Left hand'));
    await _tapButton(tester, 'Continue');
    await tester.tap(find.text('Crash reports'));
    await _tapButton(tester, 'Continue');

    expect(find.byType(WelcomePage), findsOneWidget);

    await _tapButton(tester, 'Continue as guest');

    expect(find.byType(TodayPage), findsOneWidget);
    expect(_user?.isAnonymous, isTrue);
    expect(
      getIt<SettingsRepository>().load(),
      const AppSettings(
        language: AppLanguage.english,
        signLanguage: 'demo',
        dailyGoal: DailyGoal.five,
        dominantHand: DominantHand.left,
        crashReportsConsent: true,
        onboardingComplete: true,
      ),
    );
  });

  testWidgets('a guest keeps the same account after signing up and '
      'confirms the email', (tester) async {
    final guest = await signInAsGuest();
    final email = uniqueEmail();
    await _open(
      tester,
      settings: const AppSettings(
        language: AppLanguage.english,
        onboardingComplete: true,
      ),
      initialLocation: '/profile',
    );

    expect(find.text("You're learning as a guest"), findsOneWidget);

    await _tapButton(tester, 'Create account');
    await _fill(tester, email);

    expect(find.text('Check your inbox'), findsOneWidget);
    expect(_user?.uid, guest.uid);
    expect(_user?.isAnonymous, isFalse);
    expect(_user?.email, email);

    await _tapButton(tester, "I've confirmed it");

    expect(
      find.text(
        "Your email address isn't confirmed yet. Open the link in the "
        'email, then try again.',
      ),
      findsOneWidget,
    );

    await confirmEmailFromInbox(email);
    await _tapButton(tester, "I've confirmed it");

    expect(find.text(email), findsOneWidget);
    expect(find.text('Email confirmed'), findsOneWidget);
    expect(_user?.emailVerified, isTrue);
  });

  testWidgets('a member signs out and signs back in', (tester) async {
    final email = uniqueEmail();
    final auth = await emulatedAuth();
    await auth.createUserWithEmailAndPassword(
      email: email,
      password: _password,
    );
    await _open(
      tester,
      settings: const AppSettings(
        language: AppLanguage.english,
        onboardingComplete: true,
      ),
      initialLocation: '/profile',
    );

    await tester.tap(find.text('Sign out'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Sign out'));
    await tester.pumpAndSettle();

    expect(find.byType(WelcomePage), findsOneWidget);
    expect(_user, isNull);

    await _tapButton(tester, 'I already have an account');
    await tester.enterText(find.byType(TextFormField).first, email);
    await tester.enterText(find.byType(TextFormField).last, 'wrong-password');
    await _tapButton(tester, 'Sign in');

    expect(find.text('The email or password is incorrect.'), findsOneWidget);

    await _fill(tester, email);

    expect(find.byType(TodayPage), findsOneWidget);
    expect(_user?.email, email);
  });
}
