import 'package:gestura/l10n/l10n.dart';

abstract final class LegalLinks {
  static const String host = 'gestura-prod.web.app';
  static const String fallbackLanguage = 'en';

  static Uri privacyPolicy(String languageCode) =>
      _localized('privacy', languageCode);

  static Uri terms(String languageCode) => _localized('terms', languageCode);

  static Uri _localized(String page, String languageCode) {
    final supported = AppLocalizations.supportedLocales.any(
      (locale) => locale.languageCode == languageCode,
    );
    return Uri.https(
      host,
      '/$page/${supported ? languageCode : fallbackLanguage}',
    );
  }

  static final Uri deleteAccount = Uri.https(host, '/delete-account');
}
