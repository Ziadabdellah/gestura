import 'package:flutter/material.dart';
import 'package:gestura/app/router/app_routes.dart';
import 'package:gestura/config/app_info.dart';
import 'package:gestura/di/injection.dart';
import 'package:gestura/features/profile/presentation/widgets/profile_view.dart';
import 'package:gestura/l10n/l10n.dart';

class ProfilePage extends StatelessWidget {
  const new({super.key});

  static const String applicationName = 'Gestura';

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final appInfo = getIt<AppInfo>();

    return Scaffold(
      appBar: AppBar(title: Text(l10n.tabProfile)),
      body: ProfileView(
        appInfo: appInfo,
        onOpenSettings: () => const SettingsRoute().go(context),
        onOpenAbout: () => showLicensePage(
          context: context,
          applicationName: applicationName,
          applicationVersion: appInfo.label,
          applicationLegalese: l10n.aboutLegalese,
        ),
      ),
    );
  }
}
