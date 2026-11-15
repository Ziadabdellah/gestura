import 'package:flutter/material.dart';
import 'package:gestura/features/auth/presentation/view_models/account_state.dart';
import 'package:gestura/l10n/l10n.dart';
import 'package:gestura_ui/gestura_ui.dart';

class AccountCard extends StatelessWidget {
  const new({
    required this.state,
    required this.onCreateAccount,
    required this.onSignIn,
    required this.onVerifyEmail,
    super.key,
  });

  static const double iconSize = 28;

  final AccountState state;
  final VoidCallback onCreateAccount;
  final VoidCallback onSignIn;
  final VoidCallback onVerifyEmail;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = context.gColors;
    final sizes = context.gSizes;

    return switch (state) {
      AccountSignedOut() || AccountDeleting() => const SizedBox.shrink(),
      AccountGuest() => GCard(
        tone: GCardTone.low,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                ExcludeSemantics(
                  child: Icon(
                    Icons.person_outline_rounded,
                    size: sizes.icon(iconSize),
                    color: theme.colorScheme.primary,
                  ),
                ),
                SizedBox(width: sizes.sm),
                Expanded(
                  child: Semantics(
                    header: true,
                    child: Text(
                      l10n.guestTitle,
                      style: theme.textTheme.titleMedium,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: sizes.xs),
            Text(l10n.guestMessage, style: theme.textTheme.bodyMedium),
            SizedBox(height: sizes.md),
            GButton(
              label: l10n.createAccount,
              expand: true,
              onPressed: onCreateAccount,
            ),
            SizedBox(height: sizes.xxs),
            GButton.text(
              label: l10n.haveAccount,
              expand: true,
              onPressed: onSignIn,
            ),
          ],
        ),
      ),
      AccountMember(:final email, :final emailVerified) => GCard(
        tone: GCardTone.low,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ExcludeSemantics(
                  child: CircleAvatar(
                    backgroundColor: theme.colorScheme.primaryContainer,
                    foregroundColor: theme.colorScheme.onPrimaryContainer,
                    child: Text(
                      String.fromCharCodes(email.runes.take(1)).toUpperCase(),
                    ),
                  ),
                ),
                SizedBox(width: sizes.sm),
                Expanded(
                  child: Text(email, style: theme.textTheme.titleMedium),
                ),
              ],
            ),
            SizedBox(height: sizes.sm),
            if (emailVerified)
              Row(
                children: [
                  ExcludeSemantics(
                    child: Icon(Icons.verified_rounded, color: colors.success),
                  ),
                  SizedBox(width: sizes.xs),
                  Expanded(child: Text(l10n.emailConfirmed)),
                ],
              )
            else ...[
              Row(
                children: [
                  ExcludeSemantics(
                    child: Icon(
                      Icons.mark_email_unread_outlined,
                      color: colors.warning,
                    ),
                  ),
                  SizedBox(width: sizes.xs),
                  Expanded(child: Text(l10n.emailNotVerified)),
                ],
              ),
              SizedBox(height: sizes.sm),
              GButton.secondary(
                label: l10n.verifyEmailAction,
                onPressed: onVerifyEmail,
              ),
            ],
          ],
        ),
      ),
    };
  }
}
