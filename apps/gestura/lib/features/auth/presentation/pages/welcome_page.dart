import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gestura/app/router/app_routes.dart';
import 'package:gestura/core/telemetry/telemetry.dart';
import 'package:gestura/di/injection.dart';
import 'package:gestura/features/auth/domain/auth_repository.dart';
import 'package:gestura/features/auth/presentation/view_models/auth_form_state.dart';
import 'package:gestura/features/auth/presentation/view_models/auth_form_view_model.dart';
import 'package:gestura/features/auth/presentation/widgets/welcome_view.dart';

class WelcomePage extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) =>
        AuthFormViewModel(getIt<AuthRepository>(), getIt<Telemetry>()),
    child: Scaffold(
      body: BlocBuilder<AuthFormViewModel, AuthFormState>(
        builder: (context, state) => WelcomeView(
          state: state,
          onContinueAsGuest: () =>
              unawaited(context.read<AuthFormViewModel>().continueAsGuest()),
          onContinueWithGoogle: () =>
              unawaited(context.read<AuthFormViewModel>().continueWithGoogle()),
          onCreateAccount: () =>
              unawaited(const CreateAccountRoute().push<void>(context)),
          onSignIn: () => unawaited(const SignInRoute().push<void>(context)),
        ),
      ),
    ),
  );
}
