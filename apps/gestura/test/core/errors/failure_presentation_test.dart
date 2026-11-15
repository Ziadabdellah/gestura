import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gestura/core/errors/failure_presentation.dart';
import 'package:gestura/l10n/l10n.dart';
import 'package:gestura_core/gestura_core.dart';

const List<Failure> _failures = [
  NetworkFailure(),
  NotFoundFailure(),
  PermissionDeniedFailure(),
  StorageFullFailure(),
  UnexpectedFailure('boom'),
  NoContentFailure(),
  AuthFailure(AuthProblem.invalidEmail),
  AuthFailure(AuthProblem.wrongCredentials),
  AuthFailure(AuthProblem.emailInUse),
  AuthFailure(AuthProblem.weakPassword),
  AuthFailure(AuthProblem.tooManyRequests),
  AuthFailure(AuthProblem.accountDisabled),
  AuthFailure(AuthProblem.unavailable),
  AuthFailure(AuthProblem.signInAgain),
  AuthFailure(AuthProblem.cancelled),
];

void main() {
  test('gives every failure its own message in English', () {
    final l10n = lookupAppLocalizations(const Locale('en'));

    expect(
      [for (final failure in _failures) failure.message(l10n)],
      [
        "You're offline. Check your connection and try again.",
        "We couldn't find what you're looking for.",
        "You don't have access to this.",
        'Your device is out of space. Free some up and try again.',
        'Something unexpected happened. Please try again.',
        'Lessons for this sign language are on their way. Check again soon.',
        "That email address doesn't look right.",
        'The email or password is incorrect.',
        'An account with this email already exists. Sign in instead.',
        'Choose a stronger password.',
        'Too many attempts. Wait a moment and try again.',
        'This account has been turned off.',
        "Signing in isn't available right now. Please try again later.",
        'For your security, enter your password again.',
        'Sign-in was cancelled.',
      ],
    );
  });

  for (final locale in AppLocalizations.supportedLocales) {
    test('explains every failure differently in ${locale.languageCode}', () {
      final l10n = lookupAppLocalizations(locale);
      final messages = {for (final failure in _failures) failure.message(l10n)};

      expect(messages, hasLength(_failures.length));
      expect(messages.every((message) => message.trim().isNotEmpty), isTrue);
    });
  }

  test('gives every kind of failure its own icon', () {
    expect({for (final failure in _failures) failure.icon}, hasLength(7));
    expect(
      const AuthFailure(AuthProblem.weakPassword).icon,
      const AuthFailure(AuthProblem.unavailable).icon,
    );
  });
}
