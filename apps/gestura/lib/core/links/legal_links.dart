import 'package:gestura/l10n/l10n.dart';

abstract final class LegalLinks {
  static const String host = 'gestura-prod.web.app';
  static const String fallbackLanguage = 'en';

  static Uri privacyPolicy(String languageCode) {
    final supported = AppLocalizations.supportedLocales.any(
      (locale) => locale.languageCode == languageCode,
    );
    return Uri.https(
      host,
      '/privacy/${supported ? languageCode : fallbackLanguage}',
    );
  }

  static final Uri deleteAccount = Uri.https(host, '/delete-account');
}
