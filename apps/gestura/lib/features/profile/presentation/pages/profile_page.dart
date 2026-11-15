import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gestura/app/router/app_routes.dart';
import 'package:gestura/config/app_info.dart';
import 'package:gestura/core/errors/failure_presentation.dart';
import 'package:gestura/di/injection.dart';
import 'package:gestura/features/auth/domain/auth_entry.dart';
import 'package:gestura/features/auth/domain/auth_repository.dart';
import 'package:gestura/features/auth/presentation/view_models/account_state.dart';
import 'package:gestura/features/auth/presentation/view_models/account_view_model.dart';
import 'package:gestura/features/learner/learner_cloud.dart';
import 'package:gestura/features/learner/learner_data.dart';
import 'package:gestura/features/profile/presentation/widgets/delete_account_dialog.dart';
import 'package:gestura/features/profile/presentation/widgets/profile_view.dart';
import 'package:gestura/features/profile/presentation/widgets/sign_out_dialog.dart';
import 'package:gestura/l10n/l10n.dart';
import 'package:gestura_core/gestura_core.dart';

class ProfilePage extends StatelessWidget {
  const new({super.key});

  static const String applicationName = 'Gestura';

  static Future<void> signOut(BuildContext context) async {
    final viewModel = context.read<AccountViewModel>();
    final messenger = ScaffoldMessenger.of(context);
    final l10n = context.l10n;
    if (!await confirmSignOut(context)) return;
    if (await viewModel.signOut() case Err(:final failure)) {
      messenger.showSnackBar(SnackBar(content: Text(failure.message(l10n))));
    }
  }

  static Future<void> deleteAccount(BuildContext context) async {
    final viewModel = context.read<AccountViewModel>();
    final messenger = ScaffoldMessenger.of(context);
    final l10n = context.l10n;
    final confirmation = await confirmDeleteAccount(
      context,
      needsPassword: viewModel.state is AccountMember,
    );
    if (confirmation == null) return;
    final result = await viewModel.deleteAccount(
      password: confirmation.password,
    );
    if (result case Err(:final failure)) {
      messenger.showSnackBar(SnackBar(content: Text(failure.message(l10n))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final appInfo = getIt<AppInfo>();

    return BlocProvider(
      create: (_) => AccountViewModel(
        getIt<AuthRepository>(),
        getIt<LearnerData>(),
        getIt<LearnerCloud>(),
      ),
      child: Scaffold(
        appBar: AppBar(title: Text(l10n.tabProfile)),
        body: BlocBuilder<AccountViewModel, AccountState>(
          builder: (context, account) => ProfileView(
            appInfo: appInfo,
            account: account,
            actions: (
              onOpenSettings: () => const SettingsRoute().go(context),
              onOpenAbout: () => showLicensePage(
                context: context,
                applicationName: applicationName,
                applicationVersion: appInfo.label,
                applicationLegalese: l10n.aboutLegalese,
              ),
              onCreateAccount: () => unawaited(
                const CreateAccountRoute(entry: AuthEntry.profile)
                    .push<void>(context),
              ),
              onSignIn: () => unawaited(
                const SignInRoute(entry: AuthEntry.profile).push<void>(context),
              ),
              onVerifyEmail: () => unawaited(
                const VerifyEmailRoute(entry: AuthEntry.profile)
                    .push<void>(context),
              ),
              onSignOut: () => unawaited(signOut(context)),
              onDeleteAccount: () => unawaited(deleteAccount(context)),
            ),
          ),
        ),
      ),
    );
  }
}
