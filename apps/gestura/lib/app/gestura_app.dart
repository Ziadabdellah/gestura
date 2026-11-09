import 'package:flutter/material.dart';
import 'package:gestura/app/view/flavor_banner.dart';
import 'package:gestura/app/view/home_page.dart';
import 'package:gestura/config/app_config.dart';
import 'package:gestura/l10n/l10n.dart';
import 'package:gestura_ui/gestura_ui.dart';

class GesturaApp extends StatelessWidget {
  const new({
    required this.config,
    super.key,
    this.locale,
    this.themeMode = ThemeMode.system,
  });

  final AppConfig config;
  final Locale? locale;
  final ThemeMode themeMode;

  @override
  Widget build(BuildContext context) => GesturaAdaptiveBuilder(
    builder: (context, scale) => MaterialApp(
      onGenerateTitle: (context) => context.l10n.appTitle,
      theme: GesturaTheme.light(scale: scale),
      darkTheme: GesturaTheme.dark(scale: scale),
      themeMode: themeMode,
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      debugShowCheckedModeBanner: false,
      builder: (context, child) => switch (config.flavor) {
        Flavor.prod => child!,
        Flavor.dev ||
        Flavor.staging => FlavorBanner(flavor: config.flavor, child: child!),
      },
      home: const HomePage(),
    ),
  );
}
