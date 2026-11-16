import 'package:flutter/material.dart';
import 'package:gestura/config/app_info.dart';
import 'package:gestura/core/widgets/readable_inset.dart';
import 'package:gestura/features/auth/presentation/view_models/account_state.dart';
import 'package:gestura/features/offline/offline_pack_tile.dart';
import 'package:gestura/features/profile/presentation/widgets/account_card.dart';
import 'package:gestura/l10n/l10n.dart';
import 'package:gestura_ui/gestura_ui.dart';

typedef ProfileActions = ({
  VoidCallback onOpenStats,
  VoidCallback onOpenSettings,
  ValueChanged<Rect?> onExportData,
  VoidCallback onOpenAbout,
  VoidCallback onCreateAccount,
  VoidCallback onSignIn,
  VoidCallback onVerifyEmail,
  VoidCallback onSignOut,
  VoidCallback onDeleteAccount,
  VoidCallback onOpenAdmin,
});

class ProfileView extends StatelessWidget {
  const new({
    required this.appInfo,
    required this.account,
    required this.actions,
    super.key,
    this.isAdmin = false,
  });

  final AppInfo appInfo;
  final AccountState account;
  final ProfileActions actions;
  final bool isAdmin;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final sizes = context.gSizes;
    final screenPadding = context.windowSizeClass.screenPadding;
    final padding = EdgeInsetsDirectional.symmetric(horizontal: sizes.md);
    final error = Theme.of(context).colorScheme.error;

    if (account is AccountDeleting) {
      return Center(
        child: CircularProgressIndicator(semanticsLabel: l10n.deletingAccount),
      );
    }

    return ReadableInset(
      builder: (context, inset) => ListView(
        padding: EdgeInsetsDirectional.symmetric(
          horizontal: inset,
          vertical: sizes.xs,
        ),
        children:
            [
                  if (isAdmin)
                    Padding(
                      padding: EdgeInsetsDirectional.fromSTEB(
                        screenPadding,
                        0,
                        screenPadding,
                        sizes.sm,
                      ),
                      child: GHeroCard(
                        title: l10n.adminDashboard,
                        subtitle: l10n.adminEnter,
                        leading: Icon(
                          Icons.admin_panel_settings_rounded,
                          color: context.gColors.onHero,
                        ),
                        trailing: Icon(
                          Icons.arrow_forward_rounded,
                          color: context.gColors.onHero,
                        ),
                        onTap: actions.onOpenAdmin,
                      ),
                    ),
                  Padding(
                    padding: EdgeInsetsDirectional.fromSTEB(
                      screenPadding,
                      0,
                      screenPadding,
                      sizes.sm,
                    ),
                    child: AccountCard(
                      state: account,
                      onCreateAccount: actions.onCreateAccount,
                      onSignIn: actions.onSignIn,
                      onVerifyEmail: actions.onVerifyEmail,
                    ),
                  ),
                  _Group(
                    children: [
                      ListTile(
                        contentPadding: padding,
                        leading: const ExcludeSemantics(
                          child: Icon(Icons.insights_rounded),
                        ),
                        title: Text(l10n.statsTitle),
                        trailing: const ExcludeSemantics(
                          child: Icon(Icons.chevron_right),
                        ),
                        onTap: actions.onOpenStats,
                      ),
                      ListTile(
                        contentPadding: padding,
                        leading: const ExcludeSemantics(
                          child: Icon(Icons.settings_outlined),
                        ),
                        title: Text(l10n.settingsTitle),
                        trailing: const ExcludeSemantics(
                          child: Icon(Icons.chevron_right),
                        ),
                        onTap: actions.onOpenSettings,
                      ),
                      OfflinePackTile(padding: padding),
                    ],
                  ),
                  _Group(
                    children: [
                      Builder(
                        builder: (tile) => ListTile(
                          contentPadding: padding,
                          leading: const ExcludeSemantics(
                            child: Icon(Icons.file_download_outlined),
                          ),
                          title: Text(l10n.exportData),
                          subtitle: Text(l10n.exportDataHint),
                          onTap: () {
                            final box = tile.findRenderObject()! as RenderBox;
                            actions.onExportData(
                              box.localToGlobal(Offset.zero) & box.size,
                            );
                          },
                        ),
                      ),
                      ListTile(
                        contentPadding: padding,
                        leading: const ExcludeSemantics(
                          child: Icon(Icons.info_outline_rounded),
                        ),
                        title: Text(l10n.aboutApp),
                        subtitle: Text(l10n.appVersion(appInfo.label)),
                        trailing: const ExcludeSemantics(
                          child: Icon(Icons.chevron_right),
                        ),
                        onTap: actions.onOpenAbout,
                      ),
                    ],
                  ),
                  if (account case AccountGuest() || AccountMember())
                    _Group(
                      children: [
                        if (account is AccountMember)
                          ListTile(
                            contentPadding: padding,
                            leading: const ExcludeSemantics(
                              child: Icon(Icons.logout_rounded),
                            ),
                            title: Text(l10n.signOut),
                            onTap: actions.onSignOut,
                          ),
                        if (account case AccountGuest() || AccountMember())
                          ListTile(
                            contentPadding: padding,
                            leading: ExcludeSemantics(
                              child: Icon(
                                Icons.delete_forever_outlined,
                                color: error,
                              ),
                            ),
                            title: Text(
                              l10n.deleteAccount,
                              style: TextStyle(color: error),
                            ),
                            onTap: actions.onDeleteAccount,
                          ),
                      ],
                    ),
                ]
                .map(
                  (child) => switch (child) {
                    _Group() => Padding(
                      padding: EdgeInsetsDirectional.fromSTEB(
                        screenPadding,
                        0,
                        screenPadding,
                        sizes.sm,
                      ),
                      child: child,
                    ),
                    _ => child,
                  },
                )
                .toList(),
      ),
    );
  }
}

class _Group extends StatelessWidget {
  const new({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => GCard(
    tone: GCardTone.low,
    padding: EdgeInsetsDirectional.symmetric(vertical: context.gSizes.xxs),
    child: Column(children: children),
  );
}
