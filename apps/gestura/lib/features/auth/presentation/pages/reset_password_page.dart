import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gestura/core/telemetry/telemetry.dart';
import 'package:gestura/di/injection.dart';
import 'package:gestura/features/auth/domain/auth_repository.dart';
import 'package:gestura/features/auth/presentation/view_models/auth_form_state.dart';
import 'package:gestura/features/auth/presentation/view_models/auth_form_view_model.dart';
import 'package:gestura/features/auth/presentation/widgets/auth_form_layout.dart';
import 'package:gestura/features/auth/presentation/widgets/reset_password_form.dart';
import 'package:gestura/l10n/l10n.dart';

class ResetPasswordPage extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return BlocProvider(
      create: (_) =>
          AuthFormViewModel(getIt<AuthRepository>(), getIt<Telemetry>()),
      child: BlocBuilder<AuthFormViewModel, AuthFormState>(
        builder: (context, state) => Scaffold(
          appBar: AppBar(),
          body: AuthFormLayout(
            title: l10n.resetPasswordTitle,
            subtitle: l10n.resetPasswordSubtitle,
            children: [
              ResetPasswordForm(
                state: state,
                onSubmit: (email) => unawaited(
                  context.read<AuthFormViewModel>().sendPasswordReset(
                    email: email,
                    languageCode: Localizations.localeOf(context).languageCode,
                  ),
                ),
                onBackToSignIn: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
