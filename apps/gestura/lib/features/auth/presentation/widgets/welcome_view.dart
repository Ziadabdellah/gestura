import 'package:flutter/material.dart';
import 'package:gestura/core/widgets/readable_inset.dart';
import 'package:gestura/features/auth/presentation/view_models/auth_form_state.dart';
import 'package:gestura/features/auth/presentation/widgets/auth_message.dart';
import 'package:gestura/l10n/l10n.dart';
import 'package:gestura_ui/gestura_ui.dart';

class WelcomeView extends StatelessWidget {
  const new({
    required this.state,
    required this.onContinueAsGuest,
    required this.onCreateAccount,
    required this.onSignIn,
    super.key,
  });

  static const double badgeSize = 96;
  static const double badgeIconSize = 48;

  final AuthFormState state;
  final VoidCallback onContinueAsGuest;
  final VoidCallback onCreateAccount;
  final VoidCallback onSignIn;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = context.gColors;
    final sizes = context.gSizes;
    final busy = state is AuthFormBusy;
    final badge = sizes.scaled(badgeSize);

    return SafeArea(
      child: ReadableInset(
        minimum: context.windowSizeClass.screenPadding,
        builder: (context, inset) => CustomScrollView(
          slivers: [
            SliverPadding(
              padding: EdgeInsetsDirectional.fromSTEB(
                inset,
                sizes.xl,
                inset,
                sizes.md,
              ),
              sliver: SliverFillRemaining(
                hasScrollBody: false,
                child: Column(
                  children: [
                    const Spacer(),
                    ExcludeSemantics(
                      child: Container(
                        width: badge,
                        height: badge,
                        decoration: BoxDecoration(
                          gradient: colors.heroGradient,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.sign_language_rounded,
                          size: sizes.icon(badgeIconSize),
                          color: colors.onHero,
                        ),
                      ),
                    ),
                    SizedBox(height: sizes.lg),
                    Semantics(
                      header: true,
                      child: Text(
                        l10n.welcomeTitle,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.headlineMedium,
                      ),
                    ),
                    SizedBox(height: sizes.sm),
                    Text(
                      l10n.welcomeSubtitle,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const Spacer(),
                    SizedBox(height: sizes.lg),
                    if (state case AuthFormFailed(:final failure)) ...[
                      AuthMessage.failure(failure, l10n: l10n),
                      SizedBox(height: sizes.md),
                    ],
                    GButton(
                      label: l10n.continueAsGuest,
                      expand: true,
                      isLoading: busy,
                      onPressed: onContinueAsGuest,
                    ),
                    SizedBox(height: sizes.sm),
                    GButton.secondary(
                      label: l10n.createAccount,
                      expand: true,
                      onPressed: busy ? null : onCreateAccount,
                    ),
                    SizedBox(height: sizes.xs),
                    GButton.text(
                      label: l10n.haveAccount,
                      expand: true,
                      onPressed: busy ? null : onSignIn,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
