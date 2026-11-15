import 'dart:async';

import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gestura/app/router/app_routes.dart';
import 'package:gestura/di/injection.dart';
import 'package:gestura/features/auth/domain/app_user.dart';

import '../../../helpers/fake_auth_repository.dart';
import '../../../helpers/golden_scenario.dart';
import '../../../helpers/pump_app.dart';

void main() {
  group('signed out', () {
    setUp(() => registerFakes(auth: FakeAuthRepository(null)));
    tearDown(getIt.reset);

    unawaited(
      goldenTest(
        'Welcome in English and Arabic, light and dark',
        fileName: 'welcome_page',
        builder: () => GoldenTestGroup(
          columns: 4,
          children: [
            for (final settings in goldenSettings)
              appScenario(
                settings: settings,
                location: const WelcomeRoute().location,
                size: const Size(360, 780),
              ),
          ],
        ),
      ),
    );

    unawaited(
      goldenTest(
        'Sign in, create account and reset password',
        fileName: 'auth_forms',
        builder: () => GoldenTestGroup(
          columns: 3,
          children: [
            for (final settings in [goldenSettings.first, goldenSettings.last])
              for (final route in [
                const SignInRoute().location,
                const CreateAccountRoute().location,
              ])
                appScenario(
                  settings: settings,
                  location: route,
                  size: const Size(360, 780),
                ),
            for (final settings in [goldenSettings[1], goldenSettings[2]])
              appScenario(
                settings: settings,
                location: const ResetPasswordRoute().location,
                size: const Size(360, 780),
              ),
          ],
        ),
      ),
    );
  });

  group('member waiting for confirmation', () {
    setUp(
      () => registerFakes(
        auth: FakeAuthRepository(
          const MemberUser(
            'member-uid',
            email: 'learner@example.com',
            emailVerified: false,
          ),
        ),
      ),
    );
    tearDown(getIt.reset);

    unawaited(
      goldenTest(
        'Confirm the email address',
        fileName: 'verify_email_page',
        builder: () => GoldenTestGroup(
          columns: 4,
          children: [
            for (final settings in goldenSettings)
              appScenario(
                settings: settings,
                location: const VerifyEmailRoute().location,
                size: const Size(360, 780),
              ),
          ],
        ),
      ),
    );

    unawaited(
      goldenTest(
        'Profile of a member who has not confirmed the email',
        fileName: 'profile_member',
        builder: () => GoldenTestGroup(
          columns: 2,
          children: [
            for (final settings in [goldenSettings.first, goldenSettings.last])
              appScenario(
                settings: settings,
                location: const ProfileRoute().location,
                size: const Size(360, 640),
              ),
          ],
        ),
      ),
    );
  });
}
