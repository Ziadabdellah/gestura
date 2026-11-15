import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gestura/app/router/app_gate.dart';
import 'package:gestura/app/router/app_routes.dart';
import 'package:gestura/app/view/app_frame.dart';
import 'package:gestura/config/app_config.dart';
import 'package:gestura/core/telemetry/telemetry.dart';
import 'package:gestura/di/injection.dart';
import 'package:gestura/features/app_policy/domain/app_policy.dart';
import 'package:gestura/features/app_policy/presentation/policy_gate.dart';
import 'package:gestura/features/auth/domain/app_user.dart';
import 'package:gestura/features/auth/domain/auth_repository.dart';
import 'package:gestura/features/learner/learner_sync.dart';
import 'package:gestura/features/reminders/presentation/reminder_keeper.dart';
import 'package:gestura/features/settings/presentation/settings_presentation.dart';
import 'package:gestura/features/settings/presentation/view_models/settings_state.dart';
import 'package:gestura/features/settings/presentation/view_models/settings_view_model.dart';
import 'package:gestura/l10n/l10n.dart';
import 'package:gestura_ui/gestura_ui.dart';
import 'package:go_router/go_router.dart';

typedef Consent = ({bool analytics, bool crashReports});

class GesturaApp extends ConsumerStatefulWidget {
  const new({required this.config, super.key, this.initialLocation = '/'});

  final AppConfig config;
  final String initialLocation;

  @override
  ConsumerState<GesturaApp> createState() => _GesturaAppState();
}

class _GesturaAppState extends ConsumerState<GesturaApp> {
  final AuthRepository _auth = getIt<AuthRepository>();
  final Telemetry _telemetry = getIt<Telemetry>();
  final LearnerSync _sync = getIt<LearnerSync>();
  late final AppLifecycleListener _lifecycle;
  late final AppGate _gate;
  late final StreamSubscription<AppUser?> _user;
  late final GoRouter _router;

  static Consent _consentOf(SettingsState state) => (
    analytics: state.settings.analyticsConsent,
    crashReports: state.settings.crashReportsConsent,
  );

  void _applyConsent(Consent consent) => unawaited(
    _telemetry.applyConsent(
      analytics: consent.analytics,
      crashReports: consent.crashReports,
    ),
  );

  @override
  void initState() {
    super.initState();
    final settings = ref.read(settingsViewModelProvider);
    _applyConsent(_consentOf(settings));
    _gate = AppGate(
      onboarded: settings.settings.onboardingComplete,
      signedIn: _auth.currentUser != null,
    );
    _user = _auth.watchUser().listen((user) => _gate.signedIn = user != null);
    _sync.start();
    _lifecycle = AppLifecycleListener(
      onResume: () {
        unawaited(_sync.refresh());
        unawaited(getIt<AppPolicySource>().refresh());
      },
    );
    _router = createAppRouter(
      gate: _gate,
      initialLocation: widget.initialLocation,
    );
  }

  @override
  void dispose() {
    unawaited(_user.cancel());
    _lifecycle.dispose();
    _sync.stop();
    _router.dispose();
    _gate.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref
      ..listen(
        settingsViewModelProvider.select(
          (state) => state.settings.onboardingComplete,
        ),
        (_, onboarded) => _gate.onboarded = onboarded,
      )
      ..listen(
        settingsViewModelProvider.select(_consentOf),
        (_, consent) => _applyConsent(consent),
      );
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
        builder: (context, child) => ReminderKeeper(
          child: AppFrame(
            flavor: widget.config.flavor,
            reduceMotion: settings.reduceMotion,
            child: PolicyGate(child: child!),
          ),
        ),
      ),
    );
  }
}
