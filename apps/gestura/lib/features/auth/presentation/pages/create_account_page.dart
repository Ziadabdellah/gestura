import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gestura/app/router/app_routes.dart';
import 'package:gestura/core/telemetry/telemetry.dart';
import 'package:gestura/di/injection.dart';
import 'package:gestura/features/auth/domain/app_user.dart';
import 'package:gestura/features/auth/domain/auth_entry.dart';
import 'package:gestura/features/auth/domain/auth_repository.dart';
import 'package:gestura/features/auth/presentation/view_models/auth_form_state.dart';
import 'package:gestura/features/auth/presentation/view_models/auth_form_view_model.dart';
import 'package:gestura/features/auth/presentation/widgets/auth_form_layout.dart';
import 'package:gestura/features/auth/presentation/widgets/credentials_form.dart';
import 'package:gestura/l10n/l10n.dart';

class CreateAccountPage extends StatelessWidget {
  const new({required this.entry, super.key});

  final AuthEntry entry;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final auth = getIt<AuthRepository>();
    final isGuest = auth.currentUser is GuestUser;
    return BlocProvider(
      create: (_) => AuthFormViewModel(auth, getIt<Telemetry>()),
      child: BlocConsumer<AuthFormViewModel, AuthFormState>(
        listenWhen: (previous, current) => current is AuthFormDone,
        listener: (context, _) =>
            VerifyEmailRoute(entry: entry).pushReplacement(context),
        builder: (context, state) => Scaffold(
          appBar: AppBar(),
          body: AuthFormLayout(
            title: l10n.createAccountTitle,
            subtitle: isGuest
                ? l10n.linkAccountSubtitle
                : l10n.createAccountSubtitle,
            children: [
              CredentialsForm(
                state: state,
                isNewPassword: true,
                submitLabel: l10n.createAccount,
                onSubmit: (email, password) => unawaited(
                  context.read<AuthFormViewModel>().createAccount(
                    email: email,
                    password: password,
                    languageCode: Localizations.localeOf(context).languageCode,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
