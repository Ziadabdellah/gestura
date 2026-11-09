import 'package:flutter/material.dart';
import 'package:gestura/config/app_info.dart';
import 'package:gestura/core/widgets/readable_inset.dart';
import 'package:gestura/l10n/l10n.dart';
import 'package:gestura_ui/gestura_ui.dart';

class ProfileView extends StatelessWidget {
  const new({
    required this.appInfo,
    required this.onOpenSettings,
    required this.onOpenAbout,
    super.key,
  });

  final AppInfo appInfo;
  final VoidCallback onOpenSettings;
  final VoidCallback onOpenAbout;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final padding = EdgeInsetsDirectional.symmetric(
      horizontal: context.windowSizeClass.screenPadding,
    );

    return ReadableInset(
      builder: (context, inset) => ListView(
        padding: EdgeInsetsDirectional.symmetric(
          horizontal: inset,
          vertical: context.gSizes.xs,
        ),
        children: [
          ListTile(
            contentPadding: padding,
            leading: const ExcludeSemantics(
              child: Icon(Icons.settings_outlined),
            ),
            title: Text(l10n.settingsTitle),
            trailing: const ExcludeSemantics(child: Icon(Icons.chevron_right)),
            onTap: onOpenSettings,
          ),
          ListTile(
            contentPadding: padding,
            leading: const ExcludeSemantics(
              child: Icon(Icons.info_outline_rounded),
            ),
            title: Text(l10n.aboutApp),
            subtitle: Text(l10n.appVersion(appInfo.label)),
            trailing: const ExcludeSemantics(child: Icon(Icons.chevron_right)),
            onTap: onOpenAbout,
          ),
        ],
      ),
    );
  }
}
