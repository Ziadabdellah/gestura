import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gestura/app/router/app_routes.dart';
import 'package:gestura/core/telemetry/telemetry.dart';
import 'package:gestura/di/injection.dart';
import 'package:gestura/features/admin/domain/admin_access.dart';
import 'package:gestura/features/auth/domain/auth_entry.dart';
import 'package:gestura/features/auth/domain/auth_repository.dart';
import 'package:gestura/features/auth/presentation/view_models/auth_form_state.dart';
import 'package:gestura/features/auth/presentation/view_models/auth_form_view_model.dart';
import 'package:gestura/features/auth/presentation/widgets/auth_form_layout.dart';
import 'package:gestura/features/auth/presentation/widgets/credentials_form.dart';
import 'package:gestura/l10n/l10n.dart';
import 'package:gestura_ui/gestura_ui.dart';
import 'package:go_router/go_router.dart';

class SignInPage extends StatelessWidget {
  const new({required this.entry, super.key});

  final AuthEntry entry;

  Future<void> _finish(BuildContext context) async {
    final user = getIt<AuthRepository>().currentUser;
    final admin = await getIt<AdminAccess>().isAdmin(user);
    if (!context.mounted) return;
    if (admin) {
      const AdminRoute().go(context);
      return;
    }
    switch (entry) {
      case AuthEntry.welcome:
        const TodayRoute().go(context);
      case AuthEntry.profile:
        context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return BlocProvider(
      create: (_) =>
          AuthFormViewModel(getIt<AuthRepository>(), getIt<Telemetry>()),
      child: BlocConsumer<AuthFormViewModel, AuthFormState>(
        listenWhen: (previous, current) => current is AuthFormDone,
        listener: (context, _) => unawaited(_finish(context)),
        builder: (context, state) => Scaffold(
          appBar: AppBar(),
          body: AuthFormLayout(
            title: l10n.signInTitle,
            children: [
              CredentialsForm(
                state: state,
                submitLabel: l10n.signInAction,
                onSubmit: (email, password) => unawaited(
                  context.read<AuthFormViewModel>().signIn(
                    email: email,
                    password: password,
                  ),
                ),
                belowPassword: Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: TextButton(
                    onPressed: () => unawaited(
                      const ResetPasswordRoute().push<void>(context),
                    ),
                    child: Text(l10n.forgotPassword),
                  ),
                ),
                footer: [
                  SizedBox(height: context.gSizes.lg),
                  GButton.text(
                    label: l10n.noAccountYet,
                    expand: true,
                    onPressed: () =>
                        CreateAccountRoute(entry: entry)
                            .pushReplacement(context),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
