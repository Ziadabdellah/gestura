import 'package:flutter_test/flutter_test.dart';
import 'package:gestura/core/links/legal_links.dart';

void main() {
  test('links the privacy policy in each interface language', () {
    for (final code in ['en', 'ar', 'ru', 'es', 'fr', 'de']) {
      expect(
        LegalLinks.privacyPolicy(code).toString(),
        'https://gestura-prod.web.app/privacy/$code',
      );
    }
  });

  test('falls back to English for any other language', () {
    expect(
      LegalLinks.privacyPolicy('it').toString(),
      'https://gestura-prod.web.app/privacy/en',
    );
  });

  test('links the account deletion page', () {
    expect(
      LegalLinks.deleteAccount.toString(),
      'https://gestura-prod.web.app/delete-account',
    );
  });
}
