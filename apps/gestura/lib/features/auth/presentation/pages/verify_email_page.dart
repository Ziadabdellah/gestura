import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gestura/app/router/app_routes.dart';
import 'package:gestura/di/injection.dart';
import 'package:gestura/features/auth/domain/auth_entry.dart';
import 'package:gestura/features/auth/domain/auth_repository.dart';
import 'package:gestura/features/auth/presentation/view_models/verify_email_state.dart';
import 'package:gestura/features/auth/presentation/view_models/verify_email_view_model.dart';
import 'package:gestura/features/auth/presentation/widgets/verify_email_view.dart';
import 'package:go_router/go_router.dart';

class VerifyEmailPage extends StatelessWidget {
  const new({required this.entry, super.key});

  final AuthEntry entry;

  void _finish(BuildContext context) {
    switch (entry) {
      case AuthEntry.welcome:
        const TodayRoute().go(context);
      case AuthEntry.profile:
        context.pop();
    }
  }

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => VerifyEmailViewModel(getIt<AuthRepository>()),
    child: BlocConsumer<VerifyEmailViewModel, VerifyEmailState>(
      listenWhen: (previous, current) => current is VerifyEmailConfirmed,
      listener: (context, _) => _finish(context),
      builder: (context, state) {
        final viewModel = context.read<VerifyEmailViewModel>();
        return Scaffold(
          appBar: AppBar(automaticallyImplyLeading: false),
          body: VerifyEmailView(
            state: state,
            onCheck: () => unawaited(viewModel.check()),
            onResend: () => unawaited(
              viewModel.resend(
                languageCode: Localizations.localeOf(context).languageCode,
              ),
            ),
            onDone: () => _finish(context),
          ),
        );
      },
    ),
  );
}
