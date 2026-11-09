import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gestura/app/router/app_routes.dart';
import 'package:gestura/app/view/app_frame.dart';
import 'package:gestura/config/app_config.dart';
import 'package:gestura/features/settings/presentation/settings_presentation.dart';
import 'package:gestura/features/settings/presentation/view_models/settings_view_model.dart';
import 'package:gestura/l10n/l10n.dart';
import 'package:gestura_ui/gestura_ui.dart';
import 'package:go_router/go_router.dart';

class GesturaApp extends ConsumerStatefulWidget {
  const new({required this.config, super.key, this.initialLocation = '/'});

  final AppConfig config;
  final String initialLocation;

  @override
  ConsumerState<GesturaApp> createState() => _GesturaAppState();
}

class _GesturaAppState extends ConsumerState<GesturaApp> {
  late final GoRouter _router = createAppRouter(
    initialLocation: widget.initialLocation,
  );

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(
      settingsViewModelProvider.select((state) => state.settings),
    );
    return GesturaAdaptiveBuilder(
      builder: (context, scale) => MaterialApp.router(
        routerConfig: _router,
        onGenerateTitle: (context) => context.l10n.appTitle,
        theme: GesturaTheme.light(scale: scale),
        darkTheme: GesturaTheme.dark(scale: scale),
        themeMode: settings.theme.themeMode,
        locale: settings.language.locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        debugShowCheckedModeBanner: false,
        builder: (context, child) => AppFrame(
          flavor: widget.config.flavor,
          reduceMotion: settings.reduceMotion,
          child: child!,
        ),
      ),
    );
  }
}
