import 'package:flutter/widgets.dart';
import 'package:gestura/l10n/gen/app_localizations.dart';

export 'package:gestura/l10n/gen/app_localizations.dart';

extension AppLocalizationsContext on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}
