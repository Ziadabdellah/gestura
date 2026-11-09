import 'dart:convert';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gestura/l10n/l10n.dart';

const _languages = ['en', 'ar', 'ru', 'es', 'fr', 'de'];

Map<String, dynamic> _readArb(String language) =>
    jsonDecode(File('lib/l10n/arb/app_$language.arb').readAsStringSync())
        as Map<String, dynamic>;

Set<String> _messageKeys(Map<String, dynamic> arb) =>
    arb.keys.where((key) => !key.startsWith('@')).toSet();

void main() {
  final template = _readArb('en');

  test('the app supports exactly the six interface languages', () {
    expect(
      AppLocalizations.supportedLocales.map((locale) => locale.languageCode),
      unorderedEquals(_languages),
    );
  });

  for (final language in _languages) {
    group('app_$language.arb', () {
      final arb = _readArb(language);

      test('declares its own locale', () {
        expect(arb['@@locale'], language);
      });

      test('has every message of the English template and nothing else', () {
        expect(_messageKeys(arb), _messageKeys(template));
      });

      test('has no empty messages', () {
        for (final key in _messageKeys(arb)) {
          expect((arb[key] as String).trim(), isNotEmpty, reason: key);
        }
      });

      test('keeps the placeholders of the template', () {
        for (final key in _messageKeys(template)) {
          final placeholders = RegExp(r'\{(\w+)[,}]')
              .allMatches(template[key] as String)
              .map((match) => match.group(1))
              .toSet();
          for (final placeholder in placeholders) {
            expect(
              arb[key] as String,
              contains('{$placeholder'),
              reason: '$key misses {$placeholder}',
            );
          }
        }
      });
    });
  }

  test('every language names itself differently', () {
    final names = _languages.map(
      (language) => lookupAppLocalizations(Locale(language)).languageName,
    );

    expect(names.toSet(), hasLength(_languages.length));
  });
}
