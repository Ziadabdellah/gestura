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

  test('gives every failure its own icon', () {
    expect({
      for (final failure in _failures) failure.icon,
    }, hasLength(_failures.length));
  });
}
