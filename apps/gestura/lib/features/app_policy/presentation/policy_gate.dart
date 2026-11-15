import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:gestura/config/app_info.dart';
import 'package:gestura/core/links/open_link.dart';
import 'package:gestura/core/share/link_sharer.dart';
import 'package:gestura/di/injection.dart';
import 'package:gestura/features/app_policy/domain/app_policy.dart';
import 'package:gestura/l10n/l10n.dart';
import 'package:gestura_ui/gestura_ui.dart';

const String androidPackage = 'app.gestura.com';

Uri storeLink(TargetPlatform platform) => switch (platform) {
  TargetPlatform.android => Uri.https(
    'play.google.com',
    '/store/apps/details',
    {'id': androidPackage},
  ),
  _ => Uri.parse(linkSite),
};

class PolicyGate extends StatefulWidget {
  const new({required this.child, super.key});

  final Widget child;

  @override
  State<PolicyGate> createState() => _PolicyGateState();
}

class _PolicyGateState extends State<PolicyGate> {
  final AppPolicySource _source = getIt<AppPolicySource>();
  final String _build = getIt<AppInfo>().buildNumber;
  late AppPolicy _policy = _source.current;
  late final StreamSubscription<AppPolicy> _changes;

  @override
  void initState() {
    super.initState();
    _changes = _source.watch().listen((policy) {
      if (policy != _policy) setState(() => _policy = policy);
    });
  }

  @override
  void dispose() {
    unawaited(_changes.cancel());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => switch (_policy.statusFor(_build)) {
    AppStatus.open => widget.child,
    AppStatus.needsUpdate => _Blocked(
      icon: Icons.system_update_rounded,
      title: context.l10n.updateRequiredTitle,
      message: context.l10n.updateRequiredMessage,
      action: context.l10n.updateAction,
      onAction: () =>
          unawaited(openLink(context, storeLink(defaultTargetPlatform))),
    ),
    AppStatus.maintenance => _Blocked(
      icon: Icons.construction_rounded,
      title: context.l10n.maintenanceTitle,
      message: context.l10n.maintenanceMessage,
      action: context.l10n.retry,
      onAction: () => unawaited(_source.refresh()),
    ),
  };
}

class _Blocked extends StatelessWidget {
  const new({
    required this.icon,
    required this.title,
    required this.message,
    required this.action,
    required this.onAction,
  });

  static const double iconSize = 56;

  final IconData icon;
  final String title;
  final String message;
  final String action;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sizes = context.gSizes;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsetsDirectional.all(sizes.xl),
            child: Column(
              children: [
                ExcludeSemantics(
                  child: Icon(
                    icon,
                    size: sizes.icon(iconSize),
                    color: theme.colorScheme.primary,
                  ),
                ),
                SizedBox(height: sizes.md),
                Semantics(
                  header: true,
                  child: Text(
                    title,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineSmall,
                  ),
                ),
                SizedBox(height: sizes.xs),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge,
                ),
                SizedBox(height: sizes.xl),
                GButton(label: action, onPressed: onAction),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
