import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:gestura_ui/gestura_ui.dart';

const supportedTestLocales = [
  Locale('en'),
  Locale('ar'),
  Locale('ru'),
  Locale('es'),
  Locale('fr'),
  Locale('de'),
];

typedef GoldenVariant = ({String name, Locale locale, Brightness brightness});

const List<GoldenVariant> ltrRtlLightDark = [
  (name: 'en light', locale: Locale('en'), brightness: Brightness.light),
  (name: 'en dark', locale: Locale('en'), brightness: Brightness.dark),
  (name: 'ar light', locale: Locale('ar'), brightness: Brightness.light),
  (name: 'ar dark', locale: Locale('ar'), brightness: Brightness.dark),
];

ThemeData themeFor(
  Brightness brightness, {
  GesturaScale scale = GesturaScale.identity,
}) => GesturaTheme.forBrightness(brightness, scale: scale);

class GesturaTestScope extends StatelessWidget {
  const new({
    required this.child,
    super.key,
    this.locale = const Locale('en'),
    this.brightness = Brightness.light,
    this.width = 320,
    this.scale = GesturaScale.identity,
  });

  final Widget child;
  final Locale locale;
  final Brightness brightness;
  final double width;
  final GesturaScale scale;

  @override
  Widget build(BuildContext context) {
    final theme = themeFor(brightness, scale: scale);
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(disableAnimations: true),
      child: Localizations(
        locale: locale,
        delegates: GlobalMaterialLocalizations.delegates,
        child: Theme(
          data: theme,
          child: Material(
            color: theme.colorScheme.surface,
            child: Padding(
              padding: const EdgeInsetsDirectional.all(GesturaSpacing.md),
              child: SizedBox(width: width, child: child),
            ),
          ),
        ),
      ),
    );
  }
}
